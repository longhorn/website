---
  title: Quick Start
  weight: 3
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
INFO: Requested 512 hugepages but 512 already allocated on node0
SPDK environment is configured successfully
```

Or, you can install them manually by following these steps.
- Load the kernel modules on the each Longhorn node
  ```
  modprobe uio
  modprobe uio_pci_generic
  ```

- Configure huge pages
  SPDK utilizes huge pages to enhance performance and minimize memory overhead. To enable the usage of huge pages, it is necessary to configure 2MiB-sized huge pages on each Longhorn node. Specifically, 512 pages (equivalent to a total of 1 GiB) need to be available on each Longhorn node. To allocate the huge pages, run the following commands on each node.
  ```
  echo 512 > /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages
  ```

  To make the change permanent, add the following line to the file /etc/sysctl.conf.
  ```
  echo "vm.nr_hugepages=512" >> /etc/sysctl.conf
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
csi-attacher-6488f75fb4-48pnb                       1m           19Mi
csi-attacher-6488f75fb4-94m6r                       1m           16Mi
csi-attacher-6488f75fb4-zmwfm                       1m           15Mi
csi-provisioner-6785d78459-6tps7                    1m           18Mi
csi-provisioner-6785d78459-bj89g                    1m           23Mi
csi-provisioner-6785d78459-c5dzt                    1m           17Mi
csi-resizer-d9bb7b7fc-25m8b                         1m           17Mi
csi-resizer-d9bb7b7fc-fncjf                         1m           15Mi
csi-resizer-d9bb7b7fc-t5dw7                         1m           17Mi
csi-snapshotter-5b89555c8f-76ptq                    1m           15Mi
csi-snapshotter-5b89555c8f-7vgtv                    1m           19Mi
csi-snapshotter-5b89555c8f-vkhd8                    1m           17Mi
engine-image-ei-b907910b-5vp8h                      12m          15Mi
engine-image-ei-b907910b-9krcz                      17m          15Mi
instance-manager-b3735b3e6d0a9e27d1464f548bdda5ec   1000m        29Mi
instance-manager-cbe60909512c58798690f692b883e5a9   1001m        27Mi
longhorn-csi-plugin-qf9kt                           1m           61Mi
longhorn-csi-plugin-zk6sm                           1m           60Mi
longhorn-driver-deployer-7d46fd5945-8tfmk           1m           24Mi
longhorn-manager-nm925                              6m           137Mi
longhorn-manager-np849                              6m           126Mi
longhorn-ui-54df99bfc-2lc8w                         0m           2Mi
longhorn-ui-54df99bfc-w6dts                         0m           2Mi
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
    hugepages-2Mi: 1Gi
    memory: 31813168Ki
    pods: "110"
  capacity:
    cpu: "8"
    ephemeral-storage: 209681388Ki
    hugepages-1Gi: "0"
    hugepages-2Mi: 1Gi
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

Use following command to create a StorageClass called `longhorn-spdk`. Set `parameters.backendStoreDriver`  to `v2` to utilize V2 Data Engine.
```
kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/v{{< current-version >}}/examples/v2/storageclass.yaml
```

### Create Longhorn Volumes

Create a Pod that uses Longhorn volumes using V2 Data Engine by running this command:
```
kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/v{{< current-version >}}/examples/v2/pod_with_pvc.yaml
```

Or, if you are creating a volume on Longhorn UI, please specify the `Backend Data Engine` as `v2`.
