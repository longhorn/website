---
title: Multiple Disk Support
weight: 4
---

Longhorn supports using more than one disk on the nodes to store the volume data.

By default, Longhorn stores volume data in the `/var/lib/longhorn` directory on the host. If you want to use a different disk for storage, you can add a new disk and disable scheduling for the default directory. This gives you flexibility to manage storage based on your needs.

## Add a Disk

Before adding a disk to Longhorn, you need to mount it to a directory on the host of the Longhorn node.

1. **Choose a Disk:** Select the physical or virtual disk you want to use for Longhorn storage and format it with an extent-based filesystem (e.g., ext4, xfs).
2. **Mount the Disk:** Mount the disk to a directory on the host, such as `/mnt/example-disk`. Ensure the directory is accessible and properly configured.

After the disk is mounted, you can add it to Longhorn using either the  UI or the `kubectl` command-line tool.

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

### Root Disk Reservation

Optionally, you can use the `Space Reserved` field in the UI or `spec.disks.<disk-name>.storageReserved` to reserve a portion of disk space (in bytes) for other purposes. This reserved space will not be used by Longhorn for volume data.

To maintain node stability when compute resources (for example memory or disk) are under pressure, the `kubelet` requires some space to remain free. If these critical resources are exhausted, it can lead to node instability.

Longhorn **reserves 30% of the root disk space (`/var/lib/longhorn`) by default** to prevent issues like `DiskPressure` conditions from the `kubelet`, particularly after scheduling multiple volumes. This behaviour is controlled by the `storage-reserved-percentage-for-default-disk` setting.

### Use an Alternative Path for a Disk on the Node

If you prefer to use a different path for a disk (rather than the original mount point), you can use `mount --bind` to create an alternative path. Do **not** use symbolic link (`lh -s`), as these are not properly resolved inside Longhorn pods.

Make sure the alternative path is remounted after a node reboot, for example, by adding it to `/etc/fstab`.

## Remove a Disk

Nodes and disks can be excluded from future scheduling. Note that any storage already scheduled on the node will not be automatically released when scheduling is disabled for the node.

To remove a disk:

- Disable scheduling for the disk.
- Ensure there are **no replicas or backing images** left on the disk, including any in an error state. For instructions on how to evict replicas from disabled disks, see [Select Disks or Nodes for Eviction](../disks-or-nodes-eviction/#select-disks-or-nodes-for-eviction).

Once the disk is empty and scheduling is disabled, you can safely remove it from the node configuration.

## Configuration

There are two global settings affect the scheduling of the volume.

- `StorageOverProvisioningPercentage` defines the maximum total storage that can be **scheduled** on a disk, relative to its usable capacity. The formula is:

    ```bash
    ScheduledStorage / (MaximumStorage - ReservedStorage)
    ```

    The default is `100` (%).

	On a 200 GiB disk with 50 GiB reserved, Longhorn sees 150 GiB of usable space. With the default setting, it can schedule up to 150 GiB of volume data.

    Since workloads typically don’t consume the entire allocated volume size, and Longhorn uses sparse files to store data, increasing this setting is generally safe and can help optimize disk utilization.

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
