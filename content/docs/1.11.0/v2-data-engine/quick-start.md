---
title: Quick Start
weight: 2
aliases:
- /spdk/quick-start.md
---

**Table of Contents**
- [Prerequisites](#prerequisites)
  - [Load Kernel Modules](#load-kernel-modules)
  - [Enable HugePages](#enable-hugepages)
  - [Restart `kubelet`](#restart-kubelet)
  - [Check Environment](#check-environment)
    - [Using the Longhorn Command Line Tool](#using-the-longhorn-command-line-tool)
    - [Use Longhorn Command Line Tool](#use-longhorn-command-line-tool)
- [Installation](#installation)
  - [Install Longhorn System](#install-longhorn-system)
  - [Enable V2 Data Engine](#enable-v2-data-engine)
  - [CPU and Memory Usage](#cpu-and-memory-usage)
  - [Add `block-type` Disks in Longhorn Nodes](#add-block-type-disks-in-longhorn-nodes)
    - [Prepare disks](#prepare-disks)
    - [Add disks to `node.longhorn.io`](#add-disks-to-nodelonghornio)
- [Application Deployment](#application-deployment)
  - [Create a StorageClass](#create-a-storageclass)
  - [Create Longhorn Volumes](#create-longhorn-volumes)

---

Longhorn's V2 Data Engine harnesses the power of the Storage Performance Development Kit (SPDK) to elevate its overall performance. The integration significantly reduces I/O latency while simultaneously boosting IOPS and throughput. The enhancement provides a high-performance storage solution capable of meeting diverse workload demands.

**V2 Data Engine is currently an experimental feature and should NOT be utilized in a production environment.** At present, a volume with V2 Data Engine only supports

- Volume lifecycle (creation, attachment, detachment and deletion)
- Degraded volume
- Block disk management
- Orphaned replica management

In addition to the features mentioned above, additional functionalities such as replica number adjustment, online replica rebuilding, snapshot, backup, restore and so on will be introduced in future versions.

This tutorial will guide you through the process of configuring the environment and create Kubernetes persistent storage resources of persistent volumes (PVs) and persistent volume claims (PVCs) that correspond to Longhorn volumes using V2 Data Engine.

## Prerequisites

### Load Kernel Modules

For Debian and Ubuntu, please install Linux kernel extra modules before loading the kernel modules

```
apt install -y linux-modules-extra-`uname -r`
```

To configure the necessary kernel modules and huge pages for SPDK, you can use the [Longhorn CLI](../../advanced-resources/longhornctl/). 

Or, you can install them manually by following these steps.
- Load the kernel modules on the each Longhorn node
  ```
  modprobe vfio_pci
  modprobe uio_pci_generic
  modprobe nvme-tcp
  ```

Alternatively, rather than manually loading kernel modules `vfio_pci`, `uio_pci_generic` and `nvme-tcp` each time after reboot, you can streamline the process by configuring automatic module loading during the boot sequence. For detailed instructions, please consult the manual provided by your operating system.

Reference:
- [SUSE/OpenSUSE: Loading kernel modules automatically on boot](https://documentation.suse.com/sles/15-SP4/html/SLES-all/cha-mod.html#sec-mod-modprobe-d)
- [Ubuntu: Configure kernel modules to load at boot](https://manpages.ubuntu.com/manpages/jammy/man5/modules-load.d.5.html)
- [RHEL: Loading kernel modules automatically at system boot time](https://access.redhat.com/documentation/zh-tw/red_hat_enterprise_linux/8/html/managing_monitoring_and_updating_the_kernel/managing-kernel-modules_managing-monitoring-and-updating-the-kernel)

### Enable HugePages

#### Configure huge pages

SPDK uses huge pages for enhancing performance and minimizing memory overhead. You must configure 2 MiB-sized huge pages on each Longhorn node to enable usage of huge pages. Specifically, 1024 pages (equivalent to a total of 2 GiB) must be available on each Longhorn node.

To allocate huge pages, run the following commands on each node.
  ```
  echo 1024 > /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages
  ```

Huge page allocations made using `/sys/kernel/mm/hugepages/...` are not persistent and will be reset after reboot. To make the huge page allocation persistent, you have two options:

#### Permanently (Recommended)

To pre-allocate huge pages permanently, configure the kernel boot parameters.

1. **Update GRUB configuration**

    Edit `/etc/default/grub` and add the required huge page parameters.

    Example for allocating **1024 × 2 MiB** pages (2 GiB total):

    ```bash
    GRUB_CMDLINE_LINUX="hugepagesz=2M hugepages=1024"
    ```

    If the node already has parameters, append rather than overwrite.

2. **Apply the GRUB configuration**

    On BIOS systems:

    ```bash
    sudo update-grub
    ```

    On RHEL/SUSE (GRUB2):

    ```bash
    sudo grub2-mkconfig -o /boot/grub2/grub.cfg
    ```

    On UEFI systems:

    ```bash
    sudo grub2-mkconfig -o /boot/efi/EFI/<distro>/grub.cfg
    ```

3. **Reboot the node**

    ```bash
    sudo reboot
    ```

4. **Verify the huge pages**

    ```bash
    grep Huge /proc/meminfo
    ```

    Expected output:

    ```
    HugePages_Total:    1024
    Hugepagesize:       2048 kB
    ```

5. **Verify the huge pages resources**

    ```bash
    kubectl describe node <node-name>
    ```

    Expected in **Capacity** and **Allocatable**:

    ```
    hugepages-2Mi: 2Gi
    ```

#### Alternative: Using sysctl (not recommended for persistent allocation)

Adding this line to `/etc/sysctl.conf`:

```bash
vm.nr_hugepages=1024
```

This **does not persist** across reboot on many distributions because huge pages must be allocated early in the boot process. Use only when GRUB modification is not allowed.

### Restart `kubelet`

After finishing the above steps, restart kubelet on each node.

### Check Environment

#### Using the Longhorn Command Line Tool

The `longhornctl` tool is a CLI for Longhorn operations. For more information, see [Command Line Tool (longhornctl)](../../advanced-resources/longhornctl/).

To check the prerequisites and configurations, download the tool and run the `check` sub-command:

```shell
# For AMD64 platform
curl -sSfL -o longhornctl https://github.com/longhorn/cli/releases/download/v{{< current-version >}}/longhornctl-linux-amd64
# For ARM platform
curl -sSfL -o longhornctl https://github.com/longhorn/cli/releases/download/v{{< current-version >}}/longhornctl-linux-arm64

chmod +x longhornctl
./longhornctl check preflight --enable-spdk
```

Example of result:

```shell
INFO[2024-01-10T00:00:01Z] Initializing preflight checker
INFO[2024-01-01T00:00:01Z] Cleaning up preflight checker
INFO[2024-01-01T00:00:01Z] Running preflight checker
INFO[2024-01-01T00:00:02Z] Retrieved preflight checker result:
worker1:
  error:
  - 'HugePages is insufficient. Required 2MiB HugePages: 1024 pages, Total 2MiB HugePages: 0 pages'
  - 'Module nvme_tcp is not loaded: failed to execute: nsenter [--mount=/host/proc/204896/ns/mnt --net=/host/proc/204896/ns/net grep nvme_tcp /proc/modules], output , stderr : exit status 1'
  - 'Module uio_pci_generic is not loaded: failed to execute: nsenter [--mount=/host/proc/204896/ns/mnt --net=/host/proc/204896/ns/net grep uio_pci_generic /proc/modules], output , stderr : exit status 1'
  info:
  - Service iscsid is running
  - NFS4 is supported
  - Package nfs-common is installed
  - Package open-iscsi is installed
  - CPU instruction set sse4_2 is supported
  warn:
  - multipathd.service is running. Please refer to https://longhorn.io/kb/troubleshooting-volume-with-multipath/ for more information.
```

Use the `install` sub-command to install and set up the preflight dependencies before installing Longhorn.

```shell
master:~# ./longhornctl install preflight --enable-spdk
INFO[2024-01-01T00:00:03Z] Initializing preflight installer
INFO[2024-01-01T00:00:03Z] Cleaning up preflight installer
INFO[2024-01-01T00:00:03Z] Running preflight installer
INFO[2024-01-01T00:00:03Z] Installing dependencies with package manager
INFO[2024-01-01T00:00:10Z] Installed dependencies with package manager
INFO[2024-01-01T00:00:10Z] Cleaning up preflight installer
INFO[2024-01-01T00:00:10Z] Completed preflight installer. Use 'longhornctl check preflight' to check the result.
```

> **Note**:
> Some immutable Linux distributions, such as SUSE Linux Enterprise Micro (SLE Micro), require you to reboot worker nodes after running the `install` sub-command. After the reboot, you must run the `install` sub-command again to complete the operation.
>
> The documentation for your Linux distribution should outline such requirements. For example, the [SLE Micro documentation](https://documentation.suse.com/sle-micro/6.0/html/Micro-transactional-updates/index.html#reference-transactional-update-usage) explains that all changes made by the `transactional-update` command become active only after the node is rebooted.

After installing and setting up the preflight dependencies, you can run the `check` sub-command again to verify that all environment settings are correct.

```shell
master:~# ./longhornctl check preflight --enable-spdk
INFO[2024-01-01T00:00:13Z] Initializing preflight checker
INFO[2024-01-01T00:00:13Z] Cleaning up preflight checker
INFO[2024-01-01T00:00:13Z] Running preflight checker
INFO[2024-01-01T00:00:16Z] Retrieved preflight checker result:
worker1:
  info:
  - Service iscsid is running
  - NFS4 is supported
  - Package nfs-common is installed
  - Package open-iscsi is installed
  - CPU instruction set sse4_2 is supported
  - HugePages is enabled
  - Module nvme_tcp is loaded
  - Module uio_pci_generic is loaded
```

#### Use Longhorn Command Line Tool

Make sure everything is correctly configured and installed by
```
longhornctl --kube-config ~/.kube/config --image longhornio/longhorn-cli:v{{< current-version >}} install preflight --enable-spdk
```

See [Longhorn Command Line Tool](../../advanced-resources/longhornctl/) for more information.

## Installation

### Install Longhorn System

Follow the steps in Quick Installation to install Longhorn system.

### Enable V2 Data Engine

Enable the V2 Data Engine by changing the `v2-data-engine` setting to `true` after installation. Following this, the instance-manager pods will be automatically restarted.

Or, you can enable it in `Settings > V2 Data Engine`.

### CPU and Memory Usage

When the V2 Data Engine is enabled, each Instance Manager pod for the V2 Data Engine uses 1 CPU core. The high CPU usage is caused by `spdk_tgt`, a process running in each Instance Manager pod that handles input/output (IO) operations and requires intensive polling. `spdk_tgt` consumes 100% of a dedicated CPU core to efficiently manage and process the IO requests, ensuring optimal performance and responsiveness for storage operations.

```
NAME                                                CPU(cores)   MEMORY(bytes)
csi-attacher-57c5fd5bdf-jsfs4                       1m           7Mi
csi-attacher-57c5fd5bdf-kb6dv                       1m           9Mi
csi-attacher-57c5fd5bdf-s7fb6                       1m           7Mi
csi-provisioner-7b95bf4b87-8xr6f                    1m           11Mi
csi-provisioner-7b95bf4b87-v4gwb                    1m           9Mi
csi-provisioner-7b95bf4b87-vnt58                    1m           9Mi
csi-resizer-6df9886858-6v2ds                        1m           8Mi
csi-resizer-6df9886858-b6mns                        1m           9Mi
csi-resizer-6df9886858-l4vmj                        1m           8Mi
csi-snapshotter-5d84585dd4-4dwkz                    1m           7Mi
csi-snapshotter-5d84585dd4-km8bc                    1m           9Mi
csi-snapshotter-5d84585dd4-kzh6w                    1m           7Mi
engine-image-ei-b907910b-79k2s                      3m           19Mi
instance-manager-214803c4f23376af5a75418299b12ad6   1015m        133Mi (for V2 Data Engine)
instance-manager-4550bbc4938ff1266584f42943b511ad   4m           15Mi  (for V1 Data Engine)
longhorn-csi-plugin-nz94f                           1m           26Mi
longhorn-driver-deployer-556955d47f-h5672           1m           12Mi
longhorn-manager-2n9hd                              4m           42Mi
longhorn-ui-58db78b68-bzzz8                         0m           2Mi
longhorn-ui-58db78b68-ffbxr                         0m           2Mi
```


You can observe the utilization of allocated huge pages on each node by running the command `kubectl get node <node name> -o yaml`.
```
# kubectl get node sles-pool1-07437316-4jw8f -o yaml
...

status:
  ...
  allocatable:
    cpu: "8"
    ephemeral-storage: "203978054087"
    hugepages-1Gi: "0"
    hugepages-2Mi: 2Gi
    memory: 31813168Ki
    pods: "110"
  capacity:
    cpu: "8"
    ephemeral-storage: 209681388Ki
    hugepages-1Gi: "0"
    hugepages-2Mi: 2Gi
    memory: 32861744Ki
    pods: "110"
...
```

### Add `block-type` Disks in Longhorn Nodes

Unlike `filesystem-type` disks that are designed for legacy volumes, volumes using V2 Data Engine are persistent on `block-type` disks. Therefore, it is necessary to equip Longhorn nodes with `block-type` disks.

#### Prepare disks

If there are no additional disks available on the Longhorn nodes, you can create loop block devices to test the feature. To accomplish this, execute the following command on each Longhorn node to create a 10 GiB block device.
```
dd if=/dev/zero of=blockfile bs=1M count=10240
losetup -f blockfile
```

To display the path of the block device when running the command `losetup -f blockfile`, use the following command.
```
losetup -j blockfile
```

#### Add disks to `node.longhorn.io`

You can add the disk by navigating to the Node UI page and specify the `Disk Type` as `Block`. Next, provide the block device's path in the `Path` field.

Or, edit the `node.longhorn.io` resource.
```
kubectl -n longhorn-system edit node.longhorn.io <NODE NAME>
```

Add the disk to `Spec.Disks`
```
<DISK NAME>:
  allowScheduling: true
  evictionRequested: false
  path: /PATH/TO/BLOCK/DEVICE
  storageReserved: 0
  tags: []
  diskType: block
```

Wait for a while, you will see the disk is displayed in the `Status.DiskStatus`.

## Application Deployment

After the installation and configuration, we can dynamically provision a Persistent Volume using V2 Data Engine as the following steps.

### Create a StorageClass

Run the following command to create a StorageClass named `longhorn-spdk`. Set `parameters.dataEngine` to `v2` to enable the V2 Data Engine.
```
kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/v{{< current-version >}}/examples/v2/storageclass.yaml
```

### Create Longhorn Volumes

Create a Pod that uses Longhorn volumes using V2 Data Engine by running this command:
```
kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/v{{< current-version >}}/examples/v2/pod_with_pvc.yaml
```
