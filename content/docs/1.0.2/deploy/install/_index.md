---
title: Installation
description: Install Longhorn on Kubernetes
weight: 1
---

Longhorn can be installed on a Kubernetes cluster in several ways:

- [kubectl](./install-with-kubectl/)
- [Helm](./install-with-helm/)
- [Rancher catalog app](./install-with-rancher)

To install Longhorn in an air gapped environment, refer to [this section.](../../advanced-resources/deploy/airgap)

For information on customizing Longhorn's default settings, refer to [this section.](../../advanced-resources/deploy/customizing-default-settings)

For information on deploying Longhorn on specific nodes and rejecting general workloads for those nodes, refer to the section on [taints and tolerations.](../../advanced-resources/deploy/taint-toleration)

# Installation Requirements

Each node in the Kubernetes cluster where Longhorn is installed must fulfill the following requirements:

-  A container runtime compatible with Kubernetes (Docker v1.13+, containerd v1.3.7+, etc.)
-  Kubernetes v1.14+.
    - By default Longhorn installation requires a three-nodes cluster since the default replica count is 3 and the [node level soft anti-affinity](https://longhorn.io/docs/1.0.0/references/settings/#replica-node-level-soft-anti-affinity) is disabled.
-  `open-iscsi` is installed, and the `iscsid` daemon is running on all the nodes. This is necessary, since Longhorn relies on `iscsiadm` on the host to provide persistent volumes to Kubernetes. For help installing `open-iscsi`, refer to [this section.](#installing-open-iscsi)
- The host filesystem supports the `file extents` feature to store the data. Currently we support:
    - ext4
    - XFS
- `curl`, `findmnt`, `grep`, `awk`, `blkid`, `lsblk` must be installed.
- [Mount propagation](https://kubernetes-csi.github.io/docs/deploying.html#enabling-mount-propagation) must be enabled.

The Longhorn workloads must be able to run as root in order for Longhorn to be deployed and operated properly.

CSI v1.1 is supported.

[This script](#using-the-environment-check-script) can be used to check the Longhorn environment for potential issues.

For the minimum recommended hardware, refer to the [best practices guide.](../../best-practices/#minimum-recommended-hardware)

### OS/Distro Specific Configuration

- **Google Kubernetes Engine (GKE)** requires some additional setup for Longhorn to function properly. If you're a GKE user, refer to [this section](../../advanced-resources/os-distro-specific/csi-on-gke) for details.
- **K3s clusters** require some extra setup. Refer to [this section](../../advanced-resources/os-distro-specific/csi-on-k3s)
- **RKE clusters with CoreOS** need [this configuration.](../../advanced-resources/os-distro-specific/csi-on-rke-and-coreos)

### Using the Environment Check Script

We've written a script to help you gather enough information about the factors.

Note `jq` maybe required to be installed locally prior to running env check script.

To run script:

```shell
curl -sSfL https://raw.githubusercontent.com/longhorn/longhorn/master/scripts/environment_check.sh | bash
```

Example result:

```shell
daemonset.apps/longhorn-environment-check created
waiting for pods to become ready (0/3)
all pods ready (3/3)

  MountPropagation is enabled!

cleaning up...
daemonset.apps "longhorn-environment-check" deleted
clean up complete
```

### Pod Security Policy

Starting with v1.0.2, Longhorn is shipped with a default Pod Security Policy that will give Longhorn the necessary privileges to be able to run properly.

No special configuration is needed for Longhorn to work properly on clusters with Pod Security Policy enabled.

### Notes on Mount Propagation

If your Kubernetes cluster was provisioned by Rancher v2.0.7+ or later, the MountPropagation feature is enabled by default.

If MountPropagation is disabled, Base Image feature will be disabled.

### Installing open-iscsi

The command used to install `open-iscsi` differs depending on the Linux distribution.

For GKE, we recommend using Ubuntu as the guest OS image since it contains`open-iscsi` already.

You may need to edit the cluster security group to allow SSH access.

For Debian and Ubuntu, use this command:

```
apt-get install open-iscsi
```

For RHEL, CentOS, and EKS with `EKS Kubernetes Worker AMI with AmazonLinux2 image`, use this command:

```
yum install iscsi-initiator-utils
```


### Checking the Kubernetes Version

Use the following command to check your Kubernetes server version

```shell
kubectl version
```

Result:

```shell
Client Version: version.Info{Major:"1", Minor:"10", GitVersion:"v1.10.3", GitCommit:"2bba0127d85d5a46ab4b778548be28623b32d0b0", GitTreeState:"clean", BuildDate:"2018-05-21T09:17:39Z", GoVersion:"go1.9.3", Compiler:"gc", Platform:"linux/amd64"}
Server Version: version.Info{Major:"1", Minor:"10", GitVersion:"v1.10.1", GitCommit:"d4ab47518836c750f9949b9e0d387f20fb92260b", GitTreeState:"clean", BuildDate:"2018-04-12T14:14:26Z", GoVersion:"go1.9.3", Compiler:"gc", Platform:"linux/amd64"}
```

The `Server Version` should be `v1.10` or above.


