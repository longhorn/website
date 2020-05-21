---
title: Settings Reference
weight: 1
---

- [Customizing Default Settings](#customizing-default-settings)
- [General](#general)
  - [Backup Target](#backup-target)
  - [Backup Target Credential Secret](#backup-target-credential-secret)
  - [Backupstore Poll Interval](#backupstore-poll-interval)
  - [Create Default Disk on Labeled Nodes](#create-default-disk-on-labeled-nodes)
  - [Default Data Path](#default-data-path)
  - [Default Engine Image](#default-engine-image)
  - [Enable Upgrade Checker](#enable-upgrade-checker)
  - [Latest Longhorn Version](#latest-longhorn-version)
  - [Default Replica Count](#default-replica-count)
  - [Guaranteed Engine CPU (Experimental)](#guaranteed-engine-cpu-experimental)
  - [Default Longhorn Static StorageClass Name](#default-longhorn-static-storageclass-name)
  - [Custom mkfs.ext4 parameters](#custom-mkfsext4-parameters)
  - [Kubernetes Taint Toleration](#kubernetes-taint-toleration)
- [Scheduling](#scheduling)
  - [Replica Soft Anti-Affinity](#replica-soft-anti-affinity)
  - [Storage Over Provisioning Percentage](#storage-over-provisioning-percentage)
  - [Storage Minimal Available Percentage](#storage-minimal-available-percentage)

### Customizing Default Settings

To configure Longhorn before installing it, see [this section](../../advanced-resources/deploy/customizing-default-settings) for details.

### General

#### Backup Target
> Example: `s3://backupbucket@us-east-1/backupstore`

The target used for backup. NFS and S3 are supported. See [Setting a Backup Target](../../snapshots-and-backups/backup-and-restore/set-backup-target) for details.

#### Backup Target Credential Secret
> Example: `s3-secret`

The Kubernetes secret associated with the backup target. See [Setting a Backup Target](../../snapshots-and-backups/backup-and-restore/set-backup-target) for details.

#### Backupstore Poll Interval
> Example: `300`

The interval in seconds to poll the backup store for updating volumes' **Last Backup** field. Set to 0 to disable the polling. See [Setting up Disaster Recovery Volumes](../../snapshots-and-backups/setup-disaster-recovery-volumes) for details.

For more information on how the backupstore poll interval affects the recovery time objective and recovery point objective, refer to the [concepts section.](../../concepts/#backupstore-update-intervals-rto-and-rpo)

#### Create Default Disk on Labeled Nodes
> Example: `false`

If no other disks exist, create the default disk automatically, only on nodes with the Kubernetes label `node.longhorn.io/create-default-disk=true` .

If disabled, the default disk will be created on all new nodes when the node is detected for the first time.

This option is useful if you want to scale the cluster but don't want to use storage on the new nodes.

#### Default Data Path
> Example: `/var/lib/longhorn`

Default path to use for storing data on a host.

Can be used with `Create Default Disk on Labeled Nodes` option, to make Longhorn only use the nodes with specific storage mounted at, for example, `/opt/longhorn` when scaling the cluster.

#### Default Engine Image
> Example: `longhornio/longhorn-engine:v0.6.0`

The default engine image used by the manager. Can be changed on the manager starting command line only.

Every Longhorn release will ship with a new Longhorn engine image. If the current Longhorn volumes are not using the default engine, a green arrow will show up, indicate this volume needs to be upgraded to use the default engine.

#### Enable Upgrade Checker
> Example: `true`

Upgrade Checker will check for a new Longhorn version periodically. When there is a new version available, it will notify the user in the Longhorn UI.

#### Latest Longhorn Version
> Example: `v0.6.0`

The latest version of Longhorn available. Automatically updated by the Upgrade Checker.

Only available if `Upgrade Checker` is enabled.

#### Default Replica Count
> Example: `3`

The default number of replicas when creating the volume from Longhorn UI. For Kubernetes, update the `numberOfReplicas` in the StorageClass

The recommended way of choosing the default replica count is: if you have more than three nodes for storage, use 3; otherwise use 2. Using a single replica on a single node cluster is also OK, but the high availability functionality wouldn't be available. You can still take snapshots/backups of the volume.

#### Guaranteed Engine CPU (Experimental)
> Default: `0.25`

Longhorn uses CPU resources on the node to serve the Longhorn Volumes. The Guaranteed Engine CPU option will request Kubernetes to reserve a certain amount of CPU for Longhorn Instance Manager Pods, which contain the running processes. The value is how many CPUs should be reserved for each Engine/Replica Instance Manager Pod created by Longhorn. This will help maintain engine stability during high node workload.

This number only applies to the Engine/Replica Manager Pods created after the setting takes effect.

> **Warning:** This setting should be changed only when all the volumes on the nodes are detached. Changing the setting will result in all the Instance Manager Pods restarting, which will automatically detach all the attached volumes, and could cause a workload outage.

##### Recommendations for the Guaranteed Engine CPU Allocation

Since Longhorn exposes the Volume as a block device, it's critical to ensure the Longhorn Engine processes have enough CPU to satisfy the latency requirement of the Linux system.

The Guaranteed Engine CPU should be set to **no more than a quarter** of what the node's available CPU resources, since the allocation is applied to the two Instance Managers on the node (engine and replica), and the future upgraded Instance Managers (another two for engine and replica).

For example, if the setting value is 0.25 or 250m, that means you must have at least 0.25 * 8 = 2 vCPUs per node. Otherwise, the new Instance Manager Pods may fail to start.

There are normally two Instance Manager Pods per node: one for the engine processes, and another one for the replica processes. But when Longhorn is upgrading from an old version of the Instance Manager to a new version, there can be at most four Pods requesting the reserved CPU on the node.

Taking other Kubernetes system components' CPU reservation request into consideration, we recommend having at least eight times the amount of CPU as the Guaranteed Engine CPU.

#### Default Longhorn Static StorageClass Name
>Example: `longhorn-static`

The `storageClassName` is for persistent volumes (PVs) and persistent volume claims (PVCs) when creating PV/PVC for an existing Longhorn volume. Notice that it's unnecessary for users to create the related StorageClass object in Kubernetes since the StorageClass would only be used as matching labels for PVC bounding purpose. By default 'longhorn-static'.

#### Custom mkfs.ext4 parameters
>Example: `-O ^64bit,^metadata_csum`

This can be used to pass additional parameters for ext4 filesystem creation. For older Linux Distributions like [SLES12SP3](https://www.suse.com/releasenotes/x86_64/SUSE-SLES/12-SP3/#fate-325367) that don't support the ext4 optional metadata_csum or 64bit feature it is necessary to disable it by specifying: `-O ^64bit,^metadata_csum`

#### Kubernetes Taint Toleration
> Example: `nodetype=storage:NoSchedule`

By setting tolerations for Longhorn then adding taints for the nodes, the nodes with large storage can be dedicated to Longhorn only (to store replica data) and reject other general workloads.

Before modifying toleration setting, all Longhorn volumes should be detached then Longhorn components will be restarted to apply new tolerations. And toleration update will take a while. Users cannot operate Longhorn system during update. Hence it's recommended to set toleration during Longhorn deployment.

Multiple tolerations can be set here, and these tolerations are separated by semicolon. For example, `key1=value1:NoSchedule; key2:NoExecute`

See [Taint Toleration](../../advanced-resources/deploy/taint-toleration) for details.

### Scheduling
#### Replica Soft Anti-Affinity
> Example: `true`

Allow scheduling on nodes with existing healthy replicas of the same volume.

If the users want to avoid temporarily node down caused replica rebuild, they can set this option to `false`. The volume may be kept in `Degraded` state until another node that doesn't already have a replica scheduled comes online.

#### Storage Over Provisioning Percentage
> Example: `500`

The over-provisioning percentage defines how much storage can be allocated relative to the hard drive's capacity.

The users can set this to a lower value if they don't want overprovisioning storage. See [Multiple Disks Support](../../volumes-and-nodes/multidisk/#configuration) for details. Also, a replica of volume may take more space than the volume's size since the snapshots would need space to store as well. The users can delete snapshots to reclaim spaces.

#### Storage Minimal Available Percentage
> Example: `10`

If one disk's available capacity to it's maximum capacity in % is less than the minimal available percentage, the disk would become unschedulable until more space freed up.

See [Multiple Disks Support](../../volumes-and-nodes/multidisk/#configuration) for details.
