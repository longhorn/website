---
title: Settings
weight: 1
---

- [Value Format Types by Supported Data Engines](#value-format-types-by-supported-data-engines)
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
  - [Upgrade Responder URL](#upgrade-responder-url)
  - [Latest Longhorn Version](#latest-longhorn-version)
  - [Allow Collecting Longhorn Usage Metrics](#allow-collecting-longhorn-usage-metrics)
  - [Pod Deletion Policy When Node is Down](#pod-deletion-policy-when-node-is-down)
  - [Registry Secret](#registry-secret)
  - [Replica Replenishment Wait Interval](#replica-replenishment-wait-interval)
  - [System Managed Pod Image Pull Policy](#system-managed-pod-image-pull-policy)
  - [Backing Image Cleanup Wait Interval](#backing-image-cleanup-wait-interval)
  - [Backing Image Recovery Wait Interval](#backing-image-recovery-wait-interval)
  - [Default Min Number Of Backing Image Copies](#default-min-number-of-backing-image-copies)
  - [Engine Replica Timeout](#engine-replica-timeout)
  - [Support Bundle Manager Image](#support-bundle-manager-image)
  - [Support Bundle Failed History Limit](#support-bundle-failed-history-limit)
  - [Support Bundle Node Collection Timeout](#support-bundle-node-collection-timeout)
  - [Fast Replica Rebuild Enabled](#fast-replica-rebuild-enabled)
  - [Timeout of HTTP Client to Replica File Sync Server](#timeout-of-http-client-to-replica-file-sync-server)
  - [Long gRPC Timeout](#long-grpc-timeout)
  - [Offline Replica Rebuilding](#offline-replica-rebuilding)
  - [RWX Volume Fast Failover (Experimental)](#rwx-volume-fast-failover-experimental)
  - [Log Level](#log-level)
  - [Log Path](#log-path)
  - [Data Engine Log Level](#data-engine-log-level)
  - [Data Engine Log Flags](#data-engine-log-flags)
  - [Replica Rebuilding Bandwidth Limit](#replica-rebuilding-bandwidth-limit)
- [Snapshot](#snapshot)
  - [Snapshot Data Integrity](#snapshot-data-integrity)
  - [Immediate Snapshot Data Integrity Check After Creating a Snapshot](#immediate-snapshot-data-integrity-check-after-creating-a-snapshot)
  - [Snapshot Data Integrity Check CronJob](#snapshot-data-integrity-check-cronjob)
  - [Snapshot Maximum Count](#snapshot-maximum-count)
  - [Freeze Filesystem For Snapshot](#freeze-filesystem-for-snapshot)
- [Orphan](#orphan)
  - [Orphaned Resource Automatic Deletion](#orphaned-resource-automatic-deletion)
  - [Orphaned Resource Automatic Deletion Grace Period](#orphaned-resource-automatic-deletion-grace-period)
- [Backups](#backups)
  - [Allow Recurring Job While Volume Is Detached](#allow-recurring-job-while-volume-is-detached)
  - [Backup Execution Timeout](#backup-execution-timeout)
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
  - [Replica Auto Balance Disk Pressure Threshold (%)](#replica-auto-balance-disk-pressure-threshold-)
  - [Storage Minimal Available Percentage](#storage-minimal-available-percentage)
  - [Storage Over Provisioning Percentage](#storage-over-provisioning-percentage)
  - [Storage Reserved Percentage For Default Disk](#storage-reserved-percentage-for-default-disk)
  - [Allow Empty Node Selector Volume](#allow-empty-node-selector-volume)
  - [Allow Empty Disk Selector Volume](#allow-empty-disk-selector-volume)
- [Danger Zone](#danger-zone)
  - [Concurrent Replica Rebuild Per Node Limit](#concurrent-replica-rebuild-per-node-limit)
  - [Concurrent Backing Image Replenish Per Node Limit](#concurrent-backing-image-replenish-per-node-limit)
  - [Kubernetes Taint Toleration](#kubernetes-taint-toleration)
  - [Priority Class](#priority-class)
  - [System Managed Components Node Selector](#system-managed-components-node-selector)
  - [Kubernetes Cluster Autoscaler Enabled (Experimental)](#kubernetes-cluster-autoscaler-enabled-experimental)
  - [Storage Network](#storage-network)
  - [Storage Network For RWX Volume Enabled](#storage-network-for-rwx-volume-enabled)
  - [Remove Snapshots During Filesystem Trim](#remove-snapshots-during-filesystem-trim)
  - [Guaranteed Instance Manager CPU](#guaranteed-instance-manager-cpu)
  - [Disable Snapshot Purge](#disable-snapshot-purge)
  - [Auto Cleanup Snapshot When Delete Backup](#auto-cleanup-snapshot-when-delete-backup)
  - [Auto Cleanup Snapshot After On-Demand Backup Completed](#auto-cleanup-snapshot-after-on-demand-backup-completed)
  - [Instance Manager Pod Liveness Probe Timeout](#instance-manager-pod-liveness-probe-timeout)
  - [V1 Data Engine](#v1-data-engine)
  - [V2 Data Engine](#v2-data-engine)
  - [Data Engine CPU Mask](#data-engine-cpu-mask)
  - [Data Engine Hugepage Limit](#data-engine-hugepage-limit)

---

### Value Format Types by Supported Data Engines

Each setting supports only one of the following formats, depending on its definition. The supported format determines which Data Engines can be configured and whether their values can differ.

- Single value for all supported Data Engines
  - Format: Non-JSON string (e.g., `1024`)
  - The value applies to all supported Data Engines and must be the same across them.
  - Data-engine-specific values are not allowed.
- Data-engine-specific values for V1 and V2 Data Engines
  - Format: JSON object (e.g., `{"v1": "value1", "v2": "value2"}`)
  - Allows specifying different values for V1 and V2 Data Engines.
- Data-engine-specific values for V1 Data Engine only
  - Format: JSON object with `v1` key only (e.g., `{"v1": "value1"}`)
  - Only the V1 Data Engine can be configured; the V2 Data Engine is not affected.
- Data-engine-specific values for V2 Data Engine only
  - Format: JSON object with `v2` key only (e.g., `{"v2": "value1"}`)
  - Only the V2 Data Engine can be configured; the V1 Data Engine is not affected.

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
> - Workload pods with *cluster network* RWX volumes. The setting does not apply to such pods because the Longhorn Share Manager, which provides the RWX NFS service, has its own resilience mechanism. This mechanism ensures availability until the volume is reattached without relying on the pod lifecycle to trigger volume reattachment. The setting does apply, however, to workload pods with *storage network* RWX volumes. For more information, see [ReadWriteMany (RWX) Volume](../../nodes-and-volumes/volumes/rwx-volumes) and [Storage Network](../../advanced-resources/deploy/storage-network#limitation).

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

The `storageClassName` is for persistent volumes (PVs) and persistent volume claims (PVCs) when creating PV/PVC for an existing Longhorn volume. Notice that it's unnecessary for users to create the related StorageClass object in Kubernetes since the StorageClass would only be used as matching labels for PVC bounding purposes.  The "storageClassName" needs to be an existing StorageClass. Only the StorageClass named `longhorn-static` will be created if it does not exist. By default 'longhorn-static'.

#### Default Replica Count

> Default: `{"v1":"3","v2":"3"}`

The default number of replicas when creating the volume from Longhorn UI. For Kubernetes, update the `numberOfReplicas` in the StorageClass

The recommended way of choosing the default replica count is: if you have three or more nodes for storage, use 3; otherwise use 2. Using a single replica on a single node cluster is also OK, but the high availability functionality wouldn't be available. You can still take snapshots/backups of the volume.

#### Deleting Confirmation Flag

> Default: `false`

This flag is designed to prevent Longhorn from being accidentally uninstalled which will lead to data loss.

- Set this flag to **true** to allow Longhorn uninstallation.
- If this flag **false**, Longhorn uninstallation job will fail.

#### Disable Revision Counter

> Default: `{"v1":"true"}`

Allows engine controller and engine replica to disable revision counter file update for every data write. This improves the data path performance. See [Revision Counter](../../advanced-resources/deploy/revision_counter) for details.

#### Enable Upgrade Checker

> Default: `true`

Upgrade Checker will check for a new Longhorn version periodically. When there is a new version available, it will notify the user in the Longhorn UI.

#### Upgrade Responder URL

> Default: `https://longhorn-upgrade-responder.rancher.io/v1/checkupgrade`

The Upgrade Responder sends a notification whenever a new Longhorn version that you can upgrade to becomes available.

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
- Host system architecture.
- Host kernel release.
- Host operating system (OS) distribution.
- Kubernetes node provider.

**Cluster Information collected from one of the cluster nodes includes:**

- Longhorn namespace UID.
- Number of Longhorn nodes.
- Number of volumes of each access mode (RWO, RWX, unknown).
- Number of volumes of each data engine (v1, v2).
- Number of volumes of each data locality type (disabled, best_effort, strict_local, unknown).
- Number of volumes that are encrypted or unencrypted.
- Number of volumes of each frontend type (blockdev, iscsi).
- Number of replicas.
- Number of snapshots.
- Number of backing images.
- Number of orphans.
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
    - Storage Network For RWX Volume Enabled
    - Storage Over Provisioning Percentage
    - Storage Reserved Percentage For Default Disk
    - Support Bundle Failed History Limit
    - Support Bundle Node Collection Timeout
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

#### Default Min Number Of Backing Image Copies
> Default: `1`

The default minimum number of backing image copies Longhorn maintains.

#### Engine Replica Timeout

> Default: `{"v1":"8","v2":"8"}`

The time in seconds a v1 engine will wait for a response from a replica before marking it as failed. Values between 8
and 30 are allowed. The engine replica timeout is only in effect while there are I/O requests outstanding.

This setting only applies to additional replicas. A V1 engine marks the last active replica as failed only after twice
the configured number of seconds (timeout value x 2) have passed. This behavior is intended to balance volume
responsiveness with volume availability.

- The engine can quickly (after the configured timeout) ignore individual replicas that become unresponsive in favor of
  other available ones. This ensures future I/O will not be held up.
- The engine waits on the last replica (until twice the configured timeout) to prevent unnecessarily crashing as a
  result of having no available backends.

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

#### Support Bundle Node Collection Timeout

> Default: `30`

Number of minutes Longhorn allows for collection of node information and node logs for the support bundle.

If the collection process is not completed within the allotted time, Longhorn continues generating the support bundle without the uncollected node data.

#### Fast Replica Rebuild Enabled

> Default: `{"v1":"true","v2":"true"}`

The setting enables fast replica rebuilding feature. It relies on the checksums of snapshot disk files, so setting the snapshot-data-integrity to **enable** or **fast-check** is a prerequisite.

#### Timeout of HTTP Client to Replica File Sync Server

> Default: `30`

The value in seconds specifies the timeout of the HTTP client to the replica's file sync server used for replica rebuilding, volume cloning, snapshot cloning, etc.

#### Long gRPC Timeout

> Default: `86400`

Number of seconds that Longhorn allows for the completion of replica rebuilding and snapshot cloning operations.

#### Offline Replica Rebuilding

> Default: `false`

Controls whether Longhorn automatically rebuilds degraded replicas while the volume is detached. This setting only takes effect if the volume-level setting is set to `ignored` or `enabled`. Available options:

- **true**: Enables offline replica rebuilding for all detached volumes (unless overridden at the volume level).
- **false**: Disables offline replica rebuilding globally (unless overridden at the volume level).

> **Note:** Offline rebuilding occurs only when a volume is detached. Volumes in a faulted state will not trigger offline rebuilding.

This setting allows Longhorn to automatically rebuild replicas for detached volumes when needed.

#### RWX Volume Fast Failover (Experimental)

> Default: `false`

Enable improved ReadWriteMany volume HA by shortening the time it takes to recover from a node failure.

#### Log Level

> Default: `Log Level`

The log level Panic, Fatal, Error, Warn, Info, Debug, Trace used in longhorn manager. By default Info.

#### Log Path

> Default: `/var/lib/longhorn/logs/`

Specifies the directory on the host where Longhorn stores log files for the instance manager pod. Currently, it is only used for instance manager pods in the v2 data engine.

#### Data Engine Log Level

> Default: `{"v2":"Notice"}`

Applies only to the V2 Data Engine. Specifies the log level for the Storage Performance Development Kit (SPDK) target daemon. Supported values: `Error`, `Warning`, `Notice`, `Info`, and `Debug`.

#### Data Engine Log Flags

> Default: `{"v2":""}`

Applies only to the V2 Data Engine. Specifies the log flags for the Storage Performance Development Kit (SPDK) target daemon.

#### Replica Rebuilding Bandwidth Limit

> Default: `{"v2":"0"}`

Applies only to the V2 Data Engine. Specifies the default write bandwidth limit, in megabytes per second (MB/s), for volume replica rebuilding.

### Snapshot

#### Snapshot Data Integrity

> Default: `fast-check`

This setting allows users to enable or disable snapshot hashing and data integrity checking. Available options are:

- **disabled**: Disable snapshot disk file hashing and data integrity checking.
- **enabled**: Enables periodic snapshot disk file hashing and data integrity checking. To detect the filesystem-unaware corruption caused by bit rot or other issues in snapshot disk files, Longhorn system periodically hashes files and finds corrupted ones. Hence, the system performance will be impacted during the periodical checking.
- **fast-check**: Enable snapshot disk file hashing and fast data integrity checking. Longhorn system only hashes snapshot disk files if their are not hashed or the modification time are changed. In this mode, filesystem-unaware corruption cannot be detected, but the impact on system performance can be minimized.

#### Immediate Snapshot Data Integrity Check After Creating a Snapshot

> Default: `{"v1":"false","v2":"false"}`

Hashing snapshot disk files impacts the performance of the system. The immediate snapshot hashing and checking can be disabled to minimize the impact after creating a snapshot.

#### Snapshot Data Integrity Check CronJob

> Default: `0 0 */7 * *`

Unix-cron string format. The setting specifies when Longhorn checks the data integrity of snapshot disk files.
> **Warning**
> Hashing snapshot disk files impacts the performance of the system. It is recommended to run data integrity checks during off-peak times and to reduce the frequency of checks.

#### Snapshot Maximum Count

> Default: `250`

Maximum snapshot count for a volume. The value should be between 2 to 250.

#### Freeze Filesystem For Snapshot

> Default: `{"v2":"false"}`

This setting only applies to volumes with the Kubernetes volume mode `Filesystem`. When enabled, Longhorn freezes the
volume's filesystem immediately before creating a user-initiated snapshot. When disabled or when the Kubernetes volume
mode is `Block`, Longhorn instead attempts a system sync before creating a user-initiated snapshot.

Snapshots created when this setting is enabled are more likely to be consistent because the filesystem is in a
consistent state at the moment of creation. However, under very heavy I/O, freezing the filesystem may take a
significant amount of time and may cause workload activity to pause.

When this setting is disabled, all data is flushed to disk just before the snapshot is created, but Longhorn cannot
completely block write attempts during the brief interval between the system sync and snapshot creation. I/O is not
paused during the system sync, so workloads likely do not notice that a snapshot is being created.

The default option for this setting is `false` because kernels with version `v5.17` or earlier may not respond correctly
when a volume crashes while a freeze is ongoing. This is not likely to happen but if it does, an affected kernel will
not allow you to unmount the filesystem or stop processes using the filesystem without rebooting the node. Only enable
this setting if you plan to use kernels with version `5.17` or later, and ext4 or XFS filesystems.

You can override this setting (using the field `freezeFilesystemForSnapshot`) for specific volumes through the Longhorn
UI, a StorageClass, or direct changes to an existing volume. `freezeFilesystemForSnapshot` accepts the following values:

### Orphan

#### Orphaned Resource Automatic Deletion

> Example: `replica-data;instance`

This setting allows Longhorn to automatically delete orphan resources and their corresponding orphaned resources. Orphan resources located on nodes that are in down or unknown state will not be cleaned up automatically.

List the enabled resource types in a semicolon-separated list. Available items are:

- `replica-data`: replica data store
- `instance`: engine and replica runtime instance

#### Orphaned Resource Automatic Deletion Grace Period

> Default: `300`

Specifies the wait time, in seconds, before Longhorn automatically deletes an orphaned Custom Resource (CR) and its associated resources.

> **Note:** If a user manually deletes an orphaned CR, the deletion occurs immediately and does not respect this grace period.

### Backups

#### Allow Recurring Job While Volume Is Detached

> Default: `false`

If this setting is enabled, Longhorn automatically attaches the volume and takes snapshot/backup when it is the time to do recurring snapshot/backup.

> **Note:** During the time the volume was attached automatically, the volume is not ready for the workload. The workload will have to wait until the recurring job finishes.

#### Backup Execution Timeout

> Default: `1`

Number of minutes that Longhorn allows for the backup execution.

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

#### Replica Auto Balance Disk Pressure Threshold (%)

> Default: `90`

Percentage of currently used storage that triggers automatic replica rebalancing.

When the threshold is reached, Longhorn automatically rebuilds replicas that are under disk pressure on another disk within the same node.

To disable this setting, set the value to **0**.

This setting takes effect only when the following conditions are met:

- [Replica Auto Balance](#replica-auto-balance) is set to **best-effort**. To disable this setting (disk pressure threshold) when replica auto-balance is set to best-effort, set the value of this setting to **0**.
- At least one other disk on the node has sufficient available space.

This setting is not affected by [Replica Node Level Soft Anti-Affinity](#replica-node-level-soft-anti-affinity), which can prevent Longhorn from rebuilding a replica on the same node. Regardless of that setting's value, this setting still allows Longhorn to attempt replica rebuilding on a different disk on the same node for migration purposes.

#### Storage Minimal Available Percentage

> Default: `25`

This setting controls the minimum free space that must remain on a disk, based on its **Storage Maximum**, before Longhorn can schedule a new replica.

By default, Longhorn ensures that at least **25%** of the disk's total capacity remains free. If adding a replica would reduce the available space below this limit, the disk is temporarily marked as unavailable for scheduling until enough space is freed.

This helps protect your disks from becoming too full, which can cause performance issues or storage failures. Keeping a buffer of free space helps to keep the system stable and ensures there is room for unexpected storage needs.

See [Multiple Disks Support](../../nodes-and-volumes/nodes/multidisk/#configuration) for details.

#### Storage Over Provisioning Percentage

> Default: `100`

The over-provisioning percentage defines the amount of storage that can be allocated relative to the hard drive's capacity.

Adjusting this setting allows Longhorn Manager to schedule new replicas on a disk as long as the combined size of all replicas stays within the permitted over-provisioning percentage of the usable disk space. The usable disk space is calculated as **Storage Maximum** minus **Storage Reserved**.

Note that replicas may consume more space than the volume’s nominal size due to snapshot data. To reclaim disk space, you can delete snapshots that are no longer needed.

> **Example**
> 
> Suppose a disk has a Storage Maximum of 100 GiB and Storage Reserved of 10 GiB, resulting in 90 GiB of usable capacity.
> 
> If the Storage Over-Provisioning Percentage is set to 200%, the maximum allowed Storage Scheduled is 180 GiB (200% of 90 GiB).
> 
> This means Longhorn Manager can continue scheduling replicas to this disk until the total scheduled size reaches 180 GiB, even though the actual usable space is only 90 GiB.

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

Settings are synchronized hourly. When all volumes are detached, the settings in the following table are immediately applied and the system-managed components (for example, Instance Manager, CSI Driver, and engine images) are restarted.

If you do not detach all volumes before the settings are synchronized, the settings are not applied and you must reconfigure the same settings after detaching the remaining volumes. You can view the list of unapplied settings in the **Danger Zone** section of the Longhorn UI, or run the following CLI command to check the value of the field `APPLIED`.

  ```shell
  ~# kubectl -n longhorn-system get setting priority-class
  NAME             VALUE               APPLIED   AGE
  priority-class   longhorn-critical   true      3h26m
  ```

  | Setting | Additional Information| Affected Components |
  | --- | --- | --- |
  | [Kubernetes Taint Toleration](#kubernetes-taint-toleration)| [Taints and Tolerations](../../advanced-resources/deploy/taint-toleration/) | System-managed components |
  | [Priority Class](#priority-class) | [Priority Class](../../advanced-resources/deploy/priority-class/) | System-managed components |
  | [System Managed Components Node Selector](#system-managed-components-node-selector) | [Node Selector](../../advanced-resources/deploy/node-selector/) | System-managed components |
  | [Storage Network](#storage-network) | [Storage Network](../../advanced-resources/deploy/storage-network/) | Instance Manager and Backing Image components |
  | [V1 Data Engine](#v1-data-engine) || Instance Manager component |
  | [V2 Data Engine](#v2-data-engine) | [V2 Data Engine (Experimental)](../../v2-data-engine/) | Instance Manager component |
  | [Guaranteed Instance Manager CPU](#guaranteed-instance-manager-cpu) || Instance Manager component |

For V1 and V2 Data Engine settings, you can disable the Data Engines only when all associated volumes are detached. For example, you can disable the V2 Data Engine only when all V2 volumes are detached (even when V1 volumes are still attached).

#### Concurrent Replica Rebuild Per Node Limit

> Default: `5`

This setting controls how many replicas on a node can be rebuilt simultaneously.

Typically, Longhorn can block the replica starting once the current rebuilding count on a node exceeds the limit. But when the value is 0, it means disabling the replica rebuilding.

> **WARNING:**
>  - The old setting "Disable Replica Rebuild" is replaced by this setting.
>  - Different from relying on replica starting delay to limit the concurrent rebuilding, if the rebuilding is disabled, replica object replenishment will be directly skipped.
>  - When the value is 0, the eviction and data locality feature won't work. But this shouldn't have any impact to any current replica rebuild and backup restore.

#### Concurrent Backing Image Replenish Per Node Limit

> Default: `5`

This setting controls how many backing image copies on a node can be replenished simultaneously.

Typically, Longhorn can block the backing image copy starting once the current replenishing count on a node exceeds the limit. But when the value is 0, it means disabling the backing image replenish.

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

By default, the this setting applies only to RWO (Read-Write-Once) volumes. For RWX (Read-Write-Many) volumes, see [Storage Network for RWX Volume Enabled](#storage-network-for-rwx-volume-enabled) setting.

> **Warning:** This setting should change after all Longhorn volumes are detached because some pods that run Longhorn system components are recreated to apply the setting. When all volumes are detached, Longhorn attempts to restart all Instance Manager and Backing Image Manager pods immediately. When volumes are in use, Longhorn components are not restarted, and you need to reconfigure the settings after detaching the remaining volumes; otherwise, you can wait for the setting change to be reconciled in an hour.

See [Storage Network](../../advanced-resources/deploy/storage-network) for details.

#### Storage Network For RWX Volume Enabled

> Default: `false`

This setting allows Longhorn to use the storage network for RWX volumes.

> **Warning:**
> This setting should change after all Longhorn RWX volumes are detached because some pods that run Longhorn components are recreated to apply the setting. When all RWX volumes are detached, Longhorn attempts to restart all CSI plugin pods immediately. When volumes are in use, pods that run Longhorn components are not restarted, so the settings must be reconfigured after the remaining volumes are detached. If you are unable to manually reconfigure the settings, you can opt to wait because settings are synchronized hourly.
>
> The RWX volumes are mounted with the storage network within the CSI plugin pod container network namespace. As a result, restarting the CSI plugin pod may lead to unresponsive RWX volume mounts. When this occurs, you must restart the workload pod to re-establish the mount connection. Alternatively, you can enable the [Automatically Delete Workload Pod when The Volume Is Detached Unexpectedly](#automatically-delete-workload-pod-when-the-volume-is-detached-unexpectedly) setting.

For more information, see [Storage Network](../../advanced-resources/deploy/storage-network).

#### Remove Snapshots During Filesystem Trim

> Example: `false`

This setting allows Longhorn filesystem trim feature to automatically mark the latest snapshot and its ancestors as removed and stops at the snapshot containing multiple children.

Since Longhorn filesystem trim feature can be applied to the volume head and the followed continuous removed or system snapshots only.

Notice that trying to trim a removed files from a valid snapshot will do nothing but the filesystem will discard this kind of in-memory trimmable file info. Later on if you mark the snapshot as removed and want to retry the trim, you may need to unmount and remount the filesystem so that the filesystem can recollect the trimmable file info.

See [Trim Filesystem](../../nodes-and-volumes/volumes/trim-filesystem) for details.

#### Guaranteed Instance Manager CPU

> Default: `{"v1":"12","v2":"12"}`

Percentage of the total allocatable CPU resources on each node to reserve for each instance manager pod. For example, a value of `10` means 10% of the total CPU on a node will be allocated to each instance manager pod on that node. This helps maintain engine and replica stability during periods of high node workload.

In order to prevent unexpected volume instance (engine/replica) crash as well as guarantee a relative acceptable IO performance, you can use the following formula to calculate a value for this setting:

    Guaranteed Instance Manager CPU = The estimated max Longhorn volume engine and replica count on a node * 0.1 / The total allocatable CPUs on the node * 100.

The result of above calculation doesn't mean that's the maximum CPU resources the Longhorn workloads require. To fully exploit the Longhorn volume I/O performance, you can allocate/guarantee more CPU resources via this setting.

If it's hard to estimate the usage now, you can leave it with the default value, which is 12%. Then you can tune it when there is no running workload using Longhorn volumes.

> **Warning:**
>  - Value 0 means unsetting CPU requests for instance manager pods.
>  - Considering the possible new instance manager pods in the further system upgrade, this float value ranges from 0 to 40.
>  - One more set of instance manager pods may need to be deployed when the Longhorn system is upgraded. If current available CPUs of the nodes are not enough for the new instance manager pods, you need to detach the volumes using the oldest instance manager pods so that Longhorn can clean up the old pods automatically and release the CPU resources. And the new pods with the latest instance manager image will be launched then.
>  - This global setting will be ignored for a node if the field "InstanceManagerCPURequest" on the node is set.
>  - For the v2 Data Engine, the Storage Performance Development Kit (SPDK) target daemon inside each instance manager pod uses one or more dedicated CPU cores. Setting a minimum CPU usage is critical to maintaining stability during periods of high node load.

#### Disable Snapshot Purge

> Default: `false`

When set to true, temporarily prevent all attempts to purge volume snapshots.

Longhorn typically purges snapshots during replica rebuilding and user-initiated snapshot deletion. While purging,
Longhorn coalesces unnecessary snapshots into their newer counterparts, freeing space consumed by historical data.

Allowing snapshot purging during normal operations is ideal, but this process temporarily consumes additional disk
space. If insufficient disk space prevents the process from continuing, consider temporarily disabling purging while
data is moved to other disks.

#### Auto Cleanup Snapshot When Delete Backup

> Default: `false`

When set to true, the snapshot used by the backup will be automatically cleaned up when the backup is deleted.

#### Auto Cleanup Snapshot After On-Demand Backup Completed

> Default: `false`

When set to true, the snapshot used by the backup will be automatically cleaned up after the on-demand backup is completed.

#### Instance Manager Pod Liveness Probe Timeout

> Default: `10`

In seconds. The setting specifies the timeout for the instance manager pod liveness probe. The default value is 10 seconds.

> **Warning**
>
> When applying the setting, Longhorn will try to restart all instance-manager pods if all volumes are detached and eventually restart the instance manager pod without instances running on the instance manager.

#### V1 Data Engine

> Default: `true`

Setting that allows you to enable the V1 Data Engine.

#### V2 Data Engine

> Default: `false`

Setting that allows you to enable the V2 Data Engine, which is based on the Storage Performance Development Kit (SPDK). The V2 Data Engine is an experimental feature and should not be used in production environments. For more information, see [V2 Data Engine (Experimental)](../../v2-data-engine).

> **Warning**
>
> - DO NOT CHANGE THIS SETTING WITH ATTACHED VOLUMES. Longhorn will block this setting update when there are attached volumes.
>
> - When the V2 Data Engine is enabled, each instance-manager pod utilizes 1 CPU core. This high CPU usage is attributed to the Storage Performance Development Kit (SPDK) target daemon running within each instance-manager pod. The SPDK target daemon is responsible for handling input/output (IO) operations and requires intensive polling. As a result, it consumes 100% of a dedicated CPU core to efficiently manage and process the IO requests, ensuring optimal performance and responsiveness for storage operations.

#### Data Engine CPU Mask

> Default: `{"v2":"0x1"}`

Applies only to the V2 Data Engine. Specifies the CPU cores on which the Storage Performance Development Kit (SPDK) target daemon runs. The daemon is deployed in each Instance Manager pod. Ensure that the number of assigned cores does not exceed the guaranteed Instance Manager CPUs for the V2 Data Engine.

#### Data Engine Hugepage Limit

> Default: `{"v2":"2048"}`

Applies only to the V2 Data Engine. Specifies the hugepage size, in MiB, for the Storage Performance Development Kit (SPDK) target daemon.