---
title: Quick Installation
description: Install Longhorn on Kubernetes
weight: 1
---

> **Note**: This quick installation guide uses some configurations which are not for production usage.
> Please see [Best Practices](../../best-practices/) for how to configure Longhorn for production usage.

Longhorn can be installed on a Kubernetes cluster in several ways:

- [Rancher catalog app](./install-with-rancher)
- [kubectl](./install-with-kubectl/)
- [Helm](./install-with-helm/)
- [Fleet](./install-with-fleet/)
- [Flux](./install-with-flux/)
- [ArgoCD](./install-with-argocd/)

To install Longhorn in an air gapped environment, refer to [this section.](../install/airgap)

For information on customizing Longhorn's default settings, refer to [this section.](../../advanced-resources/deploy/customizing-default-settings)

For information on deploying Longhorn on specific nodes and rejecting general workloads for those nodes, refer to the section on [taints and tolerations.](../../advanced-resources/deploy/taint-toleration)

# Installation Requirements

Each node in the Kubernetes cluster where Longhorn is installed must fulfill the following requirements:

-  A container runtime compatible with Kubernetes (Docker v1.13+, containerd v1.3.7+, etc.)
-  Kubernetes >= v1.21
-  `open-iscsi` is installed, and the `iscsid` daemon is running on all the nodes. This is necessary, since Longhorn relies on `iscsiadm` on the host to provide persistent volumes to Kubernetes. For help installing `open-iscsi`, refer to [this section.](#installing-open-iscsi)
-  RWX support requires that each node has a NFSv4 client installed.
    - For installing a NFSv4 client, refer to [this section.](#installing-nfsv4-client)
- The host filesystem supports the `file extents` feature to store the data. Currently we support:
    - ext4
    - XFS
- `bash`, `curl`, `findmnt`, `grep`, `awk`, `blkid`, `lsblk` must be installed.
- [Mount propagation](https://kubernetes-csi.github.io/docs/deploying.html#enabling-mount-propagation) must be enabled.

The Longhorn workloads must be able to run as root in order for Longhorn to be deployed and operated properly.

[This script](#using-the-environment-check-script) can be used to check the Longhorn environment for potential issues.

For the minimum recommended hardware, refer to the [best practices guide.](../../best-practices/#minimum-recommended-hardware)

### OS/Distro Specific Configuration

You must perform additional setups before using Longhorn with certain operating systems and distributions.

- Google Kubernetes Engine (GKE): See [Longhorn CSI on GKE](../../advanced-resources/os-distro-specific/csi-on-gke).
- K3s clusters: See [Longhorn CSI on K3s](../../advanced-resources/os-distro-specific/csi-on-k3s).
- RKE clusters with CoreOS: See [Longhorn CSI on RKE and CoreOS](../../advanced-resources/os-distro-specific/csi-on-rke-and-coreos).
- OCP/OKD clusters: See [OKD Support](../../advanced-resources/os-distro-specific/okd-support).
- Talos Linux clusters: See [Talos Linux Support](../../advanced-resources/os-distro-specific/talos-linux-support).

### Using the Environment Check Script

We've written a script to help you gather enough information about the factors.

Note `jq` maybe required to be installed locally prior to running env check script.

To run script:

```shell
curl -sSfL https://raw.githubusercontent.com/longhorn/longhorn/v{{< current-version >}}/scripts/environment_check.sh | bash
```

Example result:

```shell
[INFO]  Required dependencies 'kubectl jq mktemp sort printf' are installed.
[INFO]  All nodes have unique hostnames.
[INFO]  Waiting for longhorn-environment-check pods to become ready (0/3)...
[INFO]  All longhorn-environment-check pods are ready (3/3).
[INFO]  MountPropagation is enabled
[INFO]  Checking kernel release...
[INFO]  Checking iscsid...
[INFO]  Checking multipathd...
[INFO]  Checking packages...
[INFO]  Checking nfs client...
[INFO]  Cleaning up longhorn-environment-check pods...
[INFO]  Cleanup completed.
```

### Pod Security Policy

Starting with v1.0.2, Longhorn is shipped with a default Pod Security Policy that will give Longhorn the necessary privileges to be able to run properly.

No special configuration is needed for Longhorn to work properly on clusters with Pod Security Policy enabled.

### Notes on Mount Propagation

If your Kubernetes cluster was provisioned by Rancher v2.0.7+ or later, the MountPropagation feature is enabled by default.

If MountPropagation is disabled, Base Image feature will be disabled.

### Root and Privileged Permission

Longhorn components require root access with privileged permissions to achieve volume operations and management, because Longhorn relies on system resources on the host across different namespaces, for example, Longhorn uses `nsenter` to understand block devices' usage or encrypt/decrypt volumes on the host.

Below are the directories Longhorn components requiring access with root and privileged permissions :

- Longhorn Manager
  - /dev: Block devices created by Longhorn are under the `/dev` path.
  - /proc: Find the recognized host process like container runtime, then use `nsenter` to access the mounts on the host to understand disks usage.
  - /var/lib/longhorn: The default path for storing volume data on a host.
- Longhorn Engine Image
  - /var/lib/longhorn/engine-binaries: The default path for storing the Longhorn engine binaries.
- Longhorn Instance Manager
  - /: Access any data path on this node and access Longhorn engine binaries.
  - /dev: Block devices created by Longhorn are under the `/dev` path.
  - /proc: Find the recognized host process like container runtime, then use `nsenter` to manage iSCSI targets and initiators, also some file system
- Longhorn Share Manager
  - /dev: Block devices created by Longhorn are under the `/dev` path.
  - /lib/modules: Kernel modules required by `cryptsetup` for volume encryption.
  - /proc: Find the recognized host process like container runtime, then use `nsenter` for volume encryption.
  - /sys: Support volume encryption by `cryptsetup`.
- Longhorn CSI Plugin
  - /: For host checks via the NFS customer mounter (deprecated). Note that, this will be removed in the future release.
  - /dev: Block devices created by Longhorn are under the `/dev` path.
  - /lib/modules: Kernel modules required by Longhorn CSI plugin.
  - /sys: Support volume encryption by `cryptsetup`.
  - /var/lib/kubelet/plugins/kubernetes.io/csi: The path where the Longhorn CSI plugin creates the staging path (via `NodeStageVolume`) of a block device. The staging path will be bind-mounted to the target path `/var/lib/kubelet/pods` (via `NodePublishVolume`) for support single volume could be mounted to multiple Pods.
  - /var/lib/kubelet/plugins_registry: The path where the node-driver-registrar registers the CSI plugin with kubelet.
  - /var/lib/kubelet/plugins/driver.longhorn.io: The path where the socket for the communication between kubelet Longhorn CSI driver.
  - /var/lib/kubelet/pods: The path where the Longhorn CSI driver mounts volume from the target path (via `NodePublishVolume`).
- Longhorn CSI Attacher/Provisioner/Resizer/Snapshotter
  - /var/lib/kubelet/plugins/driver.longhorn.io: The path where the socket for the communication between kubelet Longhorn CSI driver.
- Longhorn Backing Image Manager
  - /var/lib/longhorn: The default path for storing data on the host.
- Longhorn Backing Image Data Source
  - /var/lib/longhorn: The default path for storing data on the host.
- Longhorn System Restore Rollout
  - /var/lib/longhorn/engine-binaries: The default path for storing the Longhorn engine binaries.

### Installing open-iscsi

The command used to install `open-iscsi` differs depending on the Linux distribution.

For GKE, we recommend using Ubuntu as the guest OS image since it contains`open-iscsi` already.

You may need to edit the cluster security group to allow SSH access.

- SUSE and openSUSE: Run the following command:
  ```
  zypper install open-iscsi
  ```

- Debian and Ubuntu: Run the following command:
  ```
  apt-get install open-iscsi
  ```

- RHEL, CentOS, and EKS *(EKS Kubernetes Worker AMI with AmazonLinux2 image)*: Run the following commands:
  ```
  yum --setopt=tsflags=noscripts install iscsi-initiator-utils
  echo "InitiatorName=$(/sbin/iscsi-iname)" > /etc/iscsi/initiatorname.iscsi
  systemctl enable iscsid
  systemctl start iscsid
  ```

- Talos Linux: See [Talos Linux Support](../../advanced-resources/os-distro-specific/talos-linux-support).

Please ensure iscsi_tcp module has been loaded before iscsid service starts. Generally, it should be automatically loaded along with the package installation.

```
modprobe iscsi_tcp
```

We also provide an `iscsi` installer to make it easier for users to install `open-iscsi` automatically:
```
kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/v{{< current-version >}}/deploy/prerequisite/longhorn-iscsi-installation.yaml
```
After the deployment, run the following command to check pods' status of the installer:
```
kubectl get pod | grep longhorn-iscsi-installation
longhorn-iscsi-installation-49hd7   1/1     Running   0          21m
longhorn-iscsi-installation-pzb7r   1/1     Running   0          39m
```
And also can check the log with the following command to see the installation result:
```
kubectl logs longhorn-iscsi-installation-pzb7r -c iscsi-installation
...
Installed:
  iscsi-initiator-utils.x86_64 0:6.2.0.874-7.amzn2

Dependency Installed:
  iscsi-initiator-utils-iscsiuio.x86_64 0:6.2.0.874-7.amzn2

Complete!
Created symlink from /etc/systemd/system/multi-user.target.wants/iscsid.service to /usr/lib/systemd/system/iscsid.service.
iscsi install successfully
```

In rare cases, it may be required to modify the installed SELinux policy to get Longhorn working. If you are running
an up-to-date version of a Fedora downstream distribution (e.g. Fedora, RHEL, Rocky, CentOS, etc.) and plan to leave
SELinux enabled, see [the KB](../../../../kb/troubleshooting-volume-attachment-fails-due-to-selinux-denials) for details.

### Installing NFSv4 client

In Longhorn system, backup feature requires NFSv4, v4.1 or v4.2, and ReadWriteMany (RWX) volume feature requires NFSv4.1. Before installing NFSv4 client userspace daemon and utilities, make sure the client kernel support is enabled on each Longhorn node.

- Check `NFSv4.1` support is enabled in kernel
  ```
  cat /boot/config-`uname -r`| grep CONFIG_NFS_V4_1
  ```

- Check `NFSv4.2` support is enabled in kernel
  ```
  cat /boot/config-`uname -r`| grep CONFIG_NFS_V4_2
  ```


The command used to install a NFSv4 client differs depending on the Linux distribution.

- For Debian and Ubuntu, use this command:
  ```
  apt-get install nfs-common
  ```

- For RHEL, CentOS, and EKS with `EKS Kubernetes Worker AMI with AmazonLinux2 image`, use this command:
  ```
  yum install nfs-utils
  ```

- For SUSE/OpenSUSE you can install a NFSv4 client via:
  ```
  zypper install nfs-client
  ```

- For Talos Linux, [the NFS client is part of the `kubelet` image maintained by the Talos team](https://www.talos.dev/v1.6/kubernetes-guides/configuration/storage/#nfs).

We also provide an `nfs` installer to make it easier for users to install `nfs-client` automatically:
```
kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/v{{< current-version >}}/deploy/prerequisite/longhorn-nfs-installation.yaml
```
After the deployment, run the following command to check pods' status of the installer:
```
kubectl get pod | grep longhorn-nfs-installation
NAME                                  READY   STATUS    RESTARTS   AGE
longhorn-nfs-installation-t2v9v   1/1     Running   0          143m
longhorn-nfs-installation-7nphm   1/1     Running   0          143m
```
And also can check the log with the following command to see the installation result:
```
kubectl logs longhorn-nfs-installation-t2v9v -c nfs-installation
...
nfs install successfully
```

### Checking the Kubernetes Version

Use the following command to check your Kubernetes server version

```shell
kubectl version
```

Result:

```shell
Client Version: version.Info{Major:"1", Minor:"26", GitVersion:"v1.26.10", GitCommit:"b8609d4dd75c5d6fba4a5eaa63a5507cb39a6e99", GitTreeState:"clean", BuildDate:"2023-10-18T11:44:31Z", GoVersion:"go1.20.10", Compiler:"gc", Platform:"linux/amd64"}
Server Version: version.Info{Major:"1", Minor:"26", GitVersion:"v1.26.10+k3s2", GitCommit:"cb5cb5557f34e240e38c68a8c4ca2506c68b1d86", GitTreeState:"clean", BuildDate:"2023-11-08T03:21:46Z", GoVersion:"go1.20.10", Compiler:"gc", Platform:"linux/amd64"}
```

The `Server Version` should be >= v1.21.
