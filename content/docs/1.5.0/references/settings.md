---
title: Settings Reference
weight: 1
---

- [Customizing Default Settings](#customizing-default-settings)
- [General](#general)
  - [Node Drain Policy](#node-drain-policy)
  - [Automatically Cleanup System Generated Snapshot](#automatically-cleanup-system-generated-snapshot)
  - [Automatically Delete Workload Pod when The Volume Is Detached Unexpectedly](#automatically-delete-workload-pod-when-the-volume-is-detached-unexpectedly)
  - [Automatic Salvage](#automatic-salvage)
  - [Concurrent Automatic Engine Upgrade Per Node Limit](#concurrent-automatic-engine-upgrade-per-node-limit)
  - [Concurrent Volume Backup Restore Per Node Limit](#concurrent-volume-backup-restore-per-node-limit)
  - [Create Default Disk on Labeled Nodes](#create-default-disk-on-labeled-nodes)
  - [Custom Resource API Version](#custom-resource-api-version)
  - [Default Data Locality](#default-data-locality)
  - [Default Data Path](#default-data-path)
  - [Default Engine Image](#default-engine-image)
  - [Default Instance Manager Image](#default-instance-manager-image)
  - [Default Longhorn Static StorageClass Name](#default-longhorn-static-storageclass-name)
  - [Default Replica Count](#default-replica-count)
  - [Default Share Manager Image](#default-share-manager-image)
  - [Deleting Confirmation Flag](#deleting-confirmation-flag)
  - [Disable Revision Counter](#disable-revision-counter)
  - [Enable Upgrade Checker](#enable-upgrade-checker)
  - [Latest Longhorn Version](#latest-longhorn-version)
  - [Pod Deletion Policy When Node is Down](#pod-deletion-policy-when-node-is-down)
  - [Registry Secret](#registry-secret)
  - [Replica Replenishment Wait Interval](#replica-replenishment-wait-interval)
  - [System Managed Pod Image Pull Policy](#system-managed-pod-image-pull-policy)
  - [Backing Image Cleanup Wait Interval](#backing-image-cleanup-wait-interval)
  - [Backing Image Recovery Wait Interval](#backing-image-recovery-wait-interval)
  - [Engine to Replica Timeout](#engine-to-replica-timeout)
  - [Support Bundle Manager Image](#support-bundle-manager-image)
  - [Support Bundle Failed History Limit](#support-bundle-failed-history-limit)
  - [Fast Replica Rebuild Enabled](#fast-replica-rebuild-enabled)
  - [Timeout of HTTP Client to Replica File Sync Server](#timeout-of-http-client-to-replica-file-sync-server)
- [Snapshot](#snapshot)
  - [Snapshot Data Integrity](#snapshot-data-integrity)
  - [Immediate Snapshot Data Integrity Check After Creating a Snapshot](#immediate-snapshot-data-integrity-check-after-creating-a-snapshot)
  - [Snapshot Data Integrity Check CronJob](#snapshot-data-integrity-check-cronjob)
- [Orphan](#orphan)
  - [Orphaned Data Automatic Deletion](#orphaned-data-automatic-deletion)
- [Backups](#backups)
  - [Allow Recurring Job While Volume Is Detached](#allow-recurring-job-while-volume-is-detached)
  - [Backup Target](#backup-target)
  - [Backup Target Credential Secret](#backup-target-credential-secret)
  - [Backupstore Poll Interval](#backupstore-poll-interval)
  - [Failed Backup Time To Live](#failed-backup-time-to-live)
  - [Cronjob Failed Jobs History Limit](#cronjob-failed-jobs-history-limit)
  - [Cronjob Successful Jobs History Limit](#cronjob-successful-jobs-history-limit)
  - [Restore Volume Recurring Jobs](#restore-volume-recurring-jobs)
- [Scheduling](#scheduling)
  - [Allow Volume Creation with Degraded Availability](#allow-volume-creation-with-degraded-availability)
  - [Disable Scheduling On Cordoned Node](#disable-scheduling-on-cordoned-node)
  - [Replica Node Level Soft Anti-Affinity](#replica-node-level-soft-anti-affinity)
  - [Replica Zone Level Soft Anti-Affinity](#replica-zone-level-soft-anti-affinity)
  - [Replica Auto Balance](#replica-auto-balance)
  - [Storage Minimal Available Percentage](#storage-minimal-available-percentage)
  - [Storage Over Provisioning Percentage](#storage-over-provisioning-percentage)
- [Danger Zone](#danger-zone)
  - [Concurrent Replica Rebuild Per Node Limit](#concurrent-replica-rebuild-per-node-limit)
  - [Guaranteed Engine Manager CPU](#guaranteed-engine-manager-cpu)
  - [Guaranteed Replica Manager CPU](#guaranteed-replica-manager-cpu)
  - [Kubernetes Taint Toleration](#kubernetes-taint-toleration)
  - [Priority Class](#priority-class)
  - [System Managed Components Node Selector](#system-managed-components-node-selector)
  - [Kubernetes Cluster Autoscaler Enabled (Experimental)](#kubernetes-cluster-autoscaler-enabled-experimental)
  - [Storage Network](#storage-network)
  - [Remove Snapshots During Filesystem Trim](#remove-snapshots-during-filesystem-trim)
- [Deprecated](#deprecated)
  - [Disable Replica Rebuild](#disable-replica-rebuild)
  - [Allow Node Drain with the Last Healthy Replica](#allow-node-drain-with-the-last-healthy-replica)

### Customizing Default Settings

To configure Longhorn before installing it, see [this section](../../advanced-resources/deploy/customizing-default-settings) for details.

### General

#### Node Drain Policy

> Default: `block-if-contains-last-replica`

Define the policy to use when a node with the last healthy replica of a volume is drained. Available options:
- `block-if-contains-last-replica`: Longhorn will block the drain when the node contains the last healthy replica of a volume.
- `allow-if-replica-is-stopped`: Longhorn will allow the drain when the node contains the last healthy replica of a volume but the replica is stopped.
  WARNING: possible data loss if the node is removed after draining. Select this option if you want to drain the node and do in-place upgrade/maintenance.
- `always-allow`: Longhorn will allow the drain even though the node contains the last healthy replica of a volume.
  WARNING: possible data loss if the node is removed after draining. Also possible data corruption if the last replica was running during the draining.

#### Automatically Cleanup System Generated Snapshot

> Default: `true`

Longhorn will generate system snapshot during replica rebuild, and if a user doesn't setup a recurring snapshot schedule, all the system generated snapshots would be left in the replica, and user has to delete them manually, this setting allow Longhorn to automatically cleanup system generated snapshot before and after replica rebuild.

#### Automatically Delete Workload Pod when The Volume Is Detached Unexpectedly

> Default: `true`

If enabled, Longhorn will automatically delete the workload pod that is managed by a controller (e.g. deployment, statefulset, daemonset, etc...) when Longhorn volume is detached unexpectedly (e.g. during Kubernetes upgrade, Docker reboot, or network disconnect).
By deleting the pod, its controller restarts the pod and Kubernetes handles volume reattachment and remount.

If disabled, Longhorn will not delete the workload pod that is managed by a controller. You will have to manually restart the pod to reattach and remount the volume.

**Note:** This setting doesn't apply to the workload pods that don't have a controller. Longhorn never deletes them.

#### Automatic Salvage

> Default: `true`

If enabled, volumes will be automatically salvaged when all the replicas become faulty e.g. due to network disconnection. Longhorn will try to figure out which replica(s) are usable, then use them for the volume.

#### Concurrent Automatic Engine Upgrade Per Node Limit

> Default: `0`

This setting controls how Longhorn automatically upgrades volumes' engines to the new default engine image after upgrading Longhorn manager.
The value of this setting specifies the maximum number of engines per node that are allowed to upgrade to the default engine image at the same time.
If the value is 0, Longhorn will not automatically upgrade volumes' engines to default version.

#### Concurrent Volume Backup Restore Per Node Limit

> Default: `5`

This setting controls how many volumes on a node can restore the backup concurrently.

Longhorn blocks the backup restore once the restoring volume count exceeds the limit.

Set the value to **0** to disable backup restore.

#### Create Default Disk on Labeled Nodes

> Default: `false`

If no other disks exist, create the default disk automatically, only on nodes with the Kubernetes label `node.longhorn.io/create-default-disk=true` .

If disabled, the default disk will be created on all new nodes when the node is detected for the first time.

This option is useful if you want to scale the cluster but don't want to use storage on the new nodes, or if you want to [customize disks for Longhorn nodes](../../advanced-resources/default-disk-and-node-config).

#### Custom Resource API Version

> Default: `longhorn.io/v1beta2`

The current customer resource's API version, e.g. longhorn.io/v1beta2. Set by manager automatically.

#### Default Data Locality

> Default: `disabled`

We say a Longhorn volume has data locality if there is a local replica of the volume on the same node as the pod which is using the volume.
This setting specifies the default data locality when a volume is created from the Longhorn UI. For Kubernetes configuration, update the dataLocality in the StorageClass

The available modes are:

- `disabled`. This is the default option.
  There may or may not be a replica on the same node as the attached volume (workload).

- `best-effort`. This option instructs Longhorn to try to keep a replica on the same node as the attached volume (workload).
  Longhorn will not stop the volume, even if it cannot keep a replica local to the attached volume (workload) due to environment limitation, e.g. not enough disk space, incompatible disk tags, etc.

- `strict-local`: This option enforces Longhorn keep the **only one replica** on the same node as the attached volume, and therefore, it offers higher IOPS and lower latency performance.


#### Default Data Path

> Default: `/var/lib/longhorn/`

Default path to use for storing data on a host.

Can be used with `Create Default Disk on Labeled Nodes` option, to make Longhorn only use the nodes with specific storage mounted at, for example, `/opt/longhorn` when scaling the cluster.

#### Default Engine Image

The default engine image used by the manager. Can be changed on the manager starting command line only.

Every Longhorn release will ship with a new Longhorn engine image. If the current Longhorn volumes are not using the default engine, a green arrow will show up, indicate this volume needs to be upgraded to use the default engine.

#### Default Instance Manager Image

The default instance manager image used by the manager. Can be changed on the manager starting command line only.

#### Default Longhorn Static StorageClass Name

> Default: `longhorn-static`

The `storageClassName` is for persistent volumes (PVs) and persistent volume claims (PVCs) when creating PV/PVC for an existing Longhorn volume. Notice that it's unnecessary for users to create the related StorageClass object in Kubernetes since the StorageClass would only be used as matching labels for PVC bounding purpose. By default 'longhorn-static'.

#### Default Replica Count

> Default: `3`

The default number of replicas when creating the volume from Longhorn UI. For Kubernetes, update the `numberOfReplicas` in the StorageClass

The recommended way of choosing the default replica count is: if you have three or more nodes for storage, use 3; otherwise use 2. Using a single replica on a single node cluster is also OK, but the high availability functionality wouldn't be available. You can still take snapshots/backups of the volume.

#### Default Share Manager Image

The default instance manager image used by the manager. Can be changed on the manager starting command line only.

#### Deleting Confirmation Flag
This flag protects Longhorn from unexpected uninstallation which leads to data loss.
Set this flag to **true** to allow Longhorn uninstallation.
If this flag is **false**, the Longhorn uninstallation job will fail.

> Default: `false`

#### Disable Revision Counter

> Default: `false`

Allows engine controller and engine replica to disable revision counter file update for every data write. This improves the data path performance. See [Revision Counter](../../advanced-resources/deploy/revision_counter) for details.

#### Enable Upgrade Checker

> Default: `true`

Upgrade Checker will check for a new Longhorn version periodically. When there is a new version available, it will notify the user in the Longhorn UI.

#### Latest Longhorn Version

The latest version of Longhorn available. Automatically updated by the Upgrade Checker.

Only available if `Upgrade Checker` is enabled.

#### Pod Deletion Policy When Node is Down

> Default: `do-nothing`

Defines the Longhorn action when a Volume is stuck with a StatefulSet/Deployment Pod on a node that is down.

- `do-nothing` is the default Kubernetes behavior of never force deleting StatefulSet/Deployment terminating pods. Since the pod on the node that is down isn't removed, Longhorn volumes are stuck on nodes that are down.
- `delete-statefulset-pod` Longhorn will force delete StatefulSet terminating pods on nodes that are down to release Longhorn volumes so that Kubernetes can spin up replacement pods.
- `delete-deployment-pod` Longhorn will force delete Deployment terminating pods on nodes that are down to release Longhorn volumes so that Kubernetes can spin up replacement pods.
- `delete-both-statefulset-and-deployment-pod` Longhorn will force delete StatefulSet/Deployment terminating pods on nodes that are down to release Longhorn volumes so that Kubernetes can spin up replacement pods.

#### Registry Secret

The Kubernetes Secret name.

#### Replica Replenishment Wait Interval

> Default: `600`

When there is at least one failed replica volume in a degraded volume, this interval in seconds determines how long Longhorn will wait at most in order to reuse the existing data of the failed replicas rather than directly creating a new replica for this volume.

Warning: This wait interval works only when there is at least one failed replica in the volume. And this option may block the rebuilding for a while.

#### System Managed Pod Image Pull Policy

> Default: `if-not-present`

This setting defines the Image Pull Policy of Longhorn system managed pods, e.g. instance manager, engine image, CSI driver, etc.

Notice that the new Image Pull Policy will only apply after the system managed pods restart.

This setting definition is exactly the same as that of in Kubernetes. Here are the available options:

- `always`. Every time the kubelet launches a container, the kubelet queries the container image registry to resolve the name to an image digest. If the kubelet has a container image with that exact digest cached locally, the kubelet uses its cached image; otherwise, the kubelet downloads (pulls) the image with the resolved digest, and uses that image to launch the container.

- `if-not-present`. The image is pulled only if it is not already present locally.

- `never`. The image is assumed to exist locally. No attempt is made to pull the image.


#### Backing Image Cleanup Wait Interval
> Default: `60`

This interval in minutes determines how long Longhorn will wait before cleaning up the backing image file when there is no replica in the disk using it.

#### Backing Image Recovery Wait Interval
> Default: `300`

The interval in seconds determines how long Longhorn will wait before re-downloading the backing image file when all disk files of this backing image become `failed` or `unknown`.
> **Note:**
>  - This recovery only works for the backing image of which the creation type is `download`.
>  - File state `unknown` means the related manager pods on the pod is not running or the node itself is down/disconnected.

#### Engine to Replica Timeout
> Default: `8`

The value in seconds specifies the timeout of the engine to the replica(s), and the value should be between 8 to 30 seconds.

#### Support Bundle Manager Image

Longhorn uses the support bundle manager image to generate the support bundles.

There will be a default image given during installation and upgrade. You can also change it in the settings.

An example of the support bundle manager image:
> Default: `longhornio/support-bundle-kit:v0.0.14`

#### Support Bundle Failed History Limit

> Default: `1`

This setting specifies how many failed support bundles can exist in the cluster.

The retained failed support bundle is for analysis purposes and needs to clean up manually.

Longhorn blocks support bundle creation when reaching the upper bound of the limitation. You can set this value to **0** to have Longhorn automatically purge all failed support bundles.

#### Fast Replica Rebuild Enabled

> Default: `false`

The setting enables fast replica rebuilding feature. It relies on the checksums of snapshot disk files, so setting the snapshot-data-integrity to **enable** or **fast-check** is a prerequisite.

#### Timeout of HTTP Client to Replica File Sync Server

> Default: `30`

The value in seconds specifies the timeout of the HTTP client to the replica's file sync server used for replica rebuilding, volume cloning, snapshot cloning, etc.

### Snapshot

#### Snapshot Data Integrity

> Default: `fast-check`

This setting allows users to enable or disable snapshot hashing and data integrity checking. Available options are:
- **disabled**: Disable snapshot disk file hashing and data integrity checking.
- **enabled**: Enables periodic snapshot disk file hashing and data integrity checking. To detect the filesystem-unaware corruption caused by bit rot or other issues in snapshot disk files, Longhorn system periodically hashes files and finds corrupted ones. Hence, the system performance will be impacted during the periodical checking.
- **fast-check**: Enable snapshot disk file hashing and fast data integrity checking. Longhorn system only hashes snapshot disk files if their are not hashed or the modification time are changed. In this mode, filesystem-unaware corruption cannot be detected, but the impact on system performance can be minimized.

#### Immediate Snapshot Data Integrity Check After Creating a Snapshot

> Default: `false`

Hashing snapshot disk files impacts the performance of the system. The immediate snapshot hashing and checking can be disabled to minimize the impact after creating a snapshot.

#### Snapshot Data Integrity Check CronJob

> Default: `0 0 */7 * *`

Unix-cron string format. The setting specifies when Longhorn checks the data integrity of snapshot disk files.
> **Warning**
> Hashing snapshot disk files impacts the performance of the system. It is recommended to run data integrity checks during off-peak times and to reduce the frequency of checks.


### Orphan

#### Orphaned Data Automatic Deletion
> Default: `false`

This setting allows Longhorn to automatically delete the `orphan` resource and its orphaned data like volume replica.

### Backups

#### Allow Recurring Job While Volume Is Detached

> Default: `false`

If this setting is enabled, Longhorn automatically attaches the volume and takes snapshot/backup when it is the time to do recurring snapshot/backup.

Note that during the time the volume was attached automatically, the volume is not ready for the workload. the workload will have to wait until the recurring job finishes.

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

#### Failed Backup Time To Live

> Default: `1440`

The interval in minutes to keep the backup resource that was failed. Set to 0 to disable the auto-deletion.

Failed backups will be checked and cleaned up during backupstore polling which is controlled by **Backupstore Poll Interval** setting. Hence this value determines the minimal wait interval of the cleanup. And the actual cleanup interval is multiple of **Backupstore Poll Interval**. Disabling **Backupstore Poll Interval** also means to disable failed backup auto-deletion.

#### Cronjob Failed Jobs History Limit

> Default: `1`

This setting specifies how many failed backup or snapshot job histories should be retained.

History will not be retained if the value is 0.


#### Cronjob Successful Jobs History Limit

> Default: `1`

This setting specifies how many successful backup or snapshot job histories should be retained.

History will not be retained if the value is 0.

#### Restore Volume Recurring Jobs

> Default: `false`

This setting allows restoring the recurring jobs of a backup volume from the backup target during a volume restoration if they do not exist on the cluster.
This is also a volume-specific setting with the below options. Users can customize it for each volume to override the global setting.

> Default: `ignored`

- `ignored`: This is the default option that instructs Longhorn to inherit from the global setting.

- `enabled`: This option instructs Longhorn to restore volume recurring jobs/groups from the backup target forcibly.

- `disabled`: This option instructs Longhorn no restoring volume recurring jobs/groups should be done.

### Scheduling

#### Allow Volume Creation with Degraded Availability

> Default: `true`

This setting allows user to create and attach a volume that doesn't have all the replicas scheduled at the time of creation.

> **Note:** It's recommended to disable this setting when using Longhorn in the production environment. See [Best Practices](../../best-practices/) for details.

#### Disable Scheduling On Cordoned Node

> Default: `true`

When this setting is checked, the Longhorn Manager will not schedule replicas on Kubernetes cordoned nodes.

When this setting is un-checked, the Longhorn Manager will schedule replicas on Kubernetes cordoned nodes.

#### Replica Node Level Soft Anti-Affinity

> Default: `false`

When this setting is checked, the Longhorn Manager will allow scheduling on nodes with existing healthy replicas of the same volume.

When this setting is un-checked, the Longhorn Manager will not allow scheduling on nodes with existing healthy replicas of the same volume.

#### Replica Zone Level Soft Anti-Affinity

> Default: `true`

When this setting is checked, the Longhorn Manager will allow scheduling new replicas of a volume to the nodes in the same zone as existing healthy replicas.

When this setting is un-checked, Longhorn Manager will not allow scheduling new replicas of a volume to the nodes in the same zone as existing healthy replicas.

> **Note:**
>   - Nodes that don't belong to any zone will be treated as if they belong to the same zone.
>   - Longhorn relies on label `topology.kubernetes.io/zone=<Zone name of the node>` in the Kubernetes node object to identify the zone.

#### Replica Auto Balance

> Default: `disabled`

Enable this setting automatically rebalances replicas when discovered an available node.

The available global options are:
- `disabled`. This is the default option. No replica auto-balance will be done.

- `least-effort`. This option instructs Longhorn to balance replicas for minimal redundancy.

- `best-effort`. This option instructs Longhorn try to balancing replicas for even redundancy.
  Longhorn does not forcefully re-schedule the replicas to a zone that does not have enough nodes
  to support even balance. Instead, Longhorn will re-schedule to balance at the node level.

Longhorn also supports customizing for individual volume. The setting can be specified in UI or with Kubernetes manifest volume.spec.replicaAutoBalance, this overrules the global setting.
The available volume spec options are:

> Default: `ignored`

- `ignored`. This is the default option that instructs Longhorn to inherit from the global setting.

- `disabled`. This option instructs Longhorn no replica auto-balance should be done."

- `least-effort`. This option instructs Longhorn to balance replicas for minimal redundancy.

- `best-effort`. This option instructs Longhorn to try balancing replicas for even redundancy.
  Longhorn does not forcefully re-schedule the replicas to a zone that does not have enough nodes
  to support even balance. Instead, Longhorn will re-schedule to balance at the node level.

#### Storage Minimal Available Percentage

> Default: `25`

With the default setting of 25, the Longhorn Manager will allow scheduling new replicas only after the amount of disk space has been subtracted from the available disk space (**Storage Available**) and the available disk space is still over 25% of actual disk capacity (**Storage Maximum**). Otherwise the disk becomes unschedulable until more space is freed up.

See [Multiple Disks Support](../../volumes-and-nodes/multidisk/#configuration) for details.

#### Storage Over Provisioning Percentage

> Default: `200`

The over-provisioning percentage defines how much storage can be allocated relative to the hard drive's capacity.

With the default setting of 200, the Longhorn Manager will allow scheduling new replicas only after the amount of disk space has been added to the used disk space (**storage scheduled**), and the used disk space (**Storage Maximum** - **Storage Reserved**) is not over 200% of the actual usable disk capacity.

This value can be lowered to avoid overprovisioning storage. See [Multiple Disks Support](../../volumes-and-nodes/multidisk/#configuration) for details. Also, a replica of volume may take more space than the volume's size since the snapshots need storage space as well. The users can delete snapshots to reclaim spaces.

### Danger Zone

#### Concurrent Replica Rebuild Per Node Limit

> Default: `5`

This setting controls how many replicas on a node can be rebuilt simultaneously.

Typically, Longhorn can block the replica starting once the current rebuilding count on a node exceeds the limit. But when the value is 0, it means disabling the replica rebuilding.

> **WARNING:**
>  - The old setting "Disable Replica Rebuild" is replaced by this setting.
>  - Different from relying on replica starting delay to limit the concurrent rebuilding, if the rebuilding is disabled, replica object replenishment will be directly skipped.
>  - When the value is 0, the eviction and data locality feature won't work. But this shouldn't have any impact to any current replica rebuild and backup restore.


#### Guaranteed Engine Manager CPU

> Default: `12`

This integer value indicates what percentage of the total allocatable CPU on each node will be reserved for each engine manager Pod. For example, 10 means 10% of the total CPU on a node will be allocated to each engine manager pod on this node. This will help maintain engine stability during high node workload.

In order to prevent an unexpected volume engine crash as well as guarantee a relatively acceptable I/O performance, you can use the following formula to calculate a value for this setting:

    Guaranteed Engine Manager CPU = The estimated max Longhorn volume engine count on a node * 0.1 / The total allocatable CPUs on the node * 100.

The result of above calculation doesn't mean that's the maximum CPU resources the Longhorn workloads require. To fully exploit the Longhorn volume I/O performance, you can allocate/guarantee more CPU resources via this setting.

If it's hard to estimate the usage now, you can leave it with the default value, which is 12%. Then you can tune it when there is no running workload using Longhorn volumes.

> **Warning:**
>  - Value 0 means removing the CPU requests from spec of engine manager pods.
>  - Considering the possible number of new instance manager pods in a further system upgrade, this integer value ranges from 0 to 40. And the total combined with the setting 'Guaranteed Replica Manager CPU' should not be greater than 40.
>  - One more set of instance manager pods may need to be deployed when the Longhorn system is upgraded. If current available CPUs of the nodes are not enough for the new instance manager pods, you need to detach the volumes using the oldest instance manager pods so that Longhorn can clean up the old pods automatically and release the CPU resources. And the new pods with the latest instance manager image will be launched then.
>  - This global setting will be ignored for a node if the field "EngineManagerCPURequest" on the node is set.
>  - After this setting is changed, all engine manager pods using this global setting on all the nodes will be automatically restarted. In other words, DO NOT CHANGE THIS SETTING WITH ATTACHED VOLUMES.

#### Guaranteed Replica Manager CPU

> Default: `12`

Similar to "Guaranteed Engine Manager CPU", this integer value indicates what percentage of the total allocatable CPU on each node will be reserved for each replica manager Pod. For example, 10 means 10% of the total CPU on a node will be allocated to each replica manager pod on this node. This will help maintain replica stability during high node workload.

In order to prevent an unexpected volume replica crash as well as guarantee a relatively acceptable IO performance, you can use the following formula to calculate a value for this setting:

    Guaranteed Replica Manager CPU = The estimated max Longhorn volume replica count on a node * 0.1 / The total allocatable CPUs on the node * 100.

The result of above calculation doesn't mean that's the maximum CPU resources the Longhorn workloads require. To fully exploit the Longhorn volume I/O performance, you can allocate/guarantee more CPU resources via this setting.

If it's hard to estimate the usage now, you can leave it with the default value, which is 12%. Then you can tune it when there is no running workload using Longhorn volumes.

> **Warning:**
>  - Value 0 means removing the CPU requests from specs of replica manager pods.
>  - Considering the possible number of new instance manager pods in a further system upgrade, this integer value ranges from 0 to 40. And the total combined with the setting 'Guaranteed Engine Manager CPU' should not be greater than 40.
>  - One more set of instance manager pods may need to be deployed when the Longhorn system is upgraded. If current available CPUs of the nodes are not enough for the new instance manager pods, you need to detach the volumes using the oldest instance manager pods so that Longhorn can clean up the old pods automatically and release the CPU resources. And the new pods with the latest instance manager image will be launched then.
>  - This global setting will be ignored for a node if the field "ReplicaManagerCPURequest" on the node is set.
>  - After this setting is changed, all replica manager pods using this global setting on all the nodes will be automatically restarted. In other words, DO NOT CHANGE THIS SETTING WITH ATTACHED VOLUMES.


#### Kubernetes Taint Toleration

> Example: `nodetype=storage:NoSchedule`

If you want to dedicate nodes to just store Longhorn replicas and reject other general workloads, you can set tolerations for **all** Longhorn components and add taints to the nodes dedicated for storage.

Longhorn system contains user deployed components (e.g, Longhorn manager, Longhorn driver, Longhorn UI) and system managed components (e.g, instance manager, engine image, CSI driver, etc.)
This setting only sets taint tolerations for system managed components.
Depending on how you deployed Longhorn, you need to set taint tolerations for user deployed components in Helm chart or deployment YAML file.

All Longhorn volumes should be detached before modifying toleration settings.
We recommend setting tolerations during Longhorn deployment because the Longhorn system cannot be operated during the update.

Multiple tolerations can be set here, and these tolerations are separated by semicolon. For example:
* `key1=value1:NoSchedule; key2:NoExecute`
* `:` this toleration tolerates everything because an empty key with operator `Exists` matches all keys, values and effects
* `key1=value1:`  this toleration has empty effect. It matches all effects with key `key1`
  See [Taint Toleration](../../advanced-resources/deploy/taint-toleration) for details.

#### Priority Class

> Example: `high-priority`

By default, Longhorn workloads run with the same priority as other pods in the cluster, meaning in cases of node pressure, such as a node running out of memory, Longhorn workloads will be at the same priority as other Pods for eviction.

The Priority Class setting will specify a Priority Class for the Longhorn workloads to run as. This can be used to set the priority for Longhorn workloads higher so that they will not be the first to be evicted when a node is under pressure.

Longhorn system contains user deployed components (e.g, Longhorn manager, Longhorn driver, Longhorn UI) and system managed components (e.g, instance manager, engine image, CSI driver, etc.)
Note that this setting only sets Priority Class for system managed components.
Depending on how you deployed Longhorn, you need to set Priority Class for user deployed components in Helm chart or deployment YAML file.
> **Warning:** This setting should only be changed after detaching all Longhorn volumes, as the Longhorn system components will be restarted to apply the setting. The Priority Class update will take a while, and users cannot operate Longhorn system during the update. Hence, it's recommended to set the Priority Class during Longhorn deployment.

See [Priority Class](../../advanced-resources/deploy/priority-class) for details.

#### System Managed Components Node Selector

> Example: `label-key1:label-value1;label-key2:label-value2`

If you want to restrict Longhorn components to only run on a particular set of nodes, you can set node selector for all Longhorn components.

Longhorn system contains user deployed components (e.g, Longhorn manager, Longhorn driver, Longhorn UI) and system managed components (e.g, instance manager, engine image, CSI driver, etc.)
You need to set node selector for both of them. This setting only sets node selector for system managed components. Follow the instruction at [Node Selector](../../advanced-resources/deploy/node-selector) to change node selector.

> **Warning:**  Since all Longhorn components will be restarted, the Longhorn system is unavailable temporarily.
Make sure all Longhorn volumes are `detached`. If there are running Longhorn volumes in the system, this means the Longhorn system cannot restart its components and the request will be rejected.
Don't operate the Longhorn system while node selector settings are updated and Longhorn components are being restarted.

#### Kubernetes Cluster Autoscaler Enabled (Experimental)

> Default: `false`

Setting the Kubernetes Cluster Autoscaler Enabled to `true` allows Longhorn to unblock the Kubernetes Cluster Autoscaler scaling.

See [Kubernetes Cluster Autoscaler Support](../../high-availability/k8s-cluster-autoscaler) for details.

> **Warning:** Replica rebuilding could be expensive because nodes with reusable replicas could get removed by the Kubernetes Cluster Autoscaler.

#### Storage Network

> Example: `kube-system/demo-192-168-0-0`

The storage network uses Multus NetworkAttachmentDefinition to segregate the in-cluster data traffic from the default Kubernetes cluster network.

> **Warning:** This setting should change after detaching all Longhorn volumes, as some of the Longhorn system component pods will get recreated to apply the setting. Longhorn will try to block this setting update when there are attached volumes.

See [Storage Network](../../advanced-resources/deploy/storage-network) for details.

#### Remove Snapshots During Filesystem Trim

> Example: `false`

This setting allows Longhorn filesystem trim feature to automatically mark the latest snapshot and its ancestors as removed and stops at the snapshot containing multiple children.

Since Longhorn filesystem trim feature can be applied to the volume head and the followed continuous removed or system snapshots only.

Notice that trying to trim a removed files from a valid snapshot will do nothing but the filesystem will discard this kind of in-memory trimmable file info. Later on if you mark the snapshot as removed and want to retry the trim, you may need to unmount and remount the filesystem so that the filesystem can recollect the trimmable file info.

See [Trim Filesystem](../../volumes-and-nodes/trim-filesystem) for details.

### Deprecated

#### Disable Replica Rebuild

> Default: `false`

This deprecated setting is replaced by the new setting `Concurrent Replica Rebuild Per Node Limit`. Once the new setting value is 0, it means rebuilding disable.

#### Allow Node Drain with the Last Healthy Replica

> Default: `false`

By default, Longhorn will block `kubectl drain` action on a node if the node contains the last healthy replica of a volume. If this setting is enabled, Longhorn will not block `kubectl drain` action on a node even if the node contains the last healthy replica of a volume.


This deprecated setting is replaced by the new setting [Node Drain Policy](#node-drain-policy)
