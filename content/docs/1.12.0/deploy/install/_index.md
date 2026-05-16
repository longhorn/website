---
title: Quick Installation
description: Install Longhorn on Kubernetes
weight: 1
---

- [Longhorn Installation Methods](#longhorn-installation-methods)
- [Installation Requirements](#installation-requirements)
  - [Platform-Specific Configuration](#platform-specific-configuration)
  - [Kubernetes Version](#kubernetes-version)
  - [Pod Security Policy](#pod-security-policy)
  - [Mount Propagation](#mount-propagation)
  - [Root and Privileged Permission](#root-and-privileged-permission)
  - [Install NFSv4 client](#install-nfsv4-client)
  - [Install Cryptsetup and LUKS](#install-cryptsetup-and-luks)
  - [Install Device Mapper Userspace Tool](#install-device-mapper-userspace-tool)
  - [V1 Data Engine Requirements](#v1-data-engine-requirements)
    - [Install open-iscsi](#install-open-iscsi)
  - [V2 Data Engine Requirements](#v2-data-engine-requirements)
    - [IOMMU Group Isolation Requirement](#iommu-group-isolation-requirement)
    - [Load Kernel Modules](#load-kernel-modules)
    - [Enable HugePages](#enable-hugepages)
      - [Configure Huge Pages Persistently](#configure-huge-pages-persistently)
    - [Restart kubelet](#restart-kubelet)
    - [Enable V2 Data Engine](#enable-v2-data-engine)
    - [Add `block-type` Disks in Longhorn Nodes](#add-block-type-disks-in-longhorn-nodes)
      - [Prepare Disks](#prepare-disks)
      - [Add Disks to `node.longhorn.io`](#add-disks-to-nodelonghornio)
- [Longhorn Command Line Tool](#longhorn-command-line-tool)
  - [Download longhornctl](#download-longhornctl)
  - [Check Prerequisites](#check-prerequisites)
  - [Install Prerequisites](#install-prerequisites)

---

## Longhorn Installation Methods

Longhorn can be installed on a Kubernetes cluster in several ways:

- [Rancher Catalog App](./install-with-rancher)
- [kubectl](./install-with-kubectl/)
- [Helm](./install-with-helm/)
- [Helm Controller](./install-with-helm-controller/)
- [Fleet](./install-with-fleet/)
- [Flux](./install-with-flux/)
- [ArgoCD](./install-with-argocd/)

For air gapped environments, refer to [Air Gap Installation](../install/airgap).

For customizing Longhorn's default settings, refer to [Customizing Default Settings](../../advanced-resources/deploy/customizing-default-settings).

For deploying Longhorn on specific nodes and rejecting general workloads for those nodes, refer to [Taints and Tolerations](../../advanced-resources/deploy/taint-toleration).

## Installation Requirements

Unless otherwise noted, the requirements in this section apply to both the V1 and V2 Data Engines. Engine-specific requirements are listed in [V1 Data Engine Requirements](#v1-data-engine-requirements) and [V2 Data Engine Requirements](#v2-data-engine-requirements).

Each node in the Kubernetes cluster where Longhorn is installed must fulfill the following requirements:

-  A container runtime compatible with Kubernetes (Docker v1.13+, containerd v1.3.7+, etc.)
-  Kubernetes >= v1.25
-  RWX support requires that each node has a NFSv4 client installed.
    - For installing a NFSv4 client, refer to [Install NFSv4 client](#install-nfsv4-client).
- `bash`, `curl`, `findmnt`, `grep`, `awk`, `blkid`, `lsblk` must be installed.
- [Mount propagation](https://kubernetes-csi.github.io/docs/deploying.html#enabling-mount-propagation) must be enabled.

The Longhorn workloads must be able to run as **root** in order for Longhorn to be deployed and operated properly.

[Longhorn Command Line Tool](../../advanced-resources/longhornctl/) can be used to check the Longhorn environment for potential issues.

For the minimum recommended hardware, refer to the [Best Practices](../../best-practices/#minimum-recommended-hardware).

### Platform-Specific Configuration

You must perform additional setups before using Longhorn with certain operating systems and distributions.

- Google Kubernetes Engine (GKE): See [Longhorn CSI on GKE](../../advanced-resources/os-distro-specific/csi-on-gke).
- K3s clusters: See [Longhorn CSI on K3s](../../advanced-resources/os-distro-specific/csi-on-k3s).
- RKE clusters with CoreOS: See [Longhorn CSI on RKE and CoreOS](../../advanced-resources/os-distro-specific/csi-on-rke-and-coreos).
- OCP/OKD clusters: See [OKD Support](../../advanced-resources/os-distro-specific/okd-support).
- Talos Linux clusters: See [Talos Linux Support](../../advanced-resources/os-distro-specific/talos-linux-support).
- Container-Optimized OS: See [Container-Optimized OS Support](../../advanced-resources/os-distro-specific/container-optimized-os-support).

### Kubernetes Version

Longhorn requires Kubernetes >= v1.25.

Use the following command to verify your cluster version:

```shell
kubectl version
```

Example output:

```shell
Client Version: version.Info{Major:"1", Minor:"26", GitVersion:"v1.26.10", GitCommit:"b8609d4dd75c5d6fba4a5eaa63a5507cb39a6e99", GitTreeState:"clean", BuildDate:"2023-10-18T11:44:31Z", GoVersion:"go1.20.10", Compiler:"gc", Platform:"linux/amd64"}
Server Version: version.Info{Major:"1", Minor:"26", GitVersion:"v1.26.10+k3s2", GitCommit:"cb5cb5557f34e240e38c68a8c4ca2506c68b1d86", GitTreeState:"clean", BuildDate:"2023-11-08T03:21:46Z", GoVersion:"go1.20.10", Compiler:"gc", Platform:"linux/amd64"}
```

### Pod Security Policy

Starting with v1.0.2, Longhorn is shipped with a default Pod Security Policy that will give Longhorn the necessary privileges to be able to run properly.

No special configuration is needed for Longhorn to work properly on clusters with Pod Security Policy enabled.

### Mount Propagation

If your Kubernetes cluster was provisioned by Rancher v2.0.7+ or later, the MountPropagation feature is enabled by default.

If MountPropagation is disabled, Base Image feature will be disabled.

### Root and Privileged Permission

Longhorn components require root access with privileged permissions to achieve volume operations and management, because Longhorn relies on system resources on the host across different namespaces, for example, Longhorn uses `nsenter` to understand block devices' usage or encrypt/decrypt volumes on the host.

The following table lists the host paths Longhorn needs to access with root and privileged permissions.

| Host path | Purpose |
| --- | --- |
| **Longhorn Manager** | |
| `/boot` (read only) | Get required modules' information from `/boot/config-$(uname -r)` on the host. |
| `/dev` | Access block devices created by Longhorn. |
| `/proc` (read only) | Find the recognized host process like container runtime, then use `nsenter` to access the mounts on the host to understand disks usage. |
| `/etc` (read only) | Read necessary system configuration to get node status updated, for example, `nfsmount.conf`. |
| `/var/lib/longhorn` | The default path for storing volume data on a host. |
| **Longhorn Engine Image** | |
| `/var/lib/longhorn/engine-binaries` | The default path for storing the Longhorn engine binaries. |
| **Longhorn Instance Manager** | |
| `/` | Access any data path on this node and access Longhorn engine binaries. |
| `/dev` | Access block devices created by Longhorn. |
| `/proc` | Find the recognized host process like container runtime, then use `nsenter` to manage iSCSI targets and initiators, also some file system. |
| **Longhorn Share Manager** | |
| `/dev` | Access block devices created by Longhorn. |
| `/lib/modules` | Access kernel modules required by `cryptsetup` for volume encryption. |
| `/proc` | Find the recognized host process like container runtime, then use `nsenter` for volume encryption. |
| `/sys` | Support volume encryption by `cryptsetup`. |
| **Longhorn CSI Plugin** | |
| `/` | Perform host checks via the NFS customer mounter. This usage is deprecated and will be removed in a future release. |
| `/dev` | Access block devices created by Longhorn. |
| `/lib/modules` | Access kernel modules required by the Longhorn CSI plugin. |
| `/sys` | Support volume encryption by `cryptsetup`. |
| `/var/lib/kubelet/plugins/kubernetes.io/csi` | Create the staging path (via `NodeStageVolume`) of a block device. The staging path is bind-mounted to `/var/lib/kubelet/pods` (via `NodePublishVolume`) to support a single volume mounted to multiple Pods. |
| `/var/lib/kubelet/plugins_registry` | Register the CSI plugin with kubelet. |
| `/var/lib/kubelet/plugins/driver.longhorn.io` | Provide the socket path for communication with the Longhorn CSI driver. |
| `/var/lib/kubelet/pods` | Mount volumes from the target path via `NodePublishVolume`. |
| **Longhorn CSI Attacher/Provisioner/Resizer/Snapshotter** | |
| `/var/lib/kubelet/plugins/driver.longhorn.io` | Provide the socket path for communication with the Longhorn CSI driver. |
| **Longhorn Backing Image Manager** | |
| `/var/lib/longhorn` | The default path for storing data on the host. |
| **Longhorn Backing Image Data Source** | |
| `/var/lib/longhorn` | The default path for storing data on the host. |
| **Longhorn System Restore Rollout** | |
| `/var/lib/longhorn/engine-binaries` | The default path for storing the Longhorn engine binaries. |

In rare cases, it may be required to modify the installed SELinux policy to get Longhorn working. If you are running an up-to-date version of a Fedora downstream distribution (e.g. Fedora, RHEL, Rocky, CentOS, etc.) and plan to leave
SELinux enabled, see [the KB](../../../../kb/troubleshooting-volume-attachment-fails-due-to-selinux-denials) for details.

### Install NFSv4 client

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

You can also use the [Longhorn Command Line Tool](#longhorn-command-line-tool) to install `nfs-client` automatically.

> **Notice:**  
> These steps only verify that the kernel supports NFSv4, v4.1, or v4.2.  
> To verify the NFS version in use, run `mount | grep nfs` or `nfsstat -m` to confirm the mounted version. Using the correct NFS version is required for backup and RWX volume features in Longhorn.

### Install Cryptsetup and LUKS

[Cryptsetup](https://gitlab.com/cryptsetup/cryptsetup) is an open-source utility used to conveniently set up `dm-crypt` based device-mapper targets and Longhorn uses [Linux Unified Key Setup](https://gitlab.com/cryptsetup/cryptsetup#luks-design) (LUKS2) format that is the standard for Linux disk encryption to support volume encryption.

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

### Install Device Mapper Userspace Tool

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

### V1 Data Engine Requirements

This is the default installation path for Longhorn. If you complete the [Installation Requirements](#installation-requirements) and install Longhorn using one of the [supported methods](#longhorn-installation-methods), Longhorn runs with the V1 Data Engine by default.

In this default mode:

- Volumes use the V1 Data Engine.
- Volume data is stored on filesystem-type disks.
- Longhorn uses the default filesystem-type disk at `/var/lib/longhorn` unless you configure additional filesystem-type disks.

No additional data-engine-specific steps are required after installing Longhorn.

#### Install open-iscsi

Each Longhorn node that will host V1 volumes must also meet the following requirements:

- `open-iscsi` is installed, and the `iscsid` daemon is running on all the nodes. Longhorn relies on `iscsiadm` on the host to provide persistent volumes to Kubernetes. For help installing `open-iscsi`, refer to [Install open-iscsi](#install-open-iscsi).
- The host filesystem supports the `file extents` feature to store the data. Currently we support:
  - ext4
  - XFS

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

You can also use the [Longhorn Command Line Tool](#longhorn-command-line-tool) to install `open-iscsi` automatically.

### V2 Data Engine Requirements

This section is for clusters that will use the **V2 Data Engine**. Complete the shared [Installation Requirements](#installation-requirements) first, then prepare each V2 node and enable the V2 Data Engine.

Longhorn's V2 Data Engine leverages the Storage Performance Development Kit (SPDK) to deliver enhanced performance with lower I/O latency and higher IOPS and throughput.

The V2 Data Engine is currently a **Technical Preview** feature. For feature coverage, see [V1 and V2 Volume Differences and Feature Support](../../v1-v2-volume-behavior-and-feature-parity/).

Before you enable the V2 Data Engine, ensure that each Longhorn node that will host V2 volumes meets the following requirements:

- AMD64 or ARM64 CPU
  - AMD64 CPUs require SSE4.2 instruction support.
- Linux kernel 5.19 or later for NVMe/TCP support
  - Linux kernel 6.7 or later is recommended for better stability.
- Required kernel modules:
  - `vfio_pci`
  - `uio_pci_generic`
  - `nvme-tcp`
- Huge page support:
  - 2 GiB of 2 MiB-sized pages on each Longhorn node
- Raw block disks for V2 volumes
  - Local NVMe disks are strongly recommended for best performance.

When the V2 Data Engine is enabled, each V2 instance-manager pod typically consumes one dedicated CPU core because the `spdk_tgt` process uses intensive polling.

After confirming these prerequisites, configure the V2 environment on each node and then enable the V2 Data Engine in Longhorn.

#### IOMMU Group Isolation Requirement

For the V2 Data Engine (SPDK) to claim a disk, the NVMe device must be isolatable. Because SPDK uses `vfio-pci`, the following hardware constraints apply:

- VFIO must claim the entire IOMMU group.
- If a group contains multiple devices, all devices in that group must be bound to VFIO.
- The Linux kernel does not allow binding a PCIe bridge or switch port to `vfio-pci`.

If your hardware topology places an NVMe device in the same IOMMU group as its parent PCIe bridge, SPDK cannot initialize the device. In such cases, the disk must be used in **AIO mode** instead of the SPDK NVMe path.

#### Load Kernel Modules

For Debian and Ubuntu, install Linux kernel extra modules before loading the required kernel modules:

```shell
apt install -y linux-modules-extra-`uname -r`
```

To configure the necessary kernel modules and huge pages for SPDK, you can use the [Longhorn CLI](../../advanced-resources/longhornctl/).

Or, load the required modules manually on each Longhorn node:

```shell
modprobe vfio_pci
modprobe uio_pci_generic
modprobe nvme-tcp
```

To avoid reloading these modules after every reboot, configure your operating system to load them automatically during boot.

#### Enable HugePages

SPDK uses huge pages for performance and memory efficiency. You must configure 2 MiB-sized huge pages on each Longhorn node. Specifically, 1024 pages must be available on each node, which is equivalent to 2 GiB in total.

To allocate huge pages temporarily:

```shell
echo 1024 > /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages
```

##### Configure Huge Pages Persistently

Huge page allocations made through `/sys/kernel/mm/hugepages/...` are not persistent across reboots. To make the allocation persistent, configure the kernel boot parameters.

1. Update `/etc/default/grub` and append the required huge page parameters:

   ```bash
   GRUB_CMDLINE_LINUX="hugepagesz=2M hugepages=1024"
   ```

1. Apply the GRUB configuration:

   BIOS systems:

   ```bash
   sudo update-grub
   ```

   RHEL/SUSE with GRUB2:

   ```bash
   sudo grub2-mkconfig -o /boot/grub2/grub.cfg
   ```

   UEFI systems:

   ```bash
   sudo grub2-mkconfig -o /boot/efi/EFI/<distro>/grub.cfg
   ```

1. Reboot the node:

   ```bash
   sudo reboot
   ```

1. Verify the huge pages:

   ```bash
   grep Huge /proc/meminfo
   ```

   Expected output:

   ```text
   HugePages_Total:    1024
   Hugepagesize:       2048 kB
   ```

1. Verify the Kubernetes node resources:

   ```bash
   kubectl describe node <node-name>
   ```

   Expected in **Capacity** and **Allocatable**:

   ```text
   hugepages-2Mi: 2Gi
   ```

#### Restart kubelet

After configuring kernel modules and huge pages, restart `kubelet` on each node.

#### Enable V2 Data Engine

After Longhorn is installed, enable the V2 Data Engine by changing the `v2-data-engine` setting to `true`.

You can do this in the Longhorn UI under **Settings > V2 Data Engine**.

After the setting is enabled, the instance-manager pods are automatically restarted.

> **Note**
>
> When the V2 Data Engine is enabled, each instance-manager pod for the V2 Data Engine typically consumes one dedicated CPU core because the `spdk_tgt` process uses intensive polling.

#### Add `block-type` Disks in Longhorn Nodes

Unlike `filesystem-type` disks that are designed for legacy volumes, volumes using the V2 Data Engine are persistent on `block-type` disks. Therefore, nodes that host V2 volumes must provide `block-type` disks.

##### Prepare Disks

If no extra disks are available on the Longhorn nodes, you can create loop block devices for testing:

```shell
dd if=/dev/zero of=blockfile bs=1M count=10240
losetup -f blockfile
```

To display the assigned block device path:

```shell
losetup -j blockfile
```

##### Add Disks to `node.longhorn.io`

Starting with v1.11.0, Longhorn prevents adding block disks that contain an existing file system or partition table. Clean the disk first:

```shell
wipefs -a /path/to/block/device
```

You can add the disk through the Longhorn UI by setting **Disk Type** to **Block**, or by editing the `node.longhorn.io` resource:

```shell
kubectl -n longhorn-system edit node.longhorn.io <NODE NAME>
```

Add the disk under `spec.disks`:

```yaml
<DISK NAME>:
  allowScheduling: true
  evictionRequested: false
  path: /PATH/TO/BLOCK/DEVICE
  storageReserved: 0
  tags: []
  diskType: block
```

## Longhorn Command Line Tool

You can use `longhornctl` to check and install prerequisites for either the default V1 installation path or the V2 Data Engine installation path.

### Download longhornctl

Download the `longhornctl` binary for your platform:

The `longhornctl` tool is a CLI for Longhorn operations. For more information, see [Command Line Tool (longhornctl)](../../advanced-resources/longhornctl/).

```shell
# For AMD64 platform
curl -sSfL -o longhornctl https://github.com/longhorn/cli/releases/download/v{{< current-version >}}/longhornctl-linux-amd64
# For ARM platform
curl -sSfL -o longhornctl https://github.com/longhorn/cli/releases/download/v{{< current-version >}}/longhornctl-linux-arm64

chmod +x longhornctl
```

### Check Prerequisites

Use the base preflight check for the default V1 installation path. If you plan to use the V2 Data Engine, run the same check with `--enable-spdk` to validate the additional V2 requirements.

For V1 Data Engine:

```shell
./longhornctl check preflight
```

Example of result:

```shell
./longhornctl check preflight
```

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

For V2 Data Engine:

```shell
./longhornctl check preflight --enable-spdk
```

This command validates, among other things:

- CPU instruction requirements
- HugePages availability
- SPDK-related kernel modules
- Base Longhorn dependencies such as `open-iscsi` and NFS support

### Install Prerequisites

Use the base install command for the default V1 installation path. If you plan to use the V2 Data Engine, run the install command with `--enable-spdk` to install the additional V2 prerequisites.

For V1 Data Engine:

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

> **Note**:
> Some immutable Linux distributions, such as SUSE Linux Enterprise Micro (SLE Micro), require you to reboot worker nodes after running the `install` sub-command. After the reboot, you must run the `install` sub-command again to complete the operation.
>
> The documentation of the Linux distribution you are using should outline such requirements. For example, the [SLE Micro documentation](https://documentation.suse.com/sle-micro/6.0/html/Micro-transactional-updates/index.html#reference-transactional-update-usage) explains how all changes made by the `transactional-update` command become active only after the node is rebooted.

For V2 Data Engine:

```shell
longhornctl --kubeconfig ~/.kube/config --image longhornio/longhorn-cli:v{{< current-version >}} install preflight --enable-spdk
```

After installation, run the check command again to verify that all V2-related prerequisites are correctly configured.
