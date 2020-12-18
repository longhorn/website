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
  - [Default Data Locality](#default-data-locality)
  - [Default Longhorn Static StorageClass Name](#default-longhorn-static-storageclass-name)
  - [Custom Resource API Version](#custom-resource-api-version)
  - [Automatic Salvage](#automatic-salvage)
  - [Automatically Delete Workload Pod when The Volume Is Detached Unexpectedly](#automatically-delete-workload-pod-when-the-volume-is-detached-unexpectedly)
  - [Registry Secret](#registry-secret)
  - [Volume Attachment Recovery Policy](#volume-attachment-recovery-policy)
  - [Pod Deletion Policy When Node is Down](#pod-deletion-policy-when-node-is-down)
  - [Custom mkfs.ext4 parameters](#custom-mkfsext4-parameters)
  - [Disable Revision Counter](#disable-revision-counter)
  - [System Pods Image Pull Policy](#system-pods-image-pull-policy)
  - [Auto Cleanup system Generated Snapshot](#auto-cleanup-system-generated-snapshot)

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
  - [Allow Volume Creation with Degraded Availability](#allow-volume-creation-with-degraded-availability)

- [Danger Zone](#danger-zone)
  - [Kubernetes Taint Toleration](#kubernetes-taint-toleration)
  - [Guaranteed Engine CPU](#guaranteed-engine-cpu)
  - [Priority Class](#priority-class)
  - [Disable Replica Rebuild](#disable-replica-rebuild)

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

#### Default Data Locality
> Default: `disabled`

We say a Longhorn volume has data locality if there is a local replica of the volume on the same node as the pod which is using the volume.
This setting specifies the default data locality when a volume is created from the Longhorn UI. For Kubernetes configuration, update the dataLocality in the StorageClass

The available modes are:

- `disabled`. This is the default option.
   There may or may not be a replica on the same node as the attached volume (workload).

- `best-effort`. This option instructs Longhorn to try to keep a replica on the same node as the attached volume (workload).
   Longhorn will not stop the volume, even if it cannot keep a replica local to the attached volume (workload) due to environment limitation, e.g. not enough disk space, incompatible disk tags, etc.

#### Default Longhorn Static StorageClass Name
> Default: `longhorn-static`

The `storageClassName` is for persistent volumes (PVs) and persistent volume claims (PVCs) when creating PV/PVC for an existing Longhorn volume. Notice that it's unnecessary for users to create the related StorageClass object in Kubernetes since the StorageClass would only be used as matching labels for PVC bounding purpose. By default 'longhorn-static'.

#### Custom Resource API Version
> Default: `longhorn.io/v1beta1`

The current customer resource's API version, e.g. longhorn.io/v1beta1. Set by manager automatically.

#### Automatic Salvage
> Default: `true`

If enabled, volumes will be automatically salvaged when all the replicas become faulty e.g. due to network disconnection. Longhorn will try to figure out which replica(s) are usable, then use them for the volume.

#### Automatically Delete Workload Pod when The Volume Is Detached Unexpectedly
> Default: `true`

If enabled, Longhorn will automatically delete the workload pod that is managed by a controller (e.g. deployment, statefulset, daemonset, etc...) when Longhorn volume is detached unexpectedly (e.g. during Kubernetes upgrade, Docker reboot, or network disconnect).
By deleting the pod, its controller restarts the pod and Kubernetes handles volume reattachment and remount.

If disabled, Longhorn will not delete the workload pod that is managed by a controller. You will have to manually restart the pod to reattach and remount the volume.

**Note:** This setting doesn't apply to the workload pods that don't have a controller. Longhorn never deletes them.

#### Registry Secret

The Kubernetes Secret name.

#### Volume Attachment Recovery Policy
> Default: `wait`

Defines the Longhorn action when a Volume is stuck with a Deployment Pod on a failed node.

- `wait`: Longhorn will wait to recover the Volume Attachment until all the terminating pods have passed their deletion grace period.
- `never`: The default Kubernetes behavior of never deleting volume attachments on terminating pods. Longhorn will not recover the Volume Attachment from a failed node.
- `immediate`: Longhorn will recover the Volume Attachment from the failed node as soon as there are pending replacement pods available.

#### Pod Deletion Policy When Node is Down
> Default: `do-nothing`

Defines the Longhorn action when a Volume is stuck with a StatefulSet/Deployment Pod on a node that is down.

- `do-nothing` is the default Kubernetes behavior of never force deleting StatefulSet/Deployment terminating pods. Since the pod on the node that is down isn't removed, Longhorn volumes are stuck on nodes that are down.
- `delete-statefulset-pod` Longhorn will force delete StatefulSet terminating pods on nodes that are down to release Longhorn volumes so that Kubernetes can spin up replacement pods.
- `delete-deployment-pod` Longhorn will force delete Deployment terminating pods on nodes that are down to release Longhorn volumes so that Kubernetes can spin up replacement pods.
- `delete-both-statefulset-and-deployment-pod` Longhorn will force delete StatefulSet/Deployment terminating pods on nodes that are down to release Longhorn volumes so that Kubernetes can spin up replacement pods.

#### Custom mkfs.ext4 parameters

Allows setting additional filesystem creation parameters for ext4. For older host kernels it might be necessary to disable the optional ext4 metadata_csum feature by specifying `-O ^64bit,^metadata_csum`.

#### Disable Revision Counter
> Default: `false`

Allows engine controller and engine replica to disable revision counter file update for every data write. This improves the data path performance. See [Revision Counter](../../advanced-resources/deploy/revision_counter) for details.

#### System Pods Image Pull Policy
> Default: `if-not-present`

Defines the image Pull Policy of Longhorn system managed pods, e.g. instance manager, engine image, CSI driver, etc. The new image Pull Policy will only apply after the system managed pods restart.

See [Kubernetes document on images](https://kubernetes.io/docs/concepts/containers/images/) for more information on the possible choices of the setting.

#### Auto Cleanup System Generated Snapshot

Longhorn will generate system snapshot during replica rebuild, and if a user doesn't setup a recurring snapshot schedule, all the system generated snapshots would be left in the replica, and user has to delete them manually, this setting allow Longhorn to automatically cleanup system generated snapshot after replica rebuild.

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

#### Allow Recurring Job While Volume Is Detached
> Default: `false`

If this setting is enabled, Longhorn automatically attaches the volume and takes snapshot/backup when it is the time to do recurring snapshot/backup.

Note that during the time the volume was attached automatically, the volume is not ready for the workload. the workload will have to wait until the recurring job finishes.

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

#### Allow Volume Creation with Degraded Availability
> Default: `true`

This setting allows user to create and attach a volume that doesn't have all the replicas scheduled at the time of creation.

> **Note:** It's recommended to disable this setting when using Longhorn in the production environment. See [Best Practices](../../best-practices/) for details.

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

In order to prevent unexpected volume crash, you can use the following formula to calculate an appropriate value for this setting:
```
Number of vCPUs = The estimated max Longhorn volume/replica count on a node * 0.1
```
The result of above calculation doesn't mean that's the maximum CPU resources the Longhorn workloads require. To fully exploit the Longhorn volume I/O performance, you can allocate/guarantee more CPU resources via this setting.

If it's hard to estimate the volume/replica count now, you can leave it with the default value, or allocate 1/8 of total CPU of a node. Then you can tune it when there is no running workload using Longhorn volumes.

> **Warning:** This setting should be changed only when all the volumes on the nodes are detached. Changing the setting will result in all the Instance Manager Pods restarting, which will automatically detach all the attached volumes, and could cause a workload outage.

##### Recommendations for the Guaranteed Engine CPU Allocation

Since Longhorn exposes the Volume as a block device, it's critical to ensure the Longhorn Engine processes have enough CPU to satisfy the latency requirement of the Linux system.

The Guaranteed Engine CPU should be set to **no more than a quarter** of what the node's available CPU resources, since the allocation is applied to the two Instance Managers on the node (engine and replica), and the future upgraded Instance Managers (another two for engine and replica).

For example, if the setting value is 0.25 or 250m, that means you must have at least 0.25 * 8 = 2 vCPUs per node. Otherwise, the new Instance Manager Pods may fail to start.

There are normally two Instance Manager Pods per node: one for the engine processes, and another one for the replica processes. But when Longhorn is upgrading from an old version of the Instance Manager to a new version, there can be at most four Pods requesting the reserved CPU on the node.

Taking other Kubernetes system components' CPU reservation request into consideration, we recommend having at least eight times the amount of CPU as the Guaranteed Engine CPU.

#### Priority Class
> Example: `high-priority`

By default, Longhorn workloads run with the same priority as other pods in the cluster, meaning in cases of node pressure, such as a node running out of memory, Longhorn workloads will be at the same priority as other Pods for eviction.

The Priority Class setting will specify a Priority Class for the Longhorn workloads to run as. This can be used to set the priority for Longhorn workloads higher so that they will not be the first to be evicted when a node is under pressure.

> **Warning:** This setting should only be changed after detaching all Longhorn volumes, as the Longhorn components will be restarted to apply the setting. The Priority Class update will take a while, and users cannot operate Longhorn system during the update. Hence, it's recommended to set the Priority Class during Longhorn deployment.

See [Priority Class](../../advanced-resources/deploy/priority-class) for details.

#### Disable Replica Rebuild
> Default: `false`

By disable replica rebuild, there won't be any new rebuild cross the whole cluster. The [Disks or Nodes Eviction Support](../../volumes-and-nodes/disks-or-nodes-eviction) and [Data Locality](../../high-availability/data-locality) feature won't work. But any restore features and currently rebuilding replica would still work as expected.
