---
  title: Quick Start
  weight: 1
---

Longhorn's SPDK Data Engine harnesses the power of the Storage Performance Development Kit (SPDK) to elevate its overall performance. The integration significantly reduces I/O latency while simultaneously boosting IOPS and throughput. The enhancement provides a high-performance storage solution capable of meeting diverse workload demands.

**SPDK Data Engine is currently a Preview feature and should NOT be utilized in a production environment.** At present, a volume with SPDK Data Engine only supports

- Volume lifecycle (creation, attachment, detachment and deletion)
- Degraded volume
- Offline replica rebuilding
- Block disk management
- Orphaned replica management

This tutorial will guide you through the process of configuring the environment and create Kubernetes persistent storage resources of persistent volumes (PVs) and persistent volume claims (PVCs) that correspond to Longhorn volumes using SPDK Data Engine.


## Prerequisites

### Configure Kernel Modules and Huge Pages

We provide a manifest that helps you configure the kernel modules and huge pages automatically, making it easier to set up.
```
kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/master/deploy/prerequisite/longhorn-spdk-setup.yaml
```

 can install them manually by following these steps.
- Load the kernel modules on the each worker node
  ```
  modprobe uio
  modprobe uio_pci_generic
  ```
- Configure huge pages
  2MiB-sized huge pages must be enabled on each worker node. 512 pages (i.e. 1 GiB total) must be available on each worker node. To allocate the huge pages, run the following commands on each node.
  ```
  echo 512 > /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages
  ```

  To make the change permanent, add the following line to the file /etc/sysctl.conf.
  ```
  echo "vm.nr_hugepages=512" >> /etc/sysctl.conf
  ```

### Install NVMe Userspace Tool and Load `nvme-tcp` Kernel Module

> Make sure the version of nvme-cli is equal to or greater than version `1.12`.

We also provide a manifest that helps you finish the deployment on each worker node.
```
kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/master/deploy/prerequisite/longhorn-nvme-cli-installation.yaml
```

Or, you can manually install them.
- Install nvme-cli on each node and make sure that the version of `nvme-cli` is **equal to or greater than version `1.12`**.

  For SUSE/OpenSUSE you can install it use this command:
  ```
  zypper install nvme-cli
  ```

  For Debian and Ubuntu, use this command:
  ```
  zypper install nvme-cli
  ```

  For RHEL, CentOS, and EKS with `EKS Kubernetes Worker AMI with AmazonLinux2 image`, use this command:
  ```
  yum install nvme-cli
  ```

  To check the version of nvme-cli, execute the following command.
  ```
  nvme version
  ```

- Load `nvme-tcp` kernel module on the each worker node
  ```
  modprobe nvme-tcp
  ```

### Load Kernel Modules Automatically on Boot

Rather than manually loading kernel modules `uio`, `uio_pci_generic` and `nvme-tcp` each time after reboot, you can streamline the process by configuring automatic module loading during the boot sequence. For detailed instructions, please consult the manual provided by your operating system.

### Restart `kubelet`

After finishing the above steps, restart kubelet on each node.

### Check Environment

Make sure everything is correctly configured and installed by
```
bash -c "$(curl -sfL https://raw.githubusercontent.com/longhorn/longhorn/master/scripts/environment_check.sh)" -s -s
```

## Installation

### Install Longhorn System

Follow the steps in Quick Installation to install Longhorn system.

### Enable SPDK Data Engine

Enable the SPDK Data Engine by changing the `spdk` setting to `true` after installation. Following this, the instance-manager pods will be automatically restarted.

Or, you can enable it in `Setting > General > Enable SPDK Data Engine (Preview Feature)`. 

### Add `block-type` Disks in Worker Nodes

Unlike `filesystem-type` disks that are designed for legacy volumes, volumes using SPDK Data Engine are persistent on `block-type` disks. Therefore, it is necessary to equip worker nodes with `block-type` disks.

#### Prepare disks

If there are no additional disks available on the worker nodes, you can create loop block devices to test the feature. To accomplish this, execute the following command on each worker node to create a 10 GiB block device.
```
dd if=/dev/zero of=blockfile bs=1M count=102400
losetup -f blockfile
```

To display the path of the block device when running the command `losetup -f blockfile`, use the following command.
```
losetup -j blockfile
```

#### Add disks `node.longhorn.io`

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

After the installation and configuration, we can dyamically provision a Persistent Volume using SPDK Data Engine as the following steps.

### Create a StorageClass

Use following command to create a StorageClass called `longhorn-spdk`. Set `parameters.backendStoreDriver`  to `spdk` to utilize SPDK Data Engine.
```
kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/master/examples/spdk/storageclass.yaml
```

### Create Longhorn Volumes

Create a Pod that uses Longhorn volumes using SPDK Data Engine by running this command:
```
kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/master/examples/spdk/pod_with_pvc.yaml
```

Or, if you are creating a volume on Longhorn UI, please specify the `Backend Data Engine` as `SPDK`.