---
title: Node Disk Support
weight: 20
aliases:
- /spdk/features/node-disk-support.md
---

Longhorn now supports the addition and management of various disk types (AIO, NVMe, and VirtIO) on nodes, enhancing filesystem operations, storage performance, and compatibility.

- Enhanced Storage Performance

  Utilizing NVMe and VirtIO disks allows for faster disk operations, significantly improving overall performance.

- Filesystem Compatibility

  Disks managed with NVMe or VirtIO drivers offer better filesystem support, including advanced operations like trimming.

- Flexibility

  Users can select the disk type that best fits their environment: AIO for traditional setups, NVMe for high-performance needs, or VirtIO for virtualized environments.

- Ease of Management

  Automatic detection of disk drivers simplifies the addition and management of disks, reducing administrative overhead.

## Configure a Disk on Longhorn Node

Longhorn can automatically detect the disk type if `node.spec.disks[i].diskDriver` is set to `auto`, optimizing storage performance. The detection and management will be as follows:

- NVMe Disk: managed by spdk_tgt using the nvme bdev driver, and `node.status.diskStatus[i].diskDriver` will be set to `nvme`.
- VirtIO Disk: managed by spdk_tgt using the virtio bdev driver, and `node.status.diskStatus[i].diskDriver` will be set to `virtio-blk`.
- Other Disks: managed by spdk_tgt using the aio bdev driver, and `node.status.diskStatus[i].diskDriver` will be set to `aio`.

Alternatively, users can manually set `node.spec.disks[i].diskDriver` to `aio` to force the use of the aio bdev driver.

To support NVMe and VirtIO disks, you need to find the BDF (Bus, Device, Function) of the disk as a disk path that will be added to the Longhorn node. The following examples provide an introduction to configuring NVMe disks, VirtIO disks, and others.

> **Note**
> 
> Once these disks are managed by the NVMe bdev driver or VirtIO bdev driver, instead of the Linux kernel driver, they will no be listed under /dev/nvmeXnY or /dev/vdbX.

### Using NVMe Disks

1. List the disks

   First, identify the NVMe disks available on your system by running the following command:

   ```
   # ls -al /sys/block/
   ```

   Example output:
   ```
   lrwxrwxrwx  1 root root 0  Jul  30 12:20 loop0 -> ../devices/virtual/block/loop0
   lrwxrwxrwx  1 root root 0  Jul  30 12:20 nvme0n1 -> ../devices/pci0000:00/0000:00:01.2/0000:02:00.0/nvme/nvme0/nvme0n1
   lrwxrwxrwx  1 root root 0  Jul  30 12:20 nvme0n1 -> ../devices/pci0000:00/0000:00:01.2/0000:05:00.0/nvme/nvme1/nvme1n1
   ```

1. Get the BDF of the NVMe disk

   Identify the BDF of the NVMe disk `/dev/nvme1n1`. From the example above, the BDF is `0000:05:00.0`.

1. Add the NVMe disk to `spec.disks` of `node.longhorn.io`

   ```
   nvme-disk:
     allowScheduling: true
     diskType: block
     diskDriver: auto
     evictionRequested: false
     path: 0000:05:00.0
     storageReserved: 0
     tags: []
   ```

1. Check the `status.diskStatus`. The disk should be detected without errors, and the diskDriver should be set to `nvme`.

> **Note: Alternative Disk Configuration**
> 
> If you add the disk using a different path, such as:
> 
>  ```
>  nvme-disk:
>    allowScheduling: true
>    diskType: block
>    diskDriver: auto
>    evictionRequested: false
>    path: /dev/nvme1n1
>    storageReserved: 0
>    tags: []
>  ```
> In this case, the disk will be managed by the aio bdev driver, and the `node.status.diskStatus[i].diskDriver` will be set to `aio`.

### Using VirtIO Disks

The steps are similar to NVMe disks.

1. List the disks

   First, identify the VirtIO disks available on your system by running the following command:

   ```
   # ls -al /sys/block/
   ```

   Example output:

   ```
   lrwxrwxrwx  1 root root 0  Jul  30 12:20 loop0 -> ../devices/virtual/block/loop0
   lrwxrwxrwx  1 root root 0 Feb 22 14:04 vda -> ../devices/pci0000:00/0000:00:02.3/0000:04:00.0/virtio2/block/vda
   lrwxrwxrwx  1 root root 0 Feb 22 14:24 vdb -> ../devices/pci0000:00/0000:00:02.6/0000:07:00.0/virtio5/block/vdb
   ```

1. Get the BDF of the VirtIO disk

   Identify the BDF of the VirtIO disk `/dev/vdb`. From the example above, the BDF is `0000:07:00.0`.

1. Add the NVMe disk to `spec.disks` of `node.longhorn.io`

   ```
   nvme-disk:
     allowScheduling: true
     diskType: block
     diskDriver: auto
     evictionRequested: false
     path: 0000:07:00.0
     storageReserved: 0
     tags: []
   ```

1. Check the `status.diskStatus`. The disk should be detected without errors, and the `diskDriver` should be set to `virtio-blk`.

> **Note: Alternative Disk Configuration**
> 
> If you add the disk using a different path, such as:
> 
>  ```
>  nvme-disk:
>    allowScheduling: true
>    diskType: block
>    diskDriver: auto
>    evictionRequested: false
>    path: /dev/vdb
>    storageReserved: 0
>    tags: []
>  ```
> In this case, the disk will be managed by the aio bdev driver, and the `node.status.diskStatus[i].diskDriver` will be set to `aio`.


### Using AIO Disks

When neither NVMe nor VirtIO drivers can manage a disk, Longhorn will default to using the aio bdev driver. Users can also manually configure this.

1. Add the disk to `spec.disks` of `node.longhorn.io`

    ```
    default-disk-loop:
      allowScheduling: true
      diskDriver: aio
      diskType: block
      evictionRequested: false
      path: /dev/loop12
      storageReserved: 0
      tags: []
    ```

1. Check node.status.diskStatus. The disk should be detected without errors, and the `node.status.diskStatus[i].diskDriver` will be set to aio.

## History

[Original Feature Request](https://github.com/longhorn/longhorn/issues/7672)
