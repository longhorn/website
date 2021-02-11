---
title: Best Practices
weight: 5
---

We recommend the following setup for deploying Longhorn in production.

- [Minimum Recommended Hardware](#minimum-recommended-hardware)
- [Software](#software)
- [Node and Disk Setup](#node-and-disk-setup)
- [Configuring Default Disks Before and After Installation](#configuring-default-disks-before-and-after-installation)
- [Deploying Workloads](#deploying-workloads)
- [Volume Maintenance](#volume-maintenance)
- [Guaranteed Instance Manager CPU](#guaranteed-instance-manager-cpu)
- [StorageClass](#storageclass)
- [Scheduling Settings](#scheduling-settings)

## Minimum Recommended Hardware

- 3 nodes
- 4 vCPUs per node
- 4 GiB per node
- SSD/NVMe or similar performance block device on the node for storage
    - We don't recommend using spinning disks with Longhorn, due to low IOPS.

## Software

It's recommended to run an OS from the following list for every node of your Kubernetes cluster:

1. Ubuntu 18.04
1. CentOS 7/8

### OSes aren't supported by Longhorn
1. RancherOS

## Node and Disk Setup

We recommend the following setup for nodes and disks.

### Use a Dedicated Disk

It's recommended to dedicate a disk for Longhorn storage for production, instead of using the root disk.

### Minimal Available Storage and Over-provisioning

If you need to use the root disk, use the default `minimal available storage percentage` setup which is 25%, and set `overprovisioning percentage` to 200% to minimize the chance of DiskPressure.

If you're using a dedicated disk for Longhorn, you can lower the setting `minimal available storage percentage` to 10%.

For the Over-provisioning percentage, it depends on how much space your volume uses on average. For example, if your workload only uses half of the available volume size, you can set the Over-provisioning percentage to `200`, which means Longhorn will consider the disk to have twice the schedulable size as its full size minus the reserved space.

### Disk Space Management

Since Longhorn doesn't currently support sharding between the different disks, we recommend using [LVM](https://en.wikipedia.org/wiki/Logical_Volume_Manager_(Linux)) to aggregate all the disks for Longhorn into a single partition, so it can be easily extended in the future.

### Setting up Extra Disks

Any extra disks must be written in the `/etc/fstab` file to allow automatic mounting after the machine reboots.

Don't use a symbolic link for the extra disks. Use `mount --bind` instead of `ln -s` and make sure it's in the `fstab` file. For details, see [the section about multiple disk support.](../volumes-and-nodes/multidisk/#use-an-alternative-path-for-a-disk-on-the-node)

## Configuring Default Disks Before and After Installation

To use a directory other than the default `/var/lib/longhorn` for storage, the `Default Data Path` setting can be changed before installing the system. For details on changing pre-installation settings, refer to [this section.](../advanced-resources/deploy/customizing-default-settings)

The [Default node/disk configuration](../advanced-resources/default-disk-and-node-config) feature can be used to customize the default disk after installation. Customizing the default configurations for disks and nodes is useful for scaling the cluster because it eliminates the need to configure Longhorn manually for each new node if the node contains more than one disk, or if the disk configuration is different for new nodes. Remember to enable `Create default disk only on labeled node` if applicable.

## Deploying Workloads

If you're using `ext4` as the filesystem of the volume, we recommend adding a liveness check to workloads to help automatically recover from a network-caused interruption, a node reboot, or a Docker restart. See [this section](../high-availability/recover-volume/) for details.

## Volume Maintenance

We highly recommend using the built-in backup feature of Longhorn.

For each volume, schedule at least one recurring backup. If you must run Longhorn in production without a backupstore, then schedule at least one recurring snapshot for each volume.

Longhorn system will create snapshots automatically when rebuilding a replica. Recurring snapshots or backups can also automatically clean up the system-generated snapshot.

## Guaranteed Instance Manager CPU

We recommend allowing Longhorn to have CPU requests set for engine/replica manager pods.

To be precise, you can set the percentage of a node total allocatable CPU reserved for all engine/replica manager pods by modifying settings `Guaranteed Engine Manager CPU` and `Guaranteed Replica Manager CPU`.

If you want to set a concrete value (milli CPU amount) for engine/replica manager pods on a specific node, you can update the fields `Engine Manager CPU Request` or  `Replica Manager CPU Request` of the node. Notice that these 2 fields will overwrite the above settings for the specific node.

The setting `Guarantee Engine CPU` is deprecated. For the system upgraded from old versions, Longhorn v1.1.1 will set the node fields mentioned above automatically to the same value as the deprecated setting then clean up the setting.

For details, refer to the settings references [`Guaranteed Engine Manager CPU`](../references/settings/#guaranteed-engine-manager-cpu) and [`Guaranteed Replica Manager CPU`](../references/settings/#guaranteed-replica-manager-cpu).

## StorageClass

We don't recommend modifying the default StorageClass named `longhorn`, since the change of parameters might cause issues during an upgrade later. If you want to change the parameters set in the StorageClass, you can create a new StorageClass by referring to the [StorageClass examples](../references/examples/#storageclass).

## Scheduling Settings

### Replica Node Level Soft Anti-Affinity
> Recommend: `false`

This setting should be set to `false` in production environment to ensure the best availability of the volume. Otherwise, one node down event may bring down more than one replicas of a volume.

### Allow Volume Creation with Degraded Availability
> Recommend: `false`

This setting should be set to `false` in production environment to ensure every volume have the best availability when created. Because with the setting set to `true`, the volume creation won't error out even there is only enough room to schedule one replica. So there is a risk that the cluster is running out of the spaces but the user won't be made aware immediately.
