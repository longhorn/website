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

For more information on how the backupstore poll interval affects the recovery time objective and recovery point objective, refer to the [concepts section.](../../concepts/#34-backupstore-update-intervals-rto-and-rpo)

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
> Example: `0.2`

Allow Longhorn Engine to have guaranteed CPU allocation. The value is how many CPUs should be reserved for each Engine/Replica Manager Pod created by Longhorn. For example, 0.1 means one-tenth of a CPU. This will help maintain engine stability during high node workload. It only applies to the Instance Manager Pods created after the setting took effect.

> **Warning:** The system may fail to start or become stuck while using this feature due to the resource constraint. Disabled (\"0\") by default.

Please set to **no more than a quarter** of what the node's available CPU resources, since the option would be applied to the two instance managers on the node (engine and replica), and the future upgraded instance managers (another two for engine and replica).

#### Default Longhorn Static StorageClass Name
>Example: `longhorn-static`

The `storageClassName` is for persistent volumes (PVs) and persistent volume claims (PVCs) when creating PV/PVC for an existing Longhorn volume. Notice that it's unnecessary for users to create the related StorageClass object in Kubernetes since the StorageClass would only be used as matching labels for PVC bounding purpose. By default 'longhorn-static'.

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