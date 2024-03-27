---
title: Settings Reference
weight: 1
---

- [Customizing Default Settings](#customizing-default-settings)
- [General](#general)
  - [Node Drain Policy](#node-drain-policy)
  - [Detach Manually Attached Volumes When Cordoned](#detach-manually-attached-volumes-when-cordoned)
  - [Automatically Clean up System Generated Snapshot](#automatically-clean-up-system-generated-snapshot)
  - [Automatically Clean up Outdated Snapshots of Recurring Backup Jobs](#automatically-clean-up-outdated-snapshots-of-recurring-backup-jobs)
  - [Automatically Delete Workload Pod when The Volume Is Detached Unexpectedly](#automatically-delete-workload-pod-when-the-volume-is-detached-unexpectedly)
  - [Automatic Salvage](#automatic-salvage)
  - [Concurrent Automatic Engine Upgrade Per Node Limit](#concurrent-automatic-engine-upgrade-per-node-limit)
  - [Concurrent Volume Backup Restore Per Node Limit](#concurrent-volume-backup-restore-per-node-limit)
  - [Create Default Disk on Labeled Nodes](#create-default-disk-on-labeled-nodes)
  - [Custom Resource API Version](#custom-resource-api-version)
  - [Default Data Locality](#default-data-locality)
  - [Default Data Path](#default-data-path)
  - [Default Engine Image](#default-engine-image)
  - [Default Longhorn Static StorageClass Name](#default-longhorn-static-storageclass-name)
  - [Default Replica Count](#default-replica-count)
  - [Deleting Confirmation Flag](#deleting-confirmation-flag)
  - [Disable Revision Counter](#disable-revision-counter)
  - [Enable Upgrade Checker](#enable-upgrade-checker)
  - [Latest Longhorn Version](#latest-longhorn-version)
  - [Allow Collecting Longhorn Usage Metrics](#allow-collecting-longhorn-usage-metrics)
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
  - [V1 Data Engine](#v1-data-engine)
- [V2 Data Engine (Preview Feature)](#v2-data-engine-preview-feature)
  - [V2 Data Engine](#v2-data-engine)
  - [V2 Data Engine Hugepage Limit](#v2-data-engine-hugepage-limit)
  - [Guaranteed Instance Manager CPU for V2 Data Engine](#guaranteed-instance-manager-cpu-for-v2-data-engine)
  - [Offline Replica Rebuilding](#offline-replica-rebuilding)
- [Snapshot](#snapshot)
  - [Snapshot Data Integrity](#snapshot-data-integrity)
  - [Immediate Snapshot Data Integrity Check After Creating a Snapshot](#immediate-snapshot-data-integrity-check-after-creating-a-snapshot)
  - [Snapshot Data Integrity Check CronJob](#snapshot-data-integrity-check-cronjob)
  - [Snapshot Maximum Count](#snapshot-maximum-count)
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
  - [Backup Compression Method](#backup-compression-method)
  - [Backup Concurrent Limit Per Backup](#backup-concurrent-limit-per-backup)
  - [Restore Concurrent Limit Per Backup](#restore-concurrent-limit-per-backup)
- [Scheduling](#scheduling)
  - [Allow Volume Creation with Degraded Availability](#allow-volume-creation-with-degraded-availability)
  - [Disable Scheduling On Cordoned Node](#disable-scheduling-on-cordoned-node)
  - [Replica Node Level Soft Anti-Affinity](#replica-node-level-soft-anti-affinity)
  - [Replica Zone Level Soft Anti-Affinity](#replica-zone-level-soft-anti-affinity)
  - [Replica Disk Level Soft Anti-Affinity](#replica-disk-level-soft-anti-affinity)
  - [Replica Auto Balance](#replica-auto-balance)
  - [Storage Minimal Available Percentage](#storage-minimal-available-percentage)
  - [Storage Over Provisioning Percentage](#storage-over-provisioning-percentage)
  - [Storage Reserved Percentage For Default Disk](#storage-reserved-percentage-for-default-disk)
  - [Allow Empty Node Selector Volume](#allow-empty-node-selector-volume)
  - [Allow Empty Disk Selector Volume](#allow-empty-disk-selector-volume)
- [Danger Zone](#danger-zone)
  - [Concurrent Replica Rebuild Per Node Limit](#concurrent-replica-rebuild-per-node-limit)
  - [Kubernetes Taint Toleration](#kubernetes-taint-toleration)
  - [Priority Class](#priority-class)
  - [System Managed Components Node Selector](#system-managed-components-node-selector)
  - [Kubernetes Cluster Autoscaler Enabled (Experimental)](#kubernetes-cluster-autoscaler-enabled-experimental)
  - [Storage Network](#storage-network)
  - [Remove Snapshots During Filesystem Trim](#remove-snapshots-during-filesystem-trim)
  - [Guaranteed Instance Manager CPU](#guaranteed-instance-manager-cpu)
  - [Disable Snapshot Purge](#disable-snapshot-purge)

### Customizing Default Settings

To configure Longhorn before installing it, see [this section](../../advanced-resources/deploy/customizing-default-settings) for details.

### General

#### Node Drain Policy

> Default: `block-if-contains-last-replica`

Define the policy to use when a node with the last healthy replica of a volume is drained. Available options:

- `block-if-contains-last-replica`: Longhorn will block the drain when the node contains the last healthy replica of a
  volume.
- `allow-if-replica-is-stopped`: Longhorn will allow the drain when the node contains the last healthy replica of a
  volume but the replica is stopped.  
  WARNING: possible data loss if the node is removed after draining.
- `always-allow`: Longhorn will allow the drain even though the node contains the last healthy replica of a volume.  
  WARNING: possible data loss if the node is removed after draining. Also possible data corruption if the last replica
  was running during the draining.
- `block-for-eviction`: Longhorn will automatically evict all replicas and block the drain until eviction is complete.  
  WARNING: Can result in slow drains and extra data movement associated with replica rebuilding.
- `block-for-eviction-if-contains-last-replica`: Longhorn will automatically evict any replicas that don't have a
  healthy counterpart and block the drain until eviction is complete.  
  WARNING: Can result in slow drains and extra data movement associated with replica rebuilding.

Each option has benefits and drawbacks. See [Node Drain Policy
Recommendations](../../maintenance/maintenance/#node-drain-policy-recommendations) for help deciding which is most
appropriate in your environment.

#### Detach Manually Attached Volumes When Cordoned

> Default: `false`

Longhorn will automatically detach volumes that are manually attached to the nodes which are cordoned. 
This prevent the draining process stuck by the PDB of instance-manager which still has running engine on the node.

#### Automatically Clean up System Generated Snapshot

> Default: `true`

Longhorn will generate system snapshot during replica rebuild, and if a user doesn't setup a recurring snapshot schedule, all the system generated snapshots would be left in the replica, and user has to delete them manually, this setting allow Longhorn to automatically cleanup system generated snapshot before and after replica rebuild.

#### Automatically Clean up Outdated Snapshots of Recurring Backup Jobs

> Default: `true`

If enabled, when running a recurring backup job, Longhorn takes a new snapshot before creating the backup. Longhorn retains only the snapshot used by the last backup job even if the value of the retain parameter is not 1.

If disabled, this setting ensures that the retained snapshots directly correspond to the backups on the remote backup target.

#### Automatically Delete Workload Pod when The Volume Is Detached Unexpectedly

> Default: `true`

If enabled, Longhorn will automatically delete the workload pod that is managed by a controller (e.g. deployment, statefulset, daemonset, etc...) when Longhorn volume is detached unexpectedly (e.g. during Kubernetes upgrade, Docker reboot, or network disconnect).
By deleting the pod, its controller restarts the pod and Kubernetes handles volume reattachment and remount.

If disabled, Longhorn will not delete the workload pod that is managed by a controller. You will have to manually restart the pod to reattach and remount the volume.

> **Note:** This setting doesn't apply to below cases.
> - The workload pods don't have a controller; Longhorn never deletes them.
> - The volumes used by workloads are RWX, because the Longhorn share manager, which provides the RWX NFS service, has its own resilience mechanism to ensure availability until the volume gets reattached without relying on the pod lifecycle to trigger volume reattachment. For details, see [here](../../nodes-and-volumes/volumes/rwx-volumes).

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

This option is useful if you want to scale the cluster but don't want to use storage on the new nodes, or if you want to [customize disks for Longhorn nodes](../../nodes-and-volumes/nodes/default-disk-and-node-config).

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

#### Default Longhorn Static StorageClass Name

> Default: `longhorn-static`

The `storageClassName` is for persistent volumes (PVs) and persistent volume claims (PVCs) when creating PV/PVC for an existing Longhorn volume. Notice that it's unnecessary for users to create the related StorageClass object in Kubernetes since the StorageClass would only be used as matching labels for PVC bounding purpose. By default 'longhorn-static'.

#### Default Replica Count

> Default: `3`

The default number of replicas when creating the volume from Longhorn UI. For Kubernetes, update the `numberOfReplicas` in the StorageClass

The recommended way of choosing the default replica count is: if you have three or more nodes for storage, use 3; otherwise use 2. Using a single replica on a single node cluster is also OK, but the high availability functionality wouldn't be available. You can still take snapshots/backups of the volume.

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

> Only available if `Upgrade Checker` is enabled.

#### Allow Collecting Longhorn Usage Metrics

> Default: `true`

Enabling this setting will allow Longhorn to provide valuable usage metrics to https://metrics.longhorn.io/.

This information will help us gain insights how Longhorn is being used, which will ultimately contribute to future improvements.

**Node Information collected from all cluster nodes includes:**
- Number of disks of each device type (HDD, SSD, NVMe, unknown).
  > This value may not be accurate for virtual machines.
- Number of disks for each Longhorn disk type (block, filesystem).
- Host kernel release.
- Host operating system (OS) distribution.
- Kubernetes node provider.

**Cluster Information collected from one of the cluster nodes includes:**
- Longhorn namespace UID.
- Number of Longhorn nodes.
- Number of volumes of each access mode (RWO, RWX, unknown).
- Number of volumes of each data engine (v1, v2).
- Number of volumes of each data locality type (disabled, best_effort, strict_local, unknown).
- Number of volumes of each frontend type (blockdev, iscsi).
- Average volume size in bytes.
- Average volume actual size in bytes.
- Average number of snapshots per volume.
- Average number of replicas per volume.
- Average Longhorn component CPU usage (instance manager, manager) in millicores.
- Average Longhorn component memory usage (instance manager, manager) in bytes.
- Longhorn settings:
  - Partially included:
    - Backup Target Type/Protocol (azblob, cifs, nfs, s3, none, unknown). This is from the Backup Target setting.
  - Included as true or false to indicate if this setting is configured:
    - Priority Class
    - Registry Secret
    - Snapshot Data Integrity CronJob
    - Storage Network
    - System Managed Components Node Selector
    - Taint Toleration
  - Included as it is:
    - Allow Recurring Job While Volume Is Detached
    - Allow Volume Creation With Degraded Availability
    - Automatically Clean up System Generated Snapshot
    - Automatically Clean up Outdated Snapshots of Recurring Backup Jobs
    - Automatically Delete Workload Pod when The Volume Is Detached Unexpectedly
    - Automatic Salvage
    - Backing Image Cleanup Wait Interval
    - Backing Image Recovery Wait Interval
    - Backup Compression Method
    - Backupstore Poll Interval
    - Backup Concurrent Limit
    - Concurrent Automatic Engine Upgrade Per Node Limit
    - Concurrent Backup Restore Per Node Limit
    - Concurrent Replica Rebuild Per Node Limit
    - CRD API Version
    - Create Default Disk Labeled Nodes
    - Default Data Locality
    - Default Replica Count
    - Disable Revision Counter
    - Disable Scheduling On Cordoned Node
    - Engine Replica Timeout
    - Failed Backup TTL
    - Fast Replica Rebuild Enabled
    - Guaranteed Instance Manager CPU
    - Kubernetes Cluster Autoscaler Enabled
    - Node Down Pod Deletion Policy
    - Node Drain Policy
    - Orphan Auto Deletion
    - Recurring Failed Jobs History Limit
    - Recurring Successful Jobs History Limit
    - Remove Snapshots During Filesystem Trim
    - Replica Auto Balance
    - Replica File Sync HTTP Client Timeout
    - Replica Replenishment Wait Interval
    - Replica Soft Anti Affinity
    - Replica Zone Soft Anti Affinity
    - Replica Disk Soft Anti Affinity
    - Restore Concurrent Limit
    - Restore Volume Recurring Jobs
    - Snapshot Data Integrity
    - Snapshot DataIntegrity Immediate Check After Snapshot Creation
    - Storage Minimal Available Percentage
    - Storage Over Provisioning Percentage
    - Storage Reserved Percentage For Default Disk
    - Support Bundle Failed History Limit
    - System Managed Pods Image Pull Policy

> The `Upgrade Checker` needs to be enabled to periodically send the collected data.

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

#### V1 Data Engine

> Default: `true`

Setting that allows you to enable the V1 Data Engine.

### V2 Data Engine (Preview Feature)
#### V2 Data Engine

> Default: `false`

Setting that allows you to enable the V2 Data Engine, which is based on the Storage Performance Development Kit (SPDK). The V2 Data Engine is a preview feature and should not be used in production environments. For more information, see [V2 Data Engine (Preview Feature)](../../v2-data-engine).

> **Warning**
>
> - DO NOT CHANGE THIS SETTING WITH ATTACHED VOLUMES. Longhorn will block this setting update when there are attached volumes.
>
> - When the V2 Data Engine is enabled, each instance-manager pod utilizes 1 CPU core. This high CPU usage is attributed to the spdk_tgt process running within each instance-manager pod. The spdk_tgt process is responsible for handling input/output (IO) operations and requires intensive polling. As a result, it consumes 100% of a dedicated CPU core to efficiently manage and process the IO requests, ensuring optimal performance and responsiveness for storage operations.

#### V2 Data Engine Hugepage Limit

> Default: `2048`

Maximum huge page size (in MiB) for the V2 Data Engine.

#### Guaranteed Instance Manager CPU for V2 Data Engine

> Default: `1250`

Number of millicpus on each node to be reserved for each instance manager pod when the V2 Data Engine is enabled. By default, the Storage Performance Development Kit (SPDK) target daemon within each instance manager pod uses 1 CPU core. Configuring a minimum CPU usage value is essential for maintaining engine and replica stability, especially during periods of high node workload.

> **Warning:**
>  - Specifying a value of 0 disables CPU requests for instance manager pods. You must specify an integer between 1000 and 8000. 
>  - This is a global setting. Modifying the value triggers an automatic restart of the Instance Manager pods. However, V2 Instance Manager pods that use this setting are restarted only when no instances are running.

#### Offline Replica Rebuilding

> Default: `enabled`

Setting that allows rebuilding of offline replicas for volumes using the V2 Data Engine. For more information, see [Automatic Offline Replica Rebuilding](../../v2-data-engine/features/automatic-offline-replica-rebuilding).

Here are the available options:
- `enabled`
- `disabled`

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

#### Snapshot Maximum Count

> Default: `250`

Maximum snapshot count for a volume. The value should be between 2 to 250.

### Orphan

#### Orphaned Data Automatic Deletion
> Default: `false`

This setting allows Longhorn to automatically delete the `orphan` resource and its orphaned data like volume replica.

### Backups

#### Allow Recurring Job While Volume Is Detached

> Default: `false`

If this setting is enabled, Longhorn automatically attaches the volume and takes snapshot/backup when it is the time to do recurring snapshot/backup.

> **Note:** During the time the volume was attached automatically, the volume is not ready for the workload. The workload will have to wait until the recurring job finishes.

#### Backup Target

> Examples:  
> `s3://backupbucket@us-east-1/backupstore`  
> `nfs://longhorn-test-nfs-svc.default:/opt/backupstore`  
> `nfs://longhorn-test-nfs-svc.default:/opt/backupstore?nfsOptions=soft,timeo=330,retrans=3`  

Endpoint used to access a backupstore.   Longhorn supports AWS S3, Azure, GCP, CIFS and NFS.  See [Setting a Backup Target](../../snapshots-and-backups/backup-and-restore/set-backup-target) for details.

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

#### Backup Compression Method

> Default: `lz4`

This setting allows users to specify backup compression method.

- `none`: Disable the compression method. Suitable for multimedia data such as encoded images and videos.

- `lz4`: Fast compression method. Suitable for flat files.

- `gzip`: A bit of higher compression ratio but relatively slow.

#### Backup Concurrent Limit Per Backup

> Default: `2`

This setting controls how many worker threads per backup concurrently.

#### Restore Concurrent Limit Per Backup

> Default: `2`

This setting controls how many worker threads per restore concurrently.

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

When this setting is un-checked, Longhorn Manager will forbid scheduling on nodes with existing healthy replicas of the same volume.

> **Note:**
>   - This setting is superseded if replicas are forbidden to share a zone by the Replica Zone Level Anti-Affinity setting.

#### Replica Zone Level Soft Anti-Affinity

> Default: `true`

When this setting is checked, the Longhorn Manager will allow scheduling new replicas of a volume to the nodes in the same zone as existing healthy replicas.

When this setting is un-checked, Longhorn Manager will forbid scheduling new replicas of a volume to the nodes in the same zone as existing healthy replicas.

> **Note:**
>   - Nodes that don't belong to any zone will be treated as if they belong to the same zone.
>   - Longhorn relies on label `topology.kubernetes.io/zone=<Zone name of the node>` in the Kubernetes node object to identify the zone.

#### Replica Disk Level Soft Anti-Affinity

> Default: `true`

When this setting is checked, the Longhorn Manager will allow scheduling new replicas of a volume to the same disks as existing healthy replicas.

When this setting is un-checked, Longhorn Manager will forbid scheduling new replicas of a volume to the same disks as existing healthy replicas.

> **Note:**
>   - Even if the setting is "true" and disk sharing is allowed, Longhorn will seek to use a different disk if possible, even if on the same node.
>   - This setting is superseded if replicas are forbidden to share a zone or a node by either of the other Soft Anti-Affinity settings.

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

See [Multiple Disks Support](../../nodes-and-volumes/nodes/multidisk/#configuration) for details.

#### Storage Over Provisioning Percentage

> Default: `100`

The over-provisioning percentage defines the amount of storage that can be allocated relative to the hard drive's capacity.

By increase this setting, the Longhorn Manager will allow scheduling new replicas only after the amount of disk space has been added to the used disk space (**storage scheduled**), and the used disk space (**Storage Maximum** - **Storage Reserved**) is not over the over-provisioning percentage of the actual usable disk capacity.

It's worth noting that a volume replica may require more storage space than the volume's actual size, as the snapshots also require storage. You can regain space by deleting unnecessary snapshots.

#### Storage Reserved Percentage For Default Disk

> Default: `30`

The reserved percentage specifies the percentage of disk space that will not be allocated to the default disk on each new Longhorn node.

This setting only affects the default disk of a new adding node or nodes when installing Longhorn.

#### Allow Empty Node Selector Volume

> Default: `true`

This setting allows replica of the volume without node selector to be scheduled on node with tags.

#### Allow Empty Disk Selector Volume

> Default: `true`

This setting allows replica of the volume without disk selector to be scheduled on disk with tags.

### Danger Zone

Starting with Longhorn v1.6.0, Longhorn allows you to modify the [Danger Zone settings](https://longhorn.io/docs/1.6.0/references/settings/#danger-zone) without the need to wait for all volumes to become detached. Your preferred settings are immediately applied in the following scenarios:

- No attached volumes: When no volumes are attached before the settings are configured, the setting changes are immediately applied.
- Engine image upgrade (live upgrade): During a live upgrade, which involves creating a new Instance Manager pod, the setting changes are immediately applied to the new pod.

Settings are synchronized hourly. When all volumes are detached, the settings in the following table are immediately applied and the system-managed components (for example, Instance Manager, CSI Driver, and Engine images) are restarted. If you do not detach all volumes before the settings are synchronized, the settings are not applied and you must reconfigure the same settings after detaching the remaining volumes.

  | Setting | Additional Information| Affected Components |
  | --- | --- | --- |
  | [Kubernetes Taint Toleration](#kubernetes-taint-toleration)| [Taints and Tolerations](../../advanced-resources/deploy/taint-toleration/) | System-managed components |
  | [Priority Class](#priority-class) | [Priority Class](../../advanced-resources/deploy/priority-class/) | System-managed components |
  | [System Managed Components Node Selector](#system-managed-components-node-selector) | [Node Selector](../../advanced-resources/deploy/node-selector/) | System-managed components |
  | [Storage Network](#storage-network) | [Storage Network](../../advanced-resources/deploy/storage-network/) | Instance Manager and Backing Image components |
  | [V1 Data Engine](#v1-data-engine) || Instance Manager component |
  | [V2 Data Engine](#v2-data-engine) | [V2 Data Engine (Preview Feature)](../../v2-data-engine/) | Instance Manager component |
  | [Guaranteed Instance Manager CPU](#guaranteed-instance-manager-cpu) || Instance Manager component |
  | [Guaranteed Instance Manager CPU for V2 Data Engine](#guaranteed-instance-manager-cpu-for-v2-data-engine) || Instance Manager component |

For V1 and V2 Data Engine settings, you can disable the Data Engines only when all associated volumes are detached. For example, you can disable the V2 Data Engine only when all V2 volumes are detached (even when V1 volumes are still attached).

#### Concurrent Replica Rebuild Per Node Limit

> Default: `5`

This setting controls how many replicas on a node can be rebuilt simultaneously.

Typically, Longhorn can block the replica starting once the current rebuilding count on a node exceeds the limit. But when the value is 0, it means disabling the replica rebuilding.

> **WARNING:**
>  - The old setting "Disable Replica Rebuild" is replaced by this setting.
>  - Different from relying on replica starting delay to limit the concurrent rebuilding, if the rebuilding is disabled, replica object replenishment will be directly skipped.
>  - When the value is 0, the eviction and data locality feature won't work. But this shouldn't have any impact to any current replica rebuild and backup restore.


#### Kubernetes Taint Toleration

> Example: `nodetype=storage:NoSchedule`

If you want to dedicate nodes to just store Longhorn replicas and reject other general workloads, you can set tolerations for **all** Longhorn components and add taints to the nodes dedicated for storage.

Longhorn system contains user deployed components (e.g, Longhorn manager, Longhorn driver, Longhorn UI) and system managed components (e.g, instance manager, engine image, CSI driver, etc.)
This setting only sets taint tolerations for system managed components.
Depending on how you deployed Longhorn, you need to set taint tolerations for user deployed components in Helm chart or deployment YAML file.

To apply the modified toleration setting immediately, ensure that all Longhorn volumes are detached. When volumes are in use, Longhorn components are not restarted, and you need to reconfigure the settings after detaching the remaining volumes; otherwise, you can wait for the setting change to be reconciled in an hour.
We recommend setting tolerations during Longhorn deployment because the Longhorn system cannot be operated during the update.

Multiple tolerations can be set here, and these tolerations are separated by semicolon. For example:
* `key1=value1:NoSchedule; key2:NoExecute`
* `:` this toleration tolerates everything because an empty key with operator `Exists` matches all keys, values and effects
* `key1=value1:`  this toleration has empty effect. It matches all effects with key `key1`
  See [Taint Toleration](../../advanced-resources/deploy/taint-toleration) for details.

#### Priority Class

> Default: `longhorn-critical`

By default, Longhorn workloads run with the same priority as other pods in the cluster, meaning in cases of node pressure, such as a node running out of memory, Longhorn workloads will be at the same priority as other Pods for eviction.

The Priority Class setting will specify a Priority Class for the Longhorn workloads to run as. This can be used to set the priority for Longhorn workloads higher so that they will not be the first to be evicted when a node is under pressure.

Longhorn system contains user deployed components (e.g, Longhorn manager, Longhorn driver, Longhorn UI) and system managed components (e.g, instance manager, engine image, CSI driver, etc.).

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
To apply a setting immediately, ensure that all Longhorn volumes are detached. When volumes are in use, Longhorn components are not restarted, and you need to reconfigure the settings after detaching the remaining volumes; otherwise, you can wait for the setting change to be reconciled in an hour.
Don't operate the Longhorn system while node selector settings are updated and Longhorn components are being restarted.

#### Kubernetes Cluster Autoscaler Enabled (Experimental)

> Default: `false`

Setting the Kubernetes Cluster Autoscaler Enabled to `true` allows Longhorn to unblock the Kubernetes Cluster Autoscaler scaling.

See [Kubernetes Cluster Autoscaler Support](../../high-availability/k8s-cluster-autoscaler) for details.

> **Warning:** Replica rebuilding could be expensive because nodes with reusable replicas could get removed by the Kubernetes Cluster Autoscaler.

#### Storage Network

> Example: `kube-system/demo-192-168-0-0`

The storage network uses Multus NetworkAttachmentDefinition to segregate the in-cluster data traffic from the default Kubernetes cluster network.

> **Warning:** This setting should change after all Longhorn volumes are detached because some pods that run Longhorn system components are recreated to apply the setting. When all volumes are detached, Longhorn attempts to restart all Instance Manager and Backing Image Manager pods immediately. When volumes are in use, Longhorn components are not restarted, and you need to reconfigure the settings after detaching the remaining volumes; otherwise, you can wait for the setting change to be reconciled in an hour.

See [Storage Network](../../advanced-resources/deploy/storage-network) for details.

#### Remove Snapshots During Filesystem Trim

> Example: `false`

This setting allows Longhorn filesystem trim feature to automatically mark the latest snapshot and its ancestors as removed and stops at the snapshot containing multiple children.

Since Longhorn filesystem trim feature can be applied to the volume head and the followed continuous removed or system snapshots only.

Notice that trying to trim a removed files from a valid snapshot will do nothing but the filesystem will discard this kind of in-memory trimmable file info. Later on if you mark the snapshot as removed and want to retry the trim, you may need to unmount and remount the filesystem so that the filesystem can recollect the trimmable file info.

See [Trim Filesystem](../../nodes-and-volumes/volumes/trim-filesystem) for details.

#### Guaranteed Instance Manager CPU

> Default: `12`

Percentage of the total allocatable CPU resources on each node to be reserved for each instance manager pod when the V1 Data Engine is enabled. For example, Longhorn reserves 10% of the total allocatable CPU resources if you specify a value of 10. This setting is essential for maintaining engine and replica stability, especially during periods of high node workload.

In order to prevent an unexpected volume instance (engine/replica) crash as well as guarantee a relatively acceptable I/O performance, you can use the following formula to calculate a value for this setting:

    Guaranteed Instance Manager CPU = The estimated max Longhorn volume engine and replica count on a node * 0.1 / The total allocatable CPUs on the node * 100.

The result of above calculation doesn't mean that's the maximum CPU resources the Longhorn workloads require. To fully exploit the Longhorn volume I/O performance, you can allocate/guarantee more CPU resources via this setting.

If it's hard to estimate the usage now, you can leave it with the default value, which is 12%. Then you can tune it when there is no running workload using Longhorn volumes.

> **Warning:**
>  - Value 0 means removing the CPU requests from spec of instance manager pods.
>  - Considering the possible number of new instance manager pods in a further system upgrade, this integer value ranges from 0 to 40.
>  - One more set of instance manager pods may need to be deployed when the Longhorn system is upgraded. If current available CPUs of the nodes are not enough for the new instance manager pods, you need to detach the volumes using the oldest instance manager pods so that Longhorn can clean up the old pods automatically and release the CPU resources. And the new pods with the latest instance manager image will be launched then.
>  - This global setting will be ignored for a node if the field "InstanceManagerCPURequest" on the node is set.
>  - After the setting is changed, the V1 Instance Manager pods that use this setting are automatically restarted when no instances are running.

#### Disable Snapshot Purge

> Default: `false`

When set to true, temporarily prevent all attempts to purge volume snapshots.

Longhorn typically purges snapshots during replica rebuilding and user-initiated snapshot deletion. While purging,
Longhorn coalesces unnecessary snapshots into their newer counterparts, freeing space consumed by historical data.

Allowing snapshot purging during normal operations is ideal, but this process temporarily consumes additional disk
space. If insufficient disk space prevents the process from continuing, consider temporarily disabling purging while
data is moved to other disks.
