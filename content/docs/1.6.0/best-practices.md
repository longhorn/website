---
title: Best Practices
weight: 5
---

We recommend the following setup for deploying Longhorn in production.

- [Minimum Recommended Hardware](#minimum-recommended-hardware)
- [Architecture](#architecture)
- [Operating System](#operating-system)
- [Kubernetes Version](#kubernetes-version)
- [Node and Disk Setup](#node-and-disk-setup)
  - [Use a Dedicated Disk](#use-a-dedicated-disk)
  - [Minimal Available Storage and Over-provisioning](#minimal-available-storage-and-over-provisioning)
  - [Disk Space Management](#disk-space-management)
  - [Setting up Extra Disks](#setting-up-extra-disks)
- [Configuring Default Disks Before and After Installation](#configuring-default-disks-before-and-after-installation)
- [Volume Performance Optimization](#volume-performance-optimization)
  - [IO Performance](#io-performance)
  - [Space Efficiency](#space-efficiency)
  - [Disaster Recovery](#disaster-recovery)
- [Deploying Workloads](#deploying-workloads)
- [Volume Maintenance](#volume-maintenance)
- [Guaranteed Instance Manager CPU](#guaranteed-instance-manager-cpu)
  - [V1 Data Engine](#v1-data-engine)
  - [V2 Data Engine](#v2-data-engine)
- [StorageClass](#storageclass)
- [Scheduling Settings](#scheduling-settings)
  - [Replica Node Level Soft Anti-Affinity](#replica-node-level-soft-anti-affinity)
  - [Allow Volume Creation with Degraded Availability](#allow-volume-creation-with-degraded-availability)

## Minimum Recommended Hardware

- 3 nodes
- 4 vCPUs per node
- 4 GiB per node
- SSD/NVMe or similar performance block device on the node for storage (recommended)
- HDD/Spinning Disk or similar performance block device on the node for storage (verified)
  - 500/250 max IOPS per volume (1 MiB I/O)
  - 500/250 max throughput per volume (MiB/s)

## Architecture

Longhorn supports the following architectures:

1. AMD64
1. ARM64
1. s390x (experimental)

## Operating System

> **Note:** CentOS Linux has been removed from the verified OS list below, as it has been discontinued in favor of CentOS Stream [[ref](https://www.redhat.com/en/blog/faq-centos-stream-updates#Q5)], a rolling-release Linux distribution. Our focus for verifying RHEL-based downstream open source distributions will be enterprise-grade, such as Rocky and Oracle Linux.

The following Linux OS distributions and versions have been verified during the v{{< current-version >}} release testing. However, this does not imply that Longhorn exclusively supports these distributions. Essentially, Longhorn should function well on any certified Kubernetes cluster running on Linux nodes with a wide range of general-purpose operating systems, as well as verified container-optimized operating systems like SLE Micro.

| No. | OS           | Versions
|-----|--------------| --------
| 1.  | Ubuntu       | 22.04
| 2.  | SLES         | 15 SP5
| 3.  | SLE Micro    | 5.5
| 4.  | RHEL         | 9.3
| 5.  | Oracle Linux | 9.3
| 6.  | Rocky Linux  | 9.3
| 7.  | Talos Linux  | 1.6.1

Note: It's recommended to guarantee that the kernel version is at least 5.8 as there is filesystem optimization/improvement since this version. See [this issue](https://github.com/longhorn/longhorn/issues/2507#issuecomment-857195496) for details.

## Kubernetes Version

We recommend running your Kubernetes cluster on one of the following versions. These versions are the active supported versions prior to the Longhorn release, and have been tested with Longhorn v{{< current-version >}}.

| Release | Released     | End-of-life
|---------|--------------| -----------
| 1.28    | 15 Aug 2023  | 28 Oct 2024
| 1.27    | 11 Apr 2023  | 28 Jun 2024
| 1.26    | 08 Dec 2022  | 28 Feb 2024

Referenced to https://endoflife.date/kubernetes.

## Node and Disk Setup

We recommend the following setup for nodes and disks.

### Use a Dedicated Disk

It's recommended to dedicate a disk for Longhorn storage for production, instead of using the root disk.

### Minimal Available Storage and Over-provisioning

If you need to use the root disk, use the default `minimal available storage percentage` setup which is 25%, and set `overprovisioning percentage` to 100% to minimize the chance of DiskPressure.

If you're using a dedicated disk for Longhorn, you can lower the setting `minimal available storage percentage` to 10%.

For the Over-provisioning percentage, it depends on how much space your volume uses on average. For example, if your workload only uses half of the available volume size, you can set the Over-provisioning percentage to `200`, which means Longhorn will consider the disk to have twice the schedulable size as its full size minus the reserved space.

### Disk Space Management

Since Longhorn doesn't currently support sharding between the different disks, we recommend using [LVM](https://en.wikipedia.org/wiki/Logical_Volume_Manager_(Linux)) to aggregate all the disks for Longhorn into a single partition, so it can be easily extended in the future.

### Setting up Extra Disks

Any extra disks must be written in the `/etc/fstab` file to allow automatic mounting after the machine reboots.

Don't use a symbolic link for the extra disks. Use `mount --bind` instead of `ln -s` and make sure it's in the `fstab` file. For details, see [the section about multiple disk support.](../nodes-and-volumes/nodes/multidisk/#use-an-alternative-path-for-a-disk-on-the-node)

## Configuring Default Disks Before and After Installation

To use a directory other than the default `/var/lib/longhorn` for storage, the `Default Data Path` setting can be changed before installing the system. For details on changing pre-installation settings, refer to [this section.](../advanced-resources/deploy/customizing-default-settings)

The [Default node/disk configuration](../nodes-and-volumes/nodes/default-disk-and-node-config) feature can be used to customize the default disk after installation. Customizing the default configurations for disks and nodes is useful for scaling the cluster because it eliminates the need to configure Longhorn manually for each new node if the node contains more than one disk, or if the disk configuration is different for new nodes. Remember to enable `Create default disk only on labeled node` if applicable.

## Volume Performance Optimization  

Before configuring workloads, ensure that you have set up the following basic requirements for optimal volume performance.  

- SATA/NVMe SSDs or disk drives with similar performance  
- 10 Gbps network bandwidth between nodes  
- Dedicated Priority Class for system-managed and user-deployed Longhorn components. By default, Longhorn installs the default Priority Class `longhorn-critical`.  

The following sections outline other recommendations for production environments.  

### IO Performance  

- **Storage network**: Use a [dedicated storage network](https://longhorn.io/docs/1.6.0/advanced-resources/deploy/storage-network/#setting-storage-network) to improve IO performance and stability.  

- **Longhorn disk**: Use a [dedicated disk](https://longhorn.io/docs/1.6.0/nodes-and-volumes/multidisk/#add-a-disk) for Longhorn storage instead of using the root disk.  

- **Replica count**: Set the [default replica count](https://longhorn.io/docs/1.6.0/references/settings/#default-replica-count) to "2" to achieve data availability with better disk space usage or less impact to system performance. This practice is especially beneficial to data-intensive applications.  

- **Storage tag**: Use [storage tags](https://longhorn.io/docs/1.6.0/nodes-and-volumes/storage-tags/) to define storage tiering for data-intensive applications. For example, only high-performance disks can be used for storing performance-sensitive data.  

- **Data locality**: Use `best-effort` as the default [data locality](https://longhorn.io/docs/1.6.0/high-availability/data-locality/) of Longhorn StorageClasses.  

  For applications that support data replication (for example, a distributed database), you can use the `strict-local` option to ensure that only one replica is created for each volume. This practice prevents the extra disk space usage and IO performance overhead associated with volume replication.  

  For data-intensive applications, you can use pod scheduling functions such as node selector or taint toleration. These functions allow you to schedule the workload to a specific storage-tagged node together with one replica.  

### Space Efficiency  

- **Recurring snapshots**: Periodically clean up system-generated snapshots and retain only the number of snapshots that makes sense for your implementation.  

  For applications with replication capability, periodically [delete all types of snapshots](https://longhorn.io/docs/1.6.0/concepts/#243-deleting-snapshots).  

- **Recurring filesystem trim**: Periodically [trim the filesystem](https://longhorn.io/docs/1.6.0/nodes-and-volumes/trim-filesystem/) inside volumes to reclaim disk space.  

- **Snapshot space management**: [Configure global and volume-specific settings](https://longhorn.io/docs/1.6.0/advanced-resources/snapshot-space-management/) to prevent unexpected disk space exhaustion.

### Disaster Recovery

- **Recurring backups**: Create [recurring backup jobs](https://longhorn.io/docs/1.6.0/nodes-and-volumes/trim-filesystem/) for mission-critical application volumes.  

- **System backup**: Create periodic [system backups](https://longhorn.io/docs/1.6.0/advanced-resources/system-backup-restore/backup-longhorn-system/#create-longhorn-system-backup).  

## Deploying Workloads

If you're using `ext4` as the filesystem of the volume, we recommend adding a liveness check to workloads to help automatically recover from a network-caused interruption, a node reboot, or a Docker restart. See [this section](../high-availability/recover-volume/) for details.

## Volume Maintenance

Using Longhorn's built-in backup feature is highly recommended. You can save backups to an object store such as S3 or to an NFS server. Saving to an object store is preferable because it generally offers better reliability.  Another advantage is that you do not need to mount and unmount the target, which can complicate failover and upgrades.

For each volume, schedule at least one recurring backup. If you must run Longhorn in production without a backupstore, then schedule at least one recurring snapshot for each volume.

Longhorn system will create snapshots automatically when rebuilding a replica. Recurring snapshots or backups can also automatically clean up the system-generated snapshot.

## Guaranteed Instance Manager CPU

We recommend setting the CPU request for Longhorn instance manager pods.

### V1 Data Engine

The `Guaranteed Instance Manager CPU` setting allows you to reserve a percentage of the total allocatable CPU resources on each node for each instance manager pod when the V1 Data Engine is enabled. The default value is 12.

You can also set a specific milli CPU value for instance manager pods on a particular node by updating the node's `Instance Manager CPU Request` field.

> **Note:** This field will overwrite the above setting for the specified node.

Refer to [Guaranteed Instance Manager CPU](../references/settings/#guaranteed-instance-manager-cpu) for more details.

### V2 Data Engine

The `Guaranteed Instance Manager CPU for V2 Data Engine` setting allows you to reserve a specific number of millicpus on each node for each instance manager pod when the V2 Data Engine is enabled. By default, the Storage Performance Development Kit (SPDK) target daemon within each instance manager pod uses 1 CPU core. Configuring a minimum CPU usage value is essential for maintaining engine and replica stability, especially during periods of high node workload. The default value is 1250.

## StorageClass

We don't recommend modifying the default StorageClass named `longhorn`, since the change of parameters might cause issues during an upgrade later. If you want to change the parameters set in the StorageClass, you can create a new StorageClass by referring to the [StorageClass examples](../references/examples/#storageclass).

## Scheduling Settings

### Replica Node Level Soft Anti-Affinity

> Recommend: `false`

This setting should be set to `false` in production environment to ensure the best availability of the volume. Otherwise, one node down event may bring down more than one replicas of a volume.

### Allow Volume Creation with Degraded Availability

> Recommend: `false`

This setting should be set to `false` in production environment to ensure every volume have the best availability when created. Because with the setting set to `true`, the volume creation won't error out even there is only enough room to schedule one replica. So there is a risk that the cluster is running out of the spaces but the user won't be made aware immediately.
