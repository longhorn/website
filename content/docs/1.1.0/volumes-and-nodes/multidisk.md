---
title: Multiple Disk Support
weight: 5
---

Longhorn supports using more than one disk on the nodes to store the volume data.

By default, `/var/lib/longhorn` on the host will be used for storing the volume data. You can avoid using the default directory by adding a new disk, then disable scheduling for `/var/lib/longhorn`.

## Add a Disk

To add a new disk for a node, head to the `Node` tab, select one of the nodes, and select `Edit Disks` in the dropdown menu.

To add any additional disks, you need to:
1. Mount the disk on the host to a certain directory.
2. Add the path of the mounted disk into the disk list of the node.

Longhorn will detect the storage information (e.g. maximum space, available space) about the disk automatically, and start scheduling to it if it's possible to accommodate the volume. A path mounted by the existing disk won't be allowed.

A certain amount of disk space can be reserved to stop Longhorn from using it. It can be set in the `Space Reserved` field for the disk. It's useful for the non-dedicated storage disk on the node. 

The kubelet needs to preserve node stability when available compute resources are low. This is especially important when dealing with incompressible compute resources, such as memory or disk space. If such resources are exhausted, nodes become unstable. To avoid kubelet `Disk pressure` issue after scheduling several volumes, by default, Longhorn reserved 30% of root disk space (`/var/lib/longhorn`) to ensure node stability.

### Use an Alternative Path for a Disk on the Node

If you don't want to use the original mount path of a disk on the node, you can use `mount --bind` to create an alternative/alias path for the disk, then use it with Longhorn. Notice that soft link `ln -s` won't work since it will not get populated correctly inside the pod.

Longhorn will identify the disk using the path, so the users need to make sure the alternative path are correctly mounted when the node reboots, e.g. by adding it to `fstab`.

## Remove a Disk
Nodes and disks can be excluded from future scheduling. Notice that any scheduled storage space won't be released automatically if the scheduling was disabled for the node.

In order to remove a disk, two conditions need to be met:
- The scheduling for the disk must be disabled
- There is no existing replica using the disk, including any replicas in an error state.

Once those two conditions are met, you should be allowed to remove the disk.

## Configuration
There are two global settings affect the scheduling of the volume.

- `StorageOverProvisioningPercentage` defines the upper bound of `ScheduledStorage / (MaximumStorage - ReservedStorage)`. The default value is `500` (%). That means we can schedule a total of 750 GiB Longhorn volumes on a 200 GiB disk with 50G reserved for the root file system. Because normally people won't use that large amount of data in the volume, and we store the volumes as sparse files.
- `StorageMinimalAvailablePercentage` defines when a disk cannot be scheduled with more volumes. The default value is `10` (%). The bigger value between `MaximumStorage * StorageMinimalAvailablePercentage / 100` and `MaximumStorage - ReservedStorage` will be used to determine if a disk is running low and cannot be scheduled with more volumes.

Notice that currently there is no guarantee that the space volumes use won't exceed the `StorageMinimalAvailablePercentage`, because:
1. Longhorn volumes can be bigger than the specified size, due to fact that the snapshot contains the old state of the volume.
2. Longhorn does over-provisioning by default.