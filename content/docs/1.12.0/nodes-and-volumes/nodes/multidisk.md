---
title: Multiple Disk Support
weight: 4
aliases:
- /docs/1.12.0/v2-data-engine/features/node-disk-support/
- /spdk/features/node-disk-support.md
---

- [Disk Types](#disk-types)
- [Default Disk Behavior](#default-disk-behavior)
- [Add a Disk](#add-a-disk)
  - [Add a Filesystem-Type Disk](#add-a-filesystem-type-disk)
    - [Use an Alternative Path for a Filesystem-Type Disk on the Node](#use-an-alternative-path-for-a-filesystem-type-disk-on-the-node)
  - [Add a Block-Type Disk](#add-a-block-type-disk)
    - [Prerequisites](#prerequisites)
    - [Steps](#steps)
    - [Disk Driver](#disk-driver)
      - [Using AIO Disks](#using-aio-disks)
      - [Using NVMe Disks](#using-nvme-disks)
      - [Using VirtIO Disks](#using-virtio-disks)
  - [Root Disk Reservation](#root-disk-reservation)
- [Remove a Disk](#remove-a-disk)
- [Disk Scheduling Configuration](#disk-scheduling-configuration)

## Disk Types

Longhorn supports two types of disks:

- **Filesystem-type disk (`diskType: filesystem`):** Used by the **V1 Data Engine**. The disk must be formatted with an extent-based filesystem (for example, ext4 or xfs) and mounted to a directory on the host.
- **Block-type disk (`diskType: block`):** Used by the **V2 Data Engine**. The disk is used as a raw block device without a filesystem.

Each disk type is tied to its corresponding data engine:

- V1 volumes are scheduled only to filesystem-type disks.
- V2 volumes are scheduled only to block-type disks.

## Default Disk Behavior

When a node is first added to Longhorn, the system creates a default **filesystem-type disk** at `/var/lib/longhorn`. This default disk is used for V1 volumes unless you disable scheduling for it or add other filesystem-type disks.

## Add a Disk

### Add a Filesystem-Type Disk

Filesystem-type disks are used for V1 volumes. Before adding one to Longhorn, you must prepare and mount it on the host.

1. **Choose a Disk:** Select the physical or virtual disk you want to use for Longhorn storage and format it with an extent-based filesystem (e.g., ext4, xfs).
2. **Mount the Disk:** Mount the disk to a directory on the host, such as `/mnt/example-disk`. Ensure the directory is accessible and properly configured.

After the disk is mounted, you can add it to Longhorn using either the UI or the `kubectl` command-line tool.

- **Using the Longhorn UI**

  1. Go to the **Nodes** tab, select a node, and choose **Edit Disks** from the dropdown menu.
  2. Add the mount path of the disk to the disk list.

- **Using `kubectl` Command**

  1. Run `kubectl edit node.longhorn.io <node-name>` to edit the Longhorn node resource.
  2. Add the disk path to `spec.disks`. For example:

    ```yaml
    ...
    spec:
      ...
      disks:
        ...
        example-disk:
          allowScheduling: true
          diskDriver: ""
          diskType: filesystem
          evictionRequested: false
          path: /mnt/example-disk
          storageReserved: 0
          tags: []
    ...
    ```

  3. Save and exit the editor.

Once a disk is added:

- Longhorn automatically detects the storage details of the disk, such as maximum and available capacity.
- If the disk is suitable for storing volume data, Longhorn begins scheduling volumes to it.

> **Notice**:
>
> 1. You cannot add a disk path that is already in use by another Longhorn disk.
> 2. Longhorn uses the filesystem ID to detect duplicate mounts. Therefore, you cannot add a disk with the **same filesystem ID** as another disk on the same node.  
>    See: [Issue #2477](https://github.com/longhorn/longhorn/issues/2477)

#### Use an Alternative Path for a Filesystem-Type Disk on the Node

If you prefer to use a different path for a filesystem-type disk (rather than the original mount point), you can use `mount --bind` to create an alternative path. Do **not** use symbolic link (`lh -s`), as these are not properly resolved inside Longhorn pods.

Make sure the alternative path is remounted after a node reboot, for example, by adding it to `/etc/fstab`.

### Add a Block-Type Disk

Block-type disks are used for V2 volumes. The V2 Data Engine requires raw block devices for direct access.

Longhorn supports several ways to manage block-type disks on a node:

- **NVMe disks:** Managed with the `nvme` driver.
- **VirtIO disks:** Managed with the `virtio-blk` driver.
- **Other block devices:** Managed with the `aio` driver.

#### Prerequisites

- The V2 Data Engine must be enabled. See [V2 Data Engine Quick Start](../../v2-data-engine/quick-start) for details.
- The disk must not contain any existing filesystem. Use `wipefs -a /path/to/block/device` to clean the disk before adding it.

#### Steps

You can add a block-type disk using the Longhorn UI or `kubectl`.

- **Using the Longhorn UI**

  1. Go to the **Nodes** tab, select a node, and choose **Edit Disks** from the dropdown menu.
  2. Add the block device path and set the disk type to **Block**.

- **Using `kubectl` Command**

  1. Run `kubectl edit node.longhorn.io <node-name>` to edit the Longhorn node resource.
  2. Add the block disk to `spec.disks`. For example:

    ```yaml
    ...
    spec:
      ...
      disks:
        ...
        block-disk:
          allowScheduling: true
          diskDriver: auto
          diskType: block
          evictionRequested: false
          path: /dev/sdb
          storageReserved: 0
          tags: []
    ...
    ```

  1. Save and exit the editor.

#### Disk Driver

The `diskDriver` field controls how Longhorn accesses the block device. Setting it to `auto` allows Longhorn to detect the appropriate driver automatically:

- **NVMe disks:** Uses the `nvme` driver. The `path` can be a BDF (Bus Device Function) notation (e.g., `0000:05:00.0`).
- **VirtIO disks:** Uses the `virtio-blk` driver. The `path` can also be a BDF notation.
- **Other disks:** Falls back to the `aio` (Linux AIO) driver. The `path` should be a standard device path (e.g., `/dev/sdb`).

After the disk is added, check `node.status.diskStatus` to confirm that Longhorn detected the disk without errors and assigned the expected `diskDriver`.

> **Note**
>
> When a disk is managed by the `nvme` or `virtio-blk` driver, it is no longer exposed through the original Linux kernel device node such as `/dev/nvmeXnY` or `/dev/vdX`.

##### Using AIO Disks

When a block device is neither NVMe nor VirtIO, or when you want to force Linux AIO, configure it with `diskDriver: aio` and use a standard device path.

```yaml
aio-disk:
  allowScheduling: true
  diskDriver: aio
  diskType: block
  evictionRequested: false
  path: /dev/sdb
  storageReserved: 0
  tags: []
```

> **Notice**:
>
> 1. Block-type disks are exclusively used by the V2 Data Engine and cannot be used for V1 volumes.
> 2. The disk must be clean (no existing filesystem) before adding it. Use `wipefs -a /path/to/block/device` to wipe it.
> 3. For disk-specific configuration examples, see [Using NVMe Disks](#using-nvme-disks), [Using VirtIO Disks](#using-virtio-disks), and [Using AIO Disks](#using-aio-disks).

##### Using NVMe Disks

To let Longhorn use the `nvme` driver, add the disk by its BDF instead of the Linux device path.

1. Identify the available disks on the node. For example:

    ```bash
    ls -al /sys/block/
    ```

    Example output:

    ```bash
    lrwxrwxrwx  1 root root 0 Jul 30 12:20 loop0 -> ../devices/virtual/block/loop0
    lrwxrwxrwx  1 root root 0 Jul 30 12:20 nvme0n1 -> ../devices/pci0000:00/0000:00:01.2/0000:02:00.0/nvme/nvme0/nvme0n1
    lrwxrwxrwx  1 root root 0 Jul 30 12:20 nvme1n1 -> ../devices/pci0000:00/0000:00:01.2/0000:05:00.0/nvme/nvme1/nvme1n1
    ```

2. Find the BDF of the target NVMe disk. In the example above, the BDF of `/dev/nvme1n1` is `0000:05:00.0`.

3. Add the disk to `spec.disks`. For example:

    ```yaml
    nvme-disk:
      allowScheduling: true
      diskType: block
      diskDriver: auto
      evictionRequested: false
      path: 0000:05:00.0
      storageReserved: 0
      tags: []
    ```

If you instead add the same disk using `/dev/nvme1n1`, Longhorn treats it as an `aio` disk instead of an `nvme` disk.

##### Using VirtIO Disks

VirtIO disks follow the same pattern. To let Longhorn use the `virtio-blk` driver, add the disk by its BDF.

1. Identify the available disks on the node. For example:

    ```bash
    ls -al /sys/block/
    ```

    Example output:

    ```bash
    lrwxrwxrwx  1 root root 0 Feb 22 14:04 vda -> ../devices/pci0000:00/0000:00:02.3/0000:04:00.0/virtio2/block/vda
    lrwxrwxrwx  1 root root 0 Feb 22 14:24 vdb -> ../devices/pci0000:00/0000:00:02.6/0000:07:00.0/virtio5/block/vdb
    ```

2. Find the BDF of the target VirtIO disk. In the example above, the BDF of `/dev/vdb` is `0000:07:00.0`.

3. Add the disk to `spec.disks`. For example:

    ```yaml
    virtio-disk:
      allowScheduling: true
      diskType: block
      diskDriver: auto
      evictionRequested: false
      path: 0000:07:00.0
      storageReserved: 0
      tags: []
    ```

If you instead add the same disk using `/dev/vdb`, Longhorn treats it as an `aio` disk instead of a `virtio-blk` disk.

### Root Disk Reservation

You can use the `Space Reserved` field in the UI or `spec.disks.<disk-name>.storageReserved` to reserve a portion of any disk's space (in bytes) for other purposes. This reserved space will not be used by Longhorn for volume data.

To maintain node stability when compute resources (for example memory or disk) are under pressure, the `kubelet` requires some space to remain free. If these critical resources are exhausted, it can lead to node instability.

For the default filesystem-type disk at `/var/lib/longhorn`, Longhorn **reserves 30% of the root disk space by default** to help prevent issues such as `DiskPressure` conditions from the `kubelet`, particularly after scheduling multiple volumes. This behavior is controlled by the `storage-reserved-percentage-for-default-disk` setting.

This automatic reservation applies only to the default filesystem-type disk created for V1 volumes. Block-type disks for V2 volumes must be configured explicitly, including any `storageReserved` value that you want to apply.

## Remove a Disk

Nodes and disks can be excluded from future scheduling. Note that any storage already scheduled on the node will not be automatically released when scheduling is disabled for the node.

To remove a disk:

- Disable scheduling for the disk.
- Ensure there are **no replicas or backing images** left on the disk, including any in an error state. For instructions on how to evict replicas from disabled disks, see [Select Disks or Nodes for Eviction](../disks-or-nodes-eviction/#select-disks-or-nodes-for-eviction).

Once the disk is empty and scheduling is disabled, you can safely remove it from the node configuration.

## Disk Scheduling Configuration

There are two global settings that affect disk scheduling.

These settings apply to both filesystem-type and block-type disks. However, the V1 Data Engine uses sparse files for thin provisioning, so over-provisioning behavior is commonly discussed in the context of filesystem-type disks.

- `StorageOverProvisioningPercentage` defines the maximum total storage that can be **scheduled** on a disk, relative to its usable capacity. The formula is:

    ```bash
    ScheduledStorage / (MaximumStorage - ReservedStorage)
    ```

    The default is `100` (%).

    On a 200 GiB disk with 50 GiB reserved, Longhorn sees 150 GiB of usable space. With the default setting, it can schedule up to 150 GiB of volume data.

    Since workloads typically do not consume the entire allocated volume size, increasing this setting can help optimize disk utilization. For V1 volumes, higher values are commonly used because the V1 Data Engine uses sparse files for thin provisioning.

- `StorageMinimalAvailablePercentage` specifies the minimum percentage of free space that must remain on a disk in order to schedule new replicas. The formula is:

    ```bash
    AvailableStorage / MaximumStorage
    ```

    The default is `25` (%).

    For a 200 GiB disk with 50 GiB reserved, Longhorn will stop scheduling new replicas if available space falls below 37.5 GiB  (25% of 150 GiB). A new volume also will not be scheduled if its size would push available space below that limit.

    This setting helps prevent disks from becoming too full, which could lead to scheduling failures or volume operation issues.

> **Warning**:
>
> Currently, Longhorn cannot fully enforce the `StorageMinimalAvailablePercentage` limit in all scenarios because:
>
> - Longhorn volumes may use more space than their requested size, especially when snapshots are taken.
> - Longhorn allows over-provisioning by default.
