---
title: Settings Reference
weight: 1
---

- [Customizing Default Settings](#customizing-default-settings)

- [General](#general)
  - [Create Default Disk on Labeled Nodes](#create-default-disk-on-labeled-nodes)
  - [Default Data Path](#default-data-path)
  - [Default Engine Image](#default-engine-image)
  - [Default Instance Manager Image](#default-instance-manager-image)
  - [Enable Upgrade Checker](#enable-upgrade-checker)
  - [Latest Longhorn Version](#latest-longhorn-version)
  - [Default Replica Count](#default-replica-count)
  - [Default Longhorn Static StorageClass Name](#default-longhorn-static-storageclass-name)
  - [Custom Resource API Version](#custom-resource-api-version)
  - [Automatic Salvage](#automatic-salvage)
  - [Registry Secret](#registry-secret)
  - [Volume Attachment Recovery Policy](#volume-attachment-recovery-policy)
  - [Custom mkfs.ext4 parameters](#custom-mkfsext4-parameters)

- [Backups](#backups)
  - [Backup Target](#backup-target)
  - [Backup Target Credential Secret](#backup-target-credential-secret)
  - [Backupstore Poll Interval](#backupstore-poll-interval)

- [Scheduling](#scheduling)
  - [Replica Node Level Soft Anti-Affinity](#replica-node-level-soft-anti-affinity)
  - [Storage Over Provisioning Percentage](#storage-over-provisioning-percentage)
  - [Storage Minimal Available Percentage](#storage-minimal-available-percentage)
  - [Disable Scheduling On Cordoned Node](#disable-scheduling-on-cordoned-node)
  - [Replica Zone Level Soft Anti-Affinity](#replica-zone-level-soft-anti-affinity)

- [Danger Zone](#danger-zone)
  - [Kubernetes Taint Toleration](#kubernetes-taint-toleration)
  - [Guaranteed Engine CPU](#guaranteed-engine-cpu)

### Customizing Default Settings

To configure Longhorn before installing it, see [this section](../../advanced-resources/deploy/customizing-default-settings) for details.

### General

#### Create Default Disk on Labeled Nodes
> Default: `false`

If no other disks exist, create the default disk automatically, only on nodes with the Kubernetes label `node.longhorn.io/create-default-disk=true` .

If disabled, the default disk will be created on all new nodes when the node is detected for the first time.

This option is useful if you want to scale the cluster but don't want to use storage on the new nodes, or if you want to [customize disks for Longhorn nodes](../../advanced-resources/default-disk-and-node-config). 

#### Default Data Path
> Default: `/var/lib/longhorn/`

Default path to use for storing data on a host.

Can be used with `Create Default Disk on Labeled Nodes` option, to make Longhorn only use the nodes with specific storage mounted at, for example, `/opt/longhorn` when scaling the cluster.

#### Default Engine Image
> Default: `longhornio/longhorn-engine:v1.0.0` for Longhorn v1.0.0

The default engine image used by the manager. Can be changed on the manager starting command line only.

Every Longhorn release will ship with a new Longhorn engine image. If the current Longhorn volumes are not using the default engine, a green arrow will show up, indicate this volume needs to be upgraded to use the default engine.

#### Default Instance Manager Image
> Default: `longhornio/longhorn-instance-manager:v1_20200514` for Longhorn v1.0.0

The default instance manager image used by the manager. Can be changed on the manager starting command line only.

#### Enable Upgrade Checker
> Default: `true`

Upgrade Checker will check for a new Longhorn version periodically. When there is a new version available, it will notify the user in the Longhorn UI.

#### Latest Longhorn Version
> Default: `v1.0.0` for Longhorn v1.0.0

The latest version of Longhorn available. Automatically updated by the Upgrade Checker.

Only available if `Upgrade Checker` is enabled.

#### Default Replica Count
> Default: `3`

The default number of replicas when creating the volume from Longhorn UI. For Kubernetes, update the `numberOfReplicas` in the StorageClass

The recommended way of choosing the default replica count is: if you have more than three nodes for storage, use 3; otherwise use 2. Using a single replica on a single node cluster is also OK, but the high availability functionality wouldn't be available. You can still take snapshots/backups of the volume.

#### Default Longhorn Static StorageClass Name
> Default: `longhorn-static`

The `storageClassName` is for persistent volumes (PVs) and persistent volume claims (PVCs) when creating PV/PVC for an existing Longhorn volume. Notice that it's unnecessary for users to create the related StorageClass object in Kubernetes since the StorageClass would only be used as matching labels for PVC bounding purpose. By default 'longhorn-static'.

#### Custom Resource API Version
> Default: `longhorn.io/v1beta1`

The current customer resource's API version, e.g. longhorn.io/v1beta1. Set by manager automatically.

#### Automatic Salvage
> Default: `true`

If enabled, volumes will be automatically salvaged when all the replicas become faulty e.g. due to network disconnection. Longhorn will try to figure out which replica(s) are usable, then use them for the volume.

#### Registry Secret

The Kubernetes Secret name.

#### Volume Attachment Recovery Policy
> Default: `wait`

Defines the Longhorn action when a Volume is stuck with a Deployment Pod on a failed node.

- `wait`: Longhorn will wait to recover the Volume Attachment until all the terminating pods have passed their deletion grace period.
- `never`: The default Kubernetes behavior of never deleting volume attachments on terminating pods. Longhorn will not recover the Volume Attachment from a failed node.
- `immediate`: Longhorn will recover the Volume Attachment from the failed node as soon as there are pending replacement pods available.

#### Custom mkfs.ext4 parameters

Allows setting additional filesystem creation parameters for ext4. For older host kernels it might be necessary to disable the optional ext4 metadata_csum feature by specifying `-O ^64bit,^metadata_csum`.

### Backups

#### Backup Target
> Example: `s3://backupbucket@us-east-1/backupstore`

The target used for backup. NFS and S3 are supported. See [Setting a Backup Target](../../snapshots-and-backups/backup-and-restore/set-backup-target) for details.

#### Backup Target Credential Secret
> Example: `s3-secret`

The Kubernetes secret associated with the backup target. See [Setting a Backup Target](../../snapshots-and-backups/backup-and-restore/set-backup-target) for details.

#### Backupstore Poll Interval
> Default: `300`

The interval in seconds to poll the backup store for updating volumes' **Last Backup** field. Set to 0 to disable the polling. See [Setting up Disaster Recovery Volumes](../../snapshots-and-backups/setup-disaster-recovery-volumes) for details.

For more information on how the backupstore poll interval affects the recovery time objective and recovery point objective, refer to the [concepts section.](../../concepts/#34-backupstore-update-intervals-rto-and-rpo)


### Scheduling

#### Replica Node Level Soft Anti-Affinity
> Default: `false`

When this setting is checked, the Longhorn Manager will allow scheduling on nodes with existing healthy replicas of the same volume.

When this setting is un-checked, the Longhorn Manager will not allow scheduling on nodes with existing healthy replicas of the same volume.

#### Storage Over Provisioning Percentage
> Default: `200`

The over-provisioning percentage defines how much storage can be allocated relative to the hard drive's capacity.

With the default setting of 200, the Longhorn Manager will allow scheduling new replicas only after the amount of disk space has been added to the used disk space (**storage scheduled**), and the used disk space (**Storage Maximum** - **Storage Reserved**) is not over 200% of the actual usable disk capacity.

This value can be lowered to avoid overprovisioning storage. See [Multiple Disks Support](../../volumes-and-nodes/multidisk/#configuration) for details. Also, a replica of volume may take more space than the volume's size since the snapshots need storage space as well. The users can delete snapshots to reclaim spaces.

#### Storage Minimal Available Percentage
> Default: `25`

With the default setting of 25, the Longhorn Manager will allow scheduling new replicas only after the amount of disk space has been subtracted from the available disk space (**Storage Available**) and the available disk space is still over 25% of actual disk capacity (**Storage Maximum**). Otherwise the disk becomes unschedulable until more space is freed up.

See [Multiple Disks Support](../../volumes-and-nodes/multidisk/#configuration) for details.

#### Disable Scheduling On Cordoned Node
> Default: `true`

When this setting is checked, the Longhorn Manager will not schedule replicas on Kubernetes cordoned nodes.

When this setting is un-checked, the Longhorn Manager will schedule replicas on Kubernetes cordoned nodes.

#### Replica Zone Level Soft Anti-Affinity
> Default: `true`

When this setting is checked, the Longhorn Manager will allow scheduling new replicas of a volume to the nodes in the same zone as existing healthy replicas.

When this setting is un-checked, Longhorn Manager will not allow scheduling new replicas of a volume to the nodes in the same zone as existing healthy replicas.

> **Note:** Nodes that don't belong to any zone will be treated as if they belong to the same zone.

### Danger Zone

#### Kubernetes Taint Toleration
> Example: `nodetype=storage:NoSchedule`

By setting tolerations for Longhorn then adding taints for the nodes, the nodes with large storage can be dedicated to Longhorn only (to store replica data) and reject other general workloads.

Before modifying toleration setting, all Longhorn volumes should be detached then Longhorn components will be restarted to apply new tolerations. And toleration update will take a while. Users cannot operate Longhorn system during update. Hence it's recommended to set toleration during Longhorn deployment.

Multiple tolerations can be set here, and these tolerations are separated by semicolon. For example, `key1=value1:NoSchedule; key2:NoExecute`

See [Taint Toleration](../../advanced-resources/deploy/taint-toleration) for details.


#### Guaranteed Engine CPU
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
