---
title: "Troubleshooting: Failed RWX mount due to connection timeout"
author: Eric Weber
draft: false
date: 2023-09-05
categories:
  - "nfs"
  - "rwx"
  - "sles"
  - "flannel"
---

## Applicable versions

Confirmed with:

- K3s `v1.24.8+k3s1` and RKE2 `v1.24.8+rke2r1`
- Longhorn `v1.3.3`
- SUSE Linux Enterprise Server 15 SP5

Likely possible with:

- Any Kubernetes distribution running Flannel CNI < `v0.20.2`
- Any Longhorn version
- A potential variety of Linux distributions and versions

## Symptoms

Longhorn RWX volumes fail to mount into workload pods.

Describing the workload pod shows:

```
...
Events:
  Type     Reason                  Age                  From                     Message
  ----     ------                  ----                 ----                     -------
  Normal   Scheduled               10m                  default-scheduler        Successfully assigned default/web-state-rwx-0 to ip-10-0-2-142
  Normal   SuccessfulAttachVolume  10m                  attachdetach-controller  AttachVolume.Attach succeeded for volume "pvc-e2d70b12-12bf-4d7e-9256-27c87fd7c32b"
  Warning  FailedMount             99s (x4 over 8m26s)  kubelet                  Unable to attach or mount volumes: unmounted volumes=[www], unattached volumes=[www kube-api-access-dr674]: timed out waiting for the condition
  Warning  FailedMount             13s (x5 over 8m21s)  kubelet                  MountVolume.MountDevice failed for volume "pvc-e2d70b12-12bf-4d7e-9256-27c87fd7c32b" : rpc error: code = DeadlineExceeded desc = context deadline exceeded
```

The `csi-plugin` pod on the node running the workload pod logs:

```
2023-08-09T14:24:23.168674384Z E0809 14:24:23.168466   17369 mount_linux.go:195] Mount failed: exit status 32
2023-08-09T14:24:23.168713885Z Mounting command: /usr/local/sbin/nsmounter
2023-08-09T14:24:23.168727245Z Mounting arguments: mount -t nfs -o vers=4.1,noresvport,soft,intr,timeo=30,retrans=3 10.43.222.49:/pvc-9fcf03ad-07d6-45d8-b00c-d8ef04928bf8 /var/lib/kubelet/plugins/kubernetes.io/csi/driver.longhorn.io/11ec8ece01effb5207e0df7f96ec6950c28fafdda89dc1ef80557d721ed2b19b/globalmount
2023-08-09T14:24:23.168731951Z Output: mount.nfs: Connection timed out
```

It takes approximately one minute to reach the volume's NFS endpoint from a node (NOT a pod) in the cluster.

```
# Get the IP address of the share manager for the volume.
-> kubectl get -oyaml -n longhorn-system volume | grep shareEndpoint
shareEndpoint: nfs://10.43.39.214/pvc-ea0519fa-d505-48f4-a54c-d61d87926e9e

# SSH to a node in the cluster.
-> SSH <user>@<node_ip>

# Use `time` and `netcat` to time access to the NFS port.
-> time nsenter -t 1 -m -n -u nc -z 10.43.78.204 2049
real    1m4.940s
user    0m0.002s
sys     0m0.000s
```

## Root cause

There is a double-NAT bug in Flannel CNI < `v0.20.2` that can slow down connections and even cause packet loss,
specifically for traffic between a node (NOT a pod) and a pod. It appears to exacerbate a bug that exists in many
kernels related to TX checksum offloading for VXLAN interfaces. See [related information](#related-information) for
further details. This bug is not specific to Longhorn. In an affected cluster, any attempt to communicate with a pod
from a node results in a similar delay. The delay exceeds Longhorn NFS mounting timeouts, causing mount failure.

NOTE: According to the issues in [related information](#related-information), kernel fixes should have made this issue
go away, regardless of Flannel version. However, we found that upgrading from SUSE Enterprise Linux 15 SP4 to SUSE
Enterprise Linux 15 SP5 caused a regression. It is unclear exactly what changed between service pack versions, but it is
better to ensure the fix within the Kubernetes environment in addition to the fix in the kernel.

## Workaround

It is generally possible to mitigate the issue by disabling TX checksum offloading for Flannel interfaces on all nodes
in the cluster. This can be done temporarily with a command like `sudo ethtool -K flannel.1 tx-checksum-ip-generic off`.
Consult your distribution documentation for a more permanent solution.

## Long term fix

The Flannel bug is fixed in `v0.20.2`. All K3s and RKE2 minor versions >= `v1.24` have a patch version with the fix. For
example, the solution in the [specific environment that led to this
KB](https://github.com/longhorn/longhorn/issues/6494#issuecomment-1687171177) was to upgrade from `v1.24.8+k3s1` to
`v1.24.16+k3s1`. If you are using a different Kubernetes distribution with Flannel, upgrade to a version that includes
Flannel >= `v0.20.2`. If you are using a different VXLAN-based CNI, consult the documentation for that CNI.

## Related information

- https://github.com/longhorn/longhorn/issues/6494:
  The original Longhorn issue documenting a failure in a test environment.
- https://github.com/flannel-io/flannel/issues/1279:
  The Flannel issue documenting the TX checksum offloading workaround.
- https://github.com/flannel-io/flannel/issues/1679:
  A Flannel issue describing the double-NAT bug.
- https://github.com/rancher/rke2/issues/1541:
  A related RKE2 issue.
- https://github.com/kubernetes/kubernetes/issues/88986:
  A related Kubernetes issue.
