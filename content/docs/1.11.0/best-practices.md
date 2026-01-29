---
title: Best Practices
weight: 4
---

We recommend the following setup for deploying Longhorn in production.

- [Minimum Recommended Hardware](#minimum-recommended-hardware)
- [Architecture](#architecture)
- [Operating System](#operating-system)
- [Kubernetes](#kubernetes)
  - [Kubernetes Version](#kubernetes-version)
  - [CoreDNS Setup](#coredns-setup)
- [Nodes and Disk Setup](#nodes-and-disk-setup)
  - [Use a Dedicated Disk](#use-a-dedicated-disk)
  - [Minimal Available Storage and Over-provisioning](#minimal-available-storage-and-over-provisioning)
  - [Disk Space Management](#disk-space-management)
  - [Setting up Extra Disks](#setting-up-extra-disks)
- [Configuring Default Disks Before and After Installation](#configuring-default-disks-before-and-after-installation)
- [Volumes Performance Optimization](#volumes-performance-optimization)
  - [IO Performance](#io-performance)
  - [Space Efficiency](#space-efficiency)
  - [Disaster Recovery](#disaster-recovery)
- [Deploying Workloads](#deploying-workloads)
- [Volumes Maintenance](#volumes-maintenance)
- [Guaranteed Instance Manager CPU](#guaranteed-instance-manager-cpu)
  - [V1 Data Engine](#v1-data-engine)
  - [V2 Data Engine](#v2-data-engine)
- [StorageClass](#storageclass)
- [Scheduling Settings](#scheduling-settings)
  - [Replica Node Level Soft Anti-Affinity](#replica-node-level-soft-anti-affinity)
  - [Allow Volumes Creation with Degraded Availability](#allow-volumes-creation-with-degraded-availability)
  - [Replica Auto-Balance](#replica-auto-balance)

## Minimum Recommended Hardware

- 3 nodes
- 4 vCPUs per node
- 4 GiB per node
- SSD/NVMe or similar performance block device on the node for storage (recommended)
- HDD/Spinning Disk or similar performance block device on the node for storage (verified)
  - 500/250 max IOPS per volume (1 MiB I/O)
  - 500/250 max throughput per volume (MiB/s)

> **Warning**: While Longhorn can function with HDDs (spinning disks) as storage, it is important to understand that **latency** plays a much more important role in volume stability than IOPS or throughput. This is because HDDs are mechanical, relying on spinning platters and moving read/write heads to access data. This physical movement introduces inherent delays (seek time and rotational delay), leading to much higher latency compared to the SSDs or NVMe drives, which utilize flash memory and have no moving parts. This can directly cause instability, especially when multiple input-output intensive tasks are running, such as:
>
> - Foreground IOs to the replicas
> - Foreground IOs from the replicas
> - Rebuilding volumes
> - Backups or other workloads
>
> The increased latency due to the use of HDDs, combined with other input-output workloads, can lead to **volume instability**. Therefore, we recommend **SSD or NVMe** drives for better performance and stability, especially for production workloads.
>
> The mentioned IOPS and throughput (500/250 max IOPS per volume and 500/250 max throughput per volume) are intended as general references based on the test setup but **should not be treated as hard requirements**. Latency, not just throughput, is the most important factor in ensuring system stability.

## Architecture

Longhorn supports the following architectures:

1. AMD64
1. ARM64

## Operating System

> **Note:** CentOS Linux has been removed from the verified OS list below, as it has been discontinued in favor of CentOS Stream [[ref](https://www.redhat.com/en/blog/faq-centos-stream-updates#Q5)], a rolling-release Linux distribution. Our focus for verifying RHEL-based downstream open source distributions will be enterprise-grade, such as Rocky and Oracle Linux.

The following Linux OS distributions and versions have been verified during the v{{< current-version >}} release testing. However, this does not imply that Longhorn exclusively supports these distributions. Essentially, Longhorn should function well on any certified Kubernetes cluster running on Linux nodes with a wide range of general-purpose operating systems, as well as verified container-optimized operating systems like SLE Micro.

| No. | OS                           | Versions
|-----|------------------------------| --------
| 1.  | Ubuntu                       | 24.04
| 2.  | SUSE Linux Enterprise Server | 16
| 3.  | SUSE Linux Enterprise Micro  | 6.1
| 4.  | Red Hat Enterprise Linux     | 10.1
| 5.  | Oracle Linux                 | 10.0
| 6.  | Rocky Linux                  | 10.1
| 7.  | Talos Linux                  | 1.11.5
| 8.  | Container-Optimized OS (GKE) | 121

Longhorn relies heavily on kernel functionality and performs better on some kernel versions. The following activities,
in particular, benefit from usage of specific kernel versions.

- Optimizing or improving the filesystem: Use a kernel with version `v5.8` or later. See [Issue
  #2507](https://github.com/longhorn/longhorn/issues/2507#issuecomment-857195496) for details.
- Enabling the [Freeze Filesystem for Snapshot](../references/settings#freeze-filesystem-for-snapshot) setting: Use a
  kernel with version `5.17` or later to ensure that a volume crash during a filesystem freeze cannot lock up a node.
- Enabling the [V2 Data Engine](../v2-data-engine/prerequisites): Use a kernel with version `5.19` or later to ensure


The list below contains known broken kernel versions that users should avoid using:

| No. | Version          | Distro          | Additional Context
|-----|------------------|-----------------| ------------------
| 1.  | 6.5.6            | Vanilla kernel  | Related to this bug https://longhorn.io/kb/troubleshooting-rwx-volume-fails-to-attached-caused-by-protocol-not-supported/
| 2.  | 5.15.0-94        | Ubuntu          | Related to this bug https://longhorn.io/kb/troubleshooting-rwx-volume-fails-to-attached-caused-by-protocol-not-supported/
| 3.  | 6.5.0-21         | Ubuntu          | Related to this bug https://longhorn.io/kb/troubleshooting-rwx-volume-fails-to-attached-caused-by-protocol-not-supported/
| 4.  | 6.5.0-1014-aws   | Ubuntu          | Related to this bug https://longhorn.io/kb/troubleshooting-rwx-volume-fails-to-attached-caused-by-protocol-not-supported/


## Kubernetes

### Kubernetes Version

Please ensure your Kubernetes cluster is at least v1.21 before upgrading to Longhorn v{{< current-version >}} because this is the minimum version Longhorn v{{< current-version >}} supports.

We recommend running your Kubernetes cluster on one of the following versions. These versions are the active supported versions prior to the Longhorn release, and have been tested with Longhorn v{{< current-version >}}.

| Release | Released     | End-of-life
|---------|--------------| -----------
| 1.35    | 17 Dec 2025  | 28 Feb 2027
| 1.34    | 27 Aug 2025  | 27 Oct 2026
| 1.33    | 23 Apr 2025  | 28 Jun 2026
| 1.32    | 11 Dec 2024  | 28 Feb 2026

Referenced to https://endoflife.date/kubernetes.

### CoreDNS Setup

Ensure that CoreDNS runs with at least 2 replicas to maintain high availability. This setup minimizes interruptions in the DNS resolution if one CoreDNS pod experiences a temporary disruption.

## Nodes and Disk Setup

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

## Volumes Performance Optimization

Before configuring workloads, ensure that you have set up the following basic requirements for optimal volume performance.

- SATA/NVMe SSDs or disk drives with similar performance
- 10 Gbps network bandwidth between nodes
- Dedicated Priority Class for system-managed and user-deployed Longhorn components. By default, Longhorn installs the default Priority Class `longhorn-critical`.

The following sections outline other recommendations for production environments.

### IO Performance

- **Storage network**: Use a [dedicated storage network](../advanced-resources/deploy/storage-network/#setting-storage-network) to improve IO performance and stability.

- **Longhorn disk**: Use a [dedicated disk](../nodes-and-volumes/nodes/multidisk/#add-a-disk) for Longhorn storage instead of using the root disk.

- **Replica count**: Set the [default replica count](../references/settings/#default-replica-count) to "2" to achieve data availability with better disk space usage or less impact to system performance. This practice is especially beneficial to data-intensive applications.

- **Storage tag**: Use [storage tags](../nodes-and-volumes/nodes/storage-tags) to define storage tiering for data-intensive applications. For example, only high-performance disks can be used for storing performance-sensitive data.

- **Data locality**: Use `best-effort` as the default [data locality](../high-availability/data-locality) of Longhorn StorageClasses.

  For applications that support data replication (for example, a distributed database), you can use the `strict-local` option to ensure that only one replica is created for each volume. This practice prevents the extra disk space usage and IO performance overhead associated with volume replication.

  For data-intensive applications, you can use pod scheduling functions such as node selector or taint toleration. These functions allow you to schedule the workload to a specific storage-tagged node together with one replica.

### Space Efficiency

- **Recurring snapshots**: Periodically clean up system-generated snapshots and retain only the number of snapshots that makes sense for your implementation.

  For applications with replication capability, periodically [delete all types of snapshots](../concepts/#243-deleting-snapshots).

- **Recurring filesystem trim**: Periodically [trim the filesystem](../nodes-and-volumes/volumes/trim-filesystem) inside volumes to reclaim disk space.

- **Snapshot space management**: [Configure global and volume-specific settings](../snapshots-and-backups/snapshot-space-management) to prevent unexpected disk space exhaustion.

### Disaster Recovery

- **Recurring backups**: Create [recurring backup jobs](../snapshots-and-backups/scheduling-backups-and-snapshots/) for mission-critical application volumes.

- **System backup**: Create periodic [system backups](../advanced-resources/system-backup-restore/backup-longhorn-system/#create-longhorn-system-backup).

## Deploying Workloads

If you're using `ext4` as the filesystem of the volume, we recommend adding a liveness check to workloads to help automatically recover from a network-caused interruption, a node reboot, or a Docker restart. See [this section](../high-availability/recover-volume) for details.

## Volumes Maintenance

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

### Allow Volumes Creation with Degraded Availability

> Recommend: `false`

This setting should be set to `false` in production environment to ensure every volume have the best availability when created. Because with the setting set to `true`, the volume creation won't error out even there is only enough room to schedule one replica. So there is a risk that the cluster is running out of the spaces but the user won't be made aware immediately.

### Replica Auto-Balance

> Recommend: `least-effort`

For production environments, we recommend setting Replica Auto-Balance to `least-effort`. This setting ensures that at least one replica is placed on a different node in each zone, providing extra high availability (HA).

In certain edge cases, you might consider using the `best-effort`, which continuously attempts to evenly distribute replicas across nodes and zones. However, this setting can lead to frequent rebuilds if the cluster is unstable.

For most users, having multiple replicas without Replica Auto-Balance setting is sufficient to achieve basic HA, especially if you prefer to avoid excessive rebuilds and resource usage.
