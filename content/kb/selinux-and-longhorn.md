---
title: "SELinux and Longhorn"
author: Eric Weber
draft: false
date: 2023-11-21
categories:
- "instruction"
- "selinux"
- "rke2"
- "k3s"
---

## Applicable versions

All Longhorn versions.

## Purpose

The purpose of this article is to help Longhorn users understand how Longhorn typically acts in SELinux-enabled systems
and provide them with basic commands to run to verify normal operation. It is a work in progress that may be expanded as
Longhorn maintainers discover additional SELinux behaviors that are of interest. It is not intended to be a guide to
SELinux or using SELinux with Kubernetes.

## SELinux basics

Security-Enhanced Linux (SELinux) is a security architecture for Linux systems that allows administrators to have more
control over who can access the system. It goes beyond discretionary access control and allows for much more granular
decisions to be made about which processes can access files or communicate with other processes. Many distributions
support SELinux, and some even enable it by default. Consult the documentation for your distribution to determine
whether SELinux is supported and how to enable it.

When SELinux is enabled, it uses policies to determine whether or not accesses are allowed. Most distributions ship
default policies, but administrators are free to write their own or modify the pre-existing ones. In addition, some
software ships with SELinux policies that grant permissions necessary for operation.

## SELinux and Kubernetes

Many popular container runtimes and Kubernetes distributions support SELinux. The upstream
[container-selinux](https://github.com/containers/container-selinux) project defines the SELinux
[domains/types](https://danwalsh.livejournal.com/81756.html) for container processes and the files they interact with.
Then, downstream maintainers provide policies based on these domains/types for their specific projects.

- [K3s SELinux documentation](https://docs.k3s.io/advanced?_highlight=selinux#selinux-support)
- [RKE2 SELinux documentation](https://docs.rke2.io/security/selinux)

## SELinux requirements for Longhorn

Assuming the Kubernetes SELinux policy is working correctly, nothing additional generally needs to be done for Longhorn
to function properly. However, on occasion, the policies shipped by OS or Kubernetes distributors have changed in a way
that caused Longhorn to fail. This section provides some basic expectations Longhorn has while running with SELinux
enabled. It is generally outside of Longhorn's ability to correct or appropriately respond to the failure to meet these
expectations.

### Privileged containers run with the spc_t context

[Longhorn 5348](https://github.com/longhorn/longhorn/issues/5348) was caused by a breaking of this requirement.

Certain Longhorn containers must run with the `privileged` security context. Privileged container processes are expected
to run with the `spc_t` SELinux context. These containers include:

- The `longhorn-manager` container in `longhorn-manager` pods.
- The `longhorn-csi-plugin` and `node-driver-registrar` containers in `longhorn-csi-plugin` pods.
- The `instance-manager` container in `instance-manager` pods.
- The `engine-image` container in `engine-image` pods.

Verify these contexts using the `-Z` flag with the `ps` command on any node running Longhorn.

```
-> ps -eZf | grep spc_t | grep longhorn
system_u:system_r:spc_t:s0      root      3146  2558  0 20:10 ?        00:00:00 /bin/bash -c diff /usr/local/bin/longhorn /data/longhorn > /dev/null 2>&1; if [ $? -ne 0 ]; then cp -p /usr/local/bin/longhorn /data/ && echo installed; fi && trap 'rm /data/longhorn* && echo cleaned up' EXIT && sleep infinity
system_u:system_r:spc_t:s0      root      3681  3409  0 20:10 ?        00:00:00 /csi-node-driver-registrar --v=2 --csi-address=/csi/csi.sock --kubelet-registration-path=/var/lib/kubelet/plugins/driver.longhorn.io/csi.sock
system_u:system_r:spc_t:s0      root      7509  3119  1 20:11 ?        00:00:00 longhorn-manager -d daemon --engine-image longhornio/longhorn-engine:v1.4.0 --instance-manager-image longhornio/longhorn-instance-manager:v1.4.0 --share-manager-image longhornio/longhorn-share-manager:v1.4.0 --backing-image-manager-image longhornio/backing-image-manager:v1.4.0 --support-bundle-manager-image longhornio/support-bundle-kit:v0.0.17 --manager-image longhornio/longhorn-manager:v1.4.0 --service-account longhorn-service-account
system_u:system_r:spc_t:s0      root      7793  7668  0 20:11 ?        00:00:00 /tini -- longhorn-instance-manager --debug daemon --listen 0.0.0.0:8500
system_u:system_r:spc_t:s0      root      7813  7793  0 20:11 ?        00:00:00 longhorn-instance-manager --debug daemon --listen 0.0.0.0:8500
system_u:system_r:spc_t:s0      root      7823  7799  0 20:11 ?        00:00:00 longhorn-instance-manager --debug daemon --listen 0.0.0.0:8500
system_u:system_r:spc_t:s0      root     11380  3409  0 20:11 ?        00:00:00 longhorn-manager -d csi --nodeid=ip-192-168-217-136 --endpoint=unix:///csi/csi.sock --drivername=driver.longhorn.io --manager-url=http://longhorn-backend:9500/v1
```

### Non-privileged containers run with the container_t context

All other Longhorn containers must run with the `container_t` SELinux context.

Verify these contexts using the `-Z` flag with the `ps` command on any node running Longhorn.

```
-> ps -eZf | grep container_t | grep longhorn
system_u:system_r:container_t:s0:c56,c987 root 2045 1738  0 20:10 ?    00:00:00 /csi-resizer --v=2 --csi-address=/csi/csi.sock --timeout=1m50s --leader-election --leader-election-namespace=longhorn-system --leader-election-namespace=longhorn-system --handle-volume-inuse-error=false
system_u:system_r:container_t:s0:c519,c912 root 2969 2404  0 20:10 ?   00:00:00 /csi-resizer --v=2 --csi-address=/csi/csi.sock --timeout=1m50s --leader-election --leader-election-namespace=longhorn-system --leader-election-namespace=longhorn-system --handle-volume-inuse-error=false
system_u:system_r:container_t:s0:c906,c1023 root 3282 2844  0 20:10 ?  00:00:00 /csi-attacher --v=2 --csi-address=/csi/csi.sock --timeout=1m50s --leader-election --leader-election-namespace=longhorn-system
system_u:system_r:container_t:s0:c406,c440 2000 3342 2686  0 20:10 ?   00:00:00 longhorn-manager recovery-backend --service-account longhorn-service-account
system_u:system_r:container_t:s0:c451,c595 root 3543 2958  0 20:10 ?   00:00:00 /csi-attacher --v=2 --csi-address=/csi/csi.sock --timeout=1m50s --leader-election --leader-election-namespace=longhorn-system
system_u:system_r:container_t:s0:c500,c551 2000 4021 3653  0 20:10 ?   00:00:00 longhorn-manager recovery-backend --service-account longhorn-service-account
system_u:system_r:container_t:s0:c397,c986 root 4178 3792  0 20:10 ?   00:00:00 /csi-resizer --v=2 --csi-address=/csi/csi.sock --timeout=1m50s --leader-election --leader-election-namespace=longhorn-system --leader-election-namespace=longhorn-system --handle-volume-inuse-error=false
system_u:system_r:container_t:s0:c658,c965 root 4285 3934  0 20:10 ?   00:00:00 /csi-snapshotter --v=2 --csi-address=/csi/csi.sock --timeout=1m50s --leader-election --leader-election-namespace=longhorn-system
system_u:system_r:container_t:s0:c42,c868 2000 4393 4087  0 20:10 ?    00:00:00 longhorn-manager conversion-webhook --service-account longhorn-service-account
system_u:system_r:container_t:s0:c561,c777 root 4831 4645  0 20:10 ?   00:00:00 /csi-snapshotter --v=2 --csi-address=/csi/csi.sock --timeout=1m50s --leader-election --leader-election-namespace=longhorn-system
system_u:system_r:container_t:s0:c635,c1000 root 5357 5018  0 20:10 ?  00:00:00 /csi-attacher --v=2 --csi-address=/csi/csi.sock --timeout=1m50s --leader-election --leader-election-namespace=longhorn-system
system_u:system_r:container_t:s0:c296,c393 2000 5438 5032  0 20:10 ?   00:00:00 longhorn-manager conversion-webhook --service-account longhorn-service-account
system_u:system_r:container_t:s0:c523,c577 root 5723 5519  0 20:10 ?   00:00:00 /csi-snapshotter --v=2 --csi-address=/csi/csi.sock --timeout=1m50s --leader-election --leader-election-namespace=longhorn-system
system_u:system_r:container_t:s0:c325,c922 2000 7159 1789  0 20:11 ?   00:00:00 longhorn-manager admission-webhook --service-account longhorn-service-account
system_u:system_r:container_t:s0:c609,c719 root 7246 1615  0 20:11 ?   00:00:00 /csi-provisioner --v=2 --csi-address=/csi/csi.sock --timeout=1m50s --leader-election --leader-election-namespace=longhorn-system --default-fstype=ext4
system_u:system_r:container_t:s0:c270,c629 2000 7304 5553  0 20:11 ?   00:00:00 longhorn-manager admission-webhook --service-account longhorn-service-account
system_u:system_r:container_t:s0:c275,c453 root 7349 1616  0 20:11 ?   00:00:00 /csi-provisioner --v=2 --csi-address=/csi/csi.sock --timeout=1m50s --leader-election --leader-election-namespace=longhorn-system --default-fstype=ext4
system_u:system_r:container_t:s0:c47,c436 root 7951 4505  0 20:11 ?    00:00:00 longhorn-manager -d deploy-driver --manager-image longhornio/longhorn-manager:v1.4.0 --manager-url http://longhorn-backend:9500/v1
system_u:system_r:container_t:s0:c499,c539 root 8936 4306  0 20:11 ?   00:00:00 /csi-provisioner --v=2 --csi-address=/csi/csi.sock --timeout=1m50s --leader-election --leader-election-namespace=longhorn-system --default-fstype=ext4
```

### Processes running as container_t must have permission to connect to processes running as spc_t

The `longhorn-manager` process in `longhorn-csi-plugin` containers in `longhorn-csi-plugin` pods runs with the `spc_t`
context. Other components, including `csi-attacher`, `csi-provisioner`, `csi-resizer`, `csi-snapshotter`, and liveness
probes, which run with the `container_t` context, must be able to connect to a socket exposed by this process.

Verify this permission using the `sesearch` command on any node Longhorn is running on. (`container_t` is included in
the `container_domain` alias.)

```
-> sesearch -A -s container_t -t spc_t -p connectto
allow container_domain spc_t:unix_stream_socket connectto;
allow domain spc_t:unix_stream_socket connectto;
allow svirt_sandbox_domain spc_t:unix_stream_socket connectto;

-> seinfo -x -a container_domain
Type Attributes: 1
   attribute container_domain;
        container_device_plugin_init_t
        container_device_plugin_t
        container_device_t
        container_engine_t
        container_init_t
        container_kvm_t
        container_logreader_t
        container_logwriter_t
        container_t
        container_userns_t
```

## Diagnosing a problem

It is sometimes not immediately obvious that SELinux is the reason for a Longhorn failure. SELinux tends to silently
cause denials that can look like connection failures or access permission issues.

- In [Longhorn 5348](https://github.com/longhorn/longhorn/issues/5348), users saw socket connection failures like
  `longhorn-liveness-probe W0203 15:06:13.264351    1893 connection.go:173] Still connecting to unix:///csi/csi.sock`.
- In [Longhorn 5627](https://github.com/longhorn/longhorn/issues/5627#issuecomment-1572852384), users saw inexplicable
  iSCSI issues.

Luckily, it is fairily easy to confirm an SELinux issue if one is expected.

First, if `getenforce` returns `Permissive` (or `getenforce` is not installed) on a node, SELinux is probably not the
cause of any problems.

Otherwise, use `sesearch` to look for any recent SELinux denials.

```
...
-> ausearch -m AVC -ts recent
time->Tue Nov 21 19:51:01 2023
type=AVC msg=audit(1700596261.324:4756): avc:  denied  { connectto } for  pid=7892 comm="csi-attacher" path="/csi/csi.sock" scontext=system_u:system_r:container_t:s0:c224,c441 tcontext=system_u:system_r:container_runtime_t:s0 tclass=unix_stream_socket permissive=0
----
time->Tue Nov 21 19:51:01 2023
type=AVC msg=audit(1700596261.467:4757): avc:  denied  { connectto } for  pid=8145 comm="csi-provisioner" path="/csi/csi.sock" scontext=system_u:system_r:container_t:s0:c566,c670 tcontext=system_u:system_r:container_runtime_t:s0 tclass=unix_stream_socket permissive=0
----
time->Tue Nov 21 19:51:01 2023
type=AVC msg=audit(1700596261.554:4758): avc:  denied  { connectto } for  pid=8226 comm="csi-resizer" path="/csi/csi.sock" scontext=system_u:system_r:container_t:s0:c272,c458 tcontext=system_u:system_r:container_runtime_t:s0 tclass=unix_stream_socket permissive=0
----
time->Tue Nov 21 19:51:01 2023
type=AVC msg=audit(1700596261.560:4759): avc:  denied  { connectto } for  pid=8362 comm="csi-snapshotter" path="/csi/csi.sock" scontext=system_u:system_r:container_t:s0:c4,c467 tcontext=system_u:system_r:container_runtime_t:s0 tclass=unix_stream_socket permissive=0
----
...
```

## Temporary workarounds

The correct solution to a Longhorn SELinux problem must typically originate upstream, either in the policies written in
the `container-selinux` project or the policies written by Kubernetes distribution maintainers. While waiting for this
solution, SELinux issues can be circumvented using one of the following strategies (in order of preference).

### Roll back the policy update that broke Longhorn functionality

It is often possible to downgrade the package that included breaking SELinux policy changes while looking for a more
permanent solution.

### Generate an addendum to SELinux policy with audit2allow

The
[audit2allow](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/6/html/security-enhanced_linux/sect-security-enhanced_linux-fixing_problems-allowing_access_audit2allow)
utility can generate a small policy that specifically allows the Longhorn action seen as denied in the audit log (with
`ausearch`). It can be used to grant a particular permission Longhorn needs until the upstream policy is fixed.

### Set SELinux to permissive

Running with SELinux enabled is included in many best practice guides and is often required by security policy. However,
putting SELinux in `permissive` mode will certainly temporarily resolve issues as a last resort.

## Additional information

- [openSUSE SELinux guide](https://en.opensuse.org/SDB:SELinux)
- [Red Hat SELinux blog post](https://www.redhat.com/en/topics/linux/what-is-selinux)
- [container-selinux project](https://github.com/containers/container-selinux)
- [K3s SElinux documentation](https://docs.k3s.io/advanced?_highlight=selinux#selinux-support)
- [RKE2 SELinux documentation](https://docs.rke2.io/security/selinux)
- [Specific SELinux troubleshooting KB](../troubleshooting-volume-attachment-fails-due-to-selinux-denials)
- [Specific SELinux GitHub issue](https://github.com/longhorn/longhorn/issues/5348)
