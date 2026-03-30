---
title: Quick Installation
description: Install Longhorn on Kubernetes
weight: 1
---

- [Installation Requirements](#installation-requirements)
  - [OS/Distro Specific Configuration](#osdistro-specific-configuration)
  - [Checking the Kubernetes Version](#checking-the-kubernetes-version)
  - [Pod Security Policy](#pod-security-policy)
  - [Notes on Mount Propagation](#notes-on-mount-propagation)
  - [Root and Privileged Permission](#root-and-privileged-permission)
  - [Installing open-iscsi](#installing-open-iscsi)
  - [Installing NFSv4 client](#installing-nfsv4-client)
  - [Installing Cryptsetup and LUKS](#installing-cryptsetup-and-luks)
  - [Installing Device Mapper Userspace Tool](#installing-device-mapper-userspace-tool)
- [Longhorn Command Line Tool](#longhorn-command-line-tool)
  - [Checking Prerequisites Using Longhorn Command Line Tool](#checking-prerequisites-using-longhorn-command-line-tool)
  - [Installing Prerequisites Using Longhorn Command Line Tool](#installing-prerequisites-using-longhorn-command-line-tool)

> **Note**: This quick installation guide uses some configurations which are not for production usage.
> Please see [Best Practices](../../best-practices/) for how to configure Longhorn for production usage.

Longhorn can be installed on a Kubernetes cluster in several ways:

- [Rancher Catalog App](./install-with-rancher)
- [kubectl](./install-with-kubectl/)
- [Helm](./install-with-helm/)
- [Helm Controller](./install-with-helm-controller/)
- [Fleet](./install-with-fleet/)
- [Flux](./install-with-flux/)
- [ArgoCD](./install-with-argocd/)

To install Longhorn in an air gapped environment, refer to [Air Gap Installation](../install/airgap).

For information on customizing Longhorn's default settings, refer to [Customizing Default Settings](../../advanced-resources/deploy/customizing-default-settings).

For information on deploying Longhorn on specific nodes and rejecting general workloads for those nodes, refer to the section on [Taints and Tolerations](../../advanced-resources/deploy/taint-toleration).

## Installation Requirements

Each node in the Kubernetes cluster where Longhorn is installed must fulfill the following requirements:

-  A container runtime compatible with Kubernetes (Docker v1.13+, containerd v1.3.7+, etc.)
-  Kubernetes >= v1.25
-  `open-iscsi` is installed, and the `iscsid` daemon is running on all the nodes. This is necessary, since Longhorn relies on `iscsiadm` on the host to provide persistent volumes to Kubernetes. For help installing `open-iscsi`, refer to [Installing open-iscsi](#installing-open-iscsi).
-  RWX support requires that each node has a NFSv4 client installed.
    - For installing a NFSv4 client, refer to [Installing NFSv4 Client](#installing-nfsv4-client).
- The host filesystem supports the `file extents` feature to store the data. Currently we support:
    - ext4
    - XFS
- `bash`, `curl`, `findmnt`, `grep`, `awk`, `blkid`, `lsblk` must be installed.
- [Mount propagation](https://kubernetes-csi.github.io/docs/deploying.html#enabling-mount-propagation) must be enabled.

The Longhorn workloads must be able to run as root in order for Longhorn to be deployed and operated properly.

[Longhorn Command Line Tool](../../advanced-resources/longhornctl/) can be used to check the Longhorn environment for potential issues.

For the minimum recommended hardware, refer to the [best practices guide](../../best-practices/#minimum-recommended-hardware).

### OS/Distro Specific Configuration

You must perform additional setups before using Longhorn with certain operating systems and distributions.

- Google Kubernetes Engine (GKE): See [Longhorn CSI on GKE](../../advanced-resources/os-distro-specific/csi-on-gke).
- K3s clusters: See [Longhorn CSI on K3s](../../advanced-resources/os-distro-specific/csi-on-k3s).
- RKE clusters with CoreOS: See [Longhorn CSI on RKE and CoreOS](../../advanced-resources/os-distro-specific/csi-on-rke-and-coreos).
- OCP/OKD clusters: See [OKD Support](../../advanced-resources/os-distro-specific/okd-support).
- Talos Linux clusters: See [Talos Linux Support](../../advanced-resources/os-distro-specific/talos-linux-support).
- Container-Optimized OS: See [Container-Optimized OS Support](../../advanced-resources/os-distro-specific/container-optimized-os-support).

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

The `Server Version` should be >= v1.25.

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
  - /boot (read only): Get required modules' information from /boot/config-$(uname -r) on the host.
  - /dev: Block devices created by Longhorn are under the `/dev` path.
  - /proc (read only): Find the recognized host process like container runtime, then use `nsenter` to access the mounts on the host to understand disks usage.
  - /etc (read only): Read the necessary system configuration to get node status updated, for example, `nfsmount.conf`.
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
  systemctl enable iscsid
  systemctl start iscsid
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

- Container-Optimized OS: See [Container-Optimized OS Support](../../advanced-resources/os-distro-specific/container-optimized-os-support)

Please ensure iscsi_tcp module has been loaded before iscsid service starts. Generally, it should be automatically loaded along with the package installation.

```
modprobe iscsi_tcp
```

> **Important**: On SUSE and openSUSE, the `iscsi_tcp` module is included only in the `kernel-default` package. If the `kernel-default-base` package is installed on your system, you must replace it with `kernel-default`.

We also provide an `iscsi` installer to make it easier for users to install `open-iscsi` automatically. You can use the [Longhorn CLI](../../advanced-resources/longhornctl/) to install the prerequisites.

You can use the `longhornctl check preflight` command. This command verifies your Kubernetes cluster environment to ensure it meets Longhorn's requirements. It performs a series of checks that can help identify potential issues that may prevent Longhorn from functioning correctly.

Example:
```sh
> longhornctl check preflight
INFO[2025-08-22T12:58:40+08:00] Initializing preflight checker               
INFO[2025-08-22T12:58:40+08:00] Cleaning up preflight checker                
INFO[2025-08-22T12:58:42+08:00] Running preflight checker                    
INFO[2025-08-22T12:58:49+08:00] Retrieved preflight checker result:
ip-10-0-1-132:
  info:
  - Service iscsid is running
  - NFS4 is supported
  - Package nfs-client is installed
  - Package open-iscsi is installed
  - Package cryptsetup is installed
  - Package device-mapper is installed
  - Module dm_crypt is loaded
  warn:
  - Kube DNS "coredns" is set with fewer than 2 replicas; consider increasing replica count for high availability
INFO[2025-08-22T12:58:49+08:00] Cleaning up preflight checker                
INFO[2025-08-22T12:58:50+08:00] Completed preflight checker
```

In rare cases, it may be required to modify the installed SELinux policy to get Longhorn working. If you are running
an up-to-date version of a Fedora downstream distribution (e.g. Fedora, RHEL, Rocky, CentOS, etc.) and plan to leave
SELinux enabled, see [the KB](../../../../kb/troubleshooting-volume-attachment-fails-due-to-selinux-denials) for details.

### Installing NFSv4 client

In Longhorn system, backup feature requires NFSv4, v4.1 or v4.2, and ReadWriteMany (RWX) volume feature requires NFSv4.1. Before installing NFSv4 client userspace daemon and utilities, make sure the client kernel support is enabled on each Longhorn node.

- Check if `NFSv4` support is enabled in the kernel:
  ```
  cat /boot/config-`uname -r`| grep CONFIG_NFS_V4
  ```

- Check if `NFSv4.1` support is enabled in the kernel:
  ```
  cat /boot/config-`uname -r`| grep CONFIG_NFS_V4_1
  ```

- Check if `NFSv4.2` support is enabled in the kernel:
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

- For Container-Optimized OS, [the NFS is supported with the node image](https://cloud.google.com/kubernetes-engine/docs/concepts/node-images#storage_driver_support).

We also provide an `nfs` installer to make it easier for users to install `nfs-client` automatically. You can use this [Longhorn CLI](../../advanced-resources/longhornctl/) to install the prerequisite.

You can use the `longhornctl check preflight` command. This command verifies your Kubernetes cluster environment to ensure it meets Longhorn's requirements. It performs a series of checks that can help identify potential issues that may prevent Longhorn from functioning correctly.

Example:
```sh
> longhornctl check preflight
INFO[2025-08-22T12:58:40+08:00] Initializing preflight checker               
INFO[2025-08-22T12:58:40+08:00] Cleaning up preflight checker                
INFO[2025-08-22T12:58:42+08:00] Running preflight checker                    
INFO[2025-08-22T12:58:49+08:00] Retrieved preflight checker result:
ip-10-0-1-132:
  info:
  - Service iscsid is running
  - NFS4 is supported
  - Package nfs-client is installed
  - Package open-iscsi is installed
  - Package cryptsetup is installed
  - Package device-mapper is installed
  - Module dm_crypt is loaded
  warn:
  - Kube DNS "coredns" is set with fewer than 2 replicas; consider increasing replica count for high availability
INFO[2025-08-22T12:58:49+08:00] Cleaning up preflight checker                
INFO[2025-08-22T12:58:50+08:00] Completed preflight checker
```

> **Notice:**  
> These steps only verify that the kernel supports NFSv4, v4.1, or v4.2.  
> To verify the NFS version in use, run `mount | grep nfs` or `nfsstat -m` to confirm the mounted version. Using the correct NFS version is required for backup and RWX volume features in Longhorn.

### Installing Cryptsetup and LUKS

[Cryptsetup](https://gitlab.com/cryptsetup/cryptsetup) is an open-source utility used to conveniently set up `dm-crypt` based device-mapper targets and Longhorn uses [LUKS2](https://gitlab.com/cryptsetup/cryptsetup#luks-design) (Linux Unified Key Setup) format that is the standard for Linux disk encryption to support volume encryption.

The command used to install the cryptsetup tool differs depending on the Linux distribution.

- For Debian and Ubuntu, use this command:

  ```shell
  apt-get install cryptsetup
  ```

- For RHEL, CentOS, Rocky Linux and EKS with `EKS Kubernetes Worker AMI with AmazonLinux2 image`, use this command:

  ```shell
  yum install cryptsetup
  ```

- For SUSE/OpenSUSE, use this command:

  ```shell
  zypper install cryptsetup
  ```

### Installing Device Mapper Userspace Tool

The device mapper is a framework provided by the Linux kernel for mapping physical block devices onto higher-level virtual block devices. It forms the foundation of the `dm-crypt` disk encryption and provides the linear dm device on the top of v2 volume. The device mapper is typically included by default in many Linux distributions. Some lightweight or highly customized distributions or a minimal installation of a distribution might exclude it to save space or reduce complexity

The command used to install the device mapper differs depending on the Linux distribution.

- For Debian and Ubuntu, use this command:

  ```shell
  apt-get install dmsetup
  ```

- For RHEL, CentOS, Rocky Linux and EKS with `EKS Kubernetes Worker AMI with AmazonLinux2 image`, use this command:

  ```shell
  yum install device-mapper
  ```

- For SUSE/OpenSUSE, use this command:

  ```shell
  zypper install device-mapper
  ```

## Longhorn Command Line Tool

### Checking Prerequisites Using Longhorn Command Line Tool

The `longhornctl` tool is a CLI for Longhorn operations. For more information, see [Command Line Tool (longhornctl)](../../advanced-resources/longhornctl/).

To check the prerequisites and configurations, download the tool and run the `check` sub-command:

```shell
# For AMD64 platform
curl -sSfL -o longhornctl https://github.com/longhorn/cli/releases/download/v{{< current-version >}}/longhornctl-linux-amd64
# For ARM platform
curl -sSfL -o longhornctl https://github.com/longhorn/cli/releases/download/v{{< current-version >}}/longhornctl-linux-arm64

chmod +x longhornctl
./longhornctl check preflight
```

Example of result:

```shell
INFO[2024-01-01T00:00:01Z] Initializing preflight checker
INFO[2024-01-01T00:00:01Z] Cleaning up preflight checker
INFO[2024-01-01T00:00:01Z] Running preflight checker
INFO[2024-01-01T00:00:02Z] Retrieved preflight checker result:
worker1:
  info:
  - Service iscsid is running
  - NFS4 is supported
  - Package nfs-common is installed
  - Package open-iscsi is installed
  warn:
  - multipathd.service is running. Please refer to https://longhorn.io/kb/troubleshooting-volume-with-multipath/ for more information.
worker2:
  info:
  - Service iscsid is running
  - NFS4 is supported
  - Package nfs-common is not installed
  - Package open-iscsi is installed
```

Use the `install` sub-command to install and set up the preflight dependencies before installing Longhorn.

```shell
./longhornctl install preflight
```

> **Note**:
> Some immutable Linux distributions, such as SUSE Linux Enterprise Micro (SLE Micro), require you to reboot worker nodes after running the `install` sub-command. After the reboot, you must run the `install` sub-command again to complete the operation.
>
> The documentation of the Linux distribution you are using should outline such requirements. For example, the [SLE Micro documentation](https://documentation.suse.com/sle-micro/6.0/html/Micro-transactional-updates/index.html#reference-transactional-update-usage) explains how all changes made by the `transactional-update` command become active only after the node is rebooted.

### Installing Prerequisites Using Longhorn Command Line Tool

```shell
longhornctl --kubeconfig ~/.kube/config --image longhornio/longhorn-cli:v{{< current-version >}} install preflight
```

Example of result:

```shell
INFO[2025-03-11T08:17:57+08:00] Initializing preflight installer
INFO[2025-03-11T08:17:57+08:00] Cleaning up preflight installer
INFO[2025-03-11T08:17:57+08:00] Running preflight installer
INFO[2025-03-11T08:17:57+08:00] Installing dependencies with package manager
INFO[2025-03-11T08:18:28+08:00] Installed dependencies with package manager
INFO[2025-03-11T08:18:28+08:00] Cleaning up preflight installer
INFO[2025-03-11T08:18:28+08:00] Completed preflight installer. Use 'longhornctl check preflight' to check the result.
```