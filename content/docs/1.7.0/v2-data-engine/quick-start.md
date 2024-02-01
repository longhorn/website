---
title: Quick Start
weight: 2
aliases:
- /spdk/quick-start.md
---

**Table of Contents**
- [Prerequisites](#prerequisites)
  - [Configure Kernel Modules and Huge Pages](#configure-kernel-modules-and-huge-pages)
  - [Load `nvme-tcp` Kernel Module](#load-nvme-tcp-kernel-module)
  - [Load Kernel Modules Automatically on Boot](#load-kernel-modules-automatically-on-boot)
  - [Restart `kubelet`](#restart-kubelet)
  - [Check Environment](#check-environment)
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

**V2 Data Engine is currently a PREVIEW feature and should NOT be utilized in a production environment.** At present, a volume with V2 Data Engine only supports

- Volume lifecycle (creation, attachment, detachment and deletion)
- Degraded volume
- Offline replica rebuilding
- Block disk management
- Orphaned replica management

In addition to the features mentioned above, additional functionalities such as replica number adjustment, online replica rebuilding, snapshot, backup, restore and so on will be introduced in future versions.

This tutorial will guide you through the process of configuring the environment and create Kubernetes persistent storage resources of persistent volumes (PVs) and persistent volume claims (PVCs) that correspond to Longhorn volumes using V2 Data Engine.

## Prerequisites

### Configure Kernel Modules and Huge Pages

For Debian and Ubuntu, please install Linux kernel extra modules before loading the kernel modules
```
apt install -y linux-modules-extra-`uname -r`
```

We provide a manifest that helps you configure the kernel modules and huge pages automatically, making it easier to set up.
```
kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/v{{< current-version >}}/deploy/prerequisite/longhorn-spdk-setup.yaml
```

And also can check the log with the following command to see the installation result.
```
Cloning into '/tmp/spdk'...
INFO: Requested 1024 hugepages but 1024 already allocated on node0
SPDK environment is configured successfully
```

Or, you can install them manually by following these steps.
- Load the kernel modules on the each Longhorn node
  ```
  modprobe uio
  modprobe uio_pci_generic
  ```

- Configure huge pages
SPDK leverages huge pages for enhancing performance and minimizing memory overhead. You must configure 2 MiB-sized huge pages on each Longhorn node to enable usage of huge pages. Specifically, 1024 pages (equivalent to a total of 2 GiB) must be available on each Longhorn node.

To allocate huge pages, run the following commands on each node.
  ```
  echo 1024 > /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages
  ```

  To make the change permanent, add the following line to the file /etc/sysctl.conf.
  ```
  echo "vm.nr_hugepages=1024" >> /etc/sysctl.conf
  ```

### Load `nvme-tcp` Kernel Module

We provide a manifest that helps you finish the deployment on each Longhorn node.
```
kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/v{{< current-version >}}/deploy/prerequisite/longhorn-nvme-cli-installation.yaml
```

Or, you can manually load `nvme-tcp` kernel module on the each Longhorn node
  ```
  modprobe nvme-tcp
  ```

### Load Kernel Modules Automatically on Boot

Rather than manually loading kernel modules `uio`, `uio_pci_generic` and `nvme-tcp` each time after reboot, you can streamline the process by configuring automatic module loading during the boot sequence. For detailed instructions, please consult the manual provided by your operating system.

Reference:
- [SUSE/OpenSUSE: Loading kernel modules automatically on boot](https://documentation.suse.com/sles/15-SP4/html/SLES-all/cha-mod.html#sec-mod-modprobe-d)
- [Ubuntu: Configure kernel modules to load at boot](https://manpages.ubuntu.com/manpages/jammy/man5/modules-load.d.5.html)
- [RHEL: Loading kernel modules automatically at system boot time](https://access.redhat.com/documentation/zh-tw/red_hat_enterprise_linux/8/html/managing_monitoring_and_updating_the_kernel/managing-kernel-modules_managing-monitoring-and-updating-the-kernel)

### Restart `kubelet`

After finishing the above steps, restart kubelet on each node.

### Check Environment

Make sure everything is correctly configured and installed by
```
bash -c "$(curl -sfL https://raw.githubusercontent.com/longhorn/longhorn/v{{< current-version >}}/scripts/environment_check.sh)" -s -s
```

## Installation

### Install Longhorn System

Follow the steps in Quick Installation to install Longhorn system.

### Enable V2 Data Engine

Enable the V2 Data Engine by changing the `v2-data-engine` setting to `true` after installation. Following this, the instance-manager pods will be automatically restarted.

Or, you can enable it in `Setting > General > V2 Data Engine`.

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

Or, if you are creating a volume on Longhorn UI, please specify the `Data Engine` as `v2`.
