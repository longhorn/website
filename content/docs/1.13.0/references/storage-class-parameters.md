---
title: Storage Class Parameters
weight: 1
---

## Overview

Storage Class as a resource object has a number of settable parameters. Here's a sample YAML:

```yaml
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: longhorn-test
provisioner: driver.longhorn.io
allowVolumeExpansion: true
reclaimPolicy: Delete
volumeBindingMode: Immediate
parameters:
  backupTargetName: "default"
  numberOfReplicas: "3"
  staleReplicaTimeout: "2880"
  fromBackup: ""
  fsType: "ext4"
#  mkfsParams: ""
#  migratable: false
#  encrypted: false
#  dataLocality: "disabled"
#  replicaAutoBalance: "ignored"
#  diskSelector: "ssd,fast"
#  nodeSelector: "storage,fast"
#  recurringJobSelector: '[{"name":"snap-group", "isGroup":true},
#                          {"name":"backup", "isGroup":false}]'
#  backingImageName: ""
#  backingImageChecksum: ""
#  backingImageDataSourceType: ""
#  backingImageDataSourceParameters: ""
#  unmapMarkSnapChainRemoved: "ignored"
#  disableRevisionCounter: false
#  replicaSoftAntiAffinity: "ignored"
#  replicaZoneSoftAntiAffinity: "ignored"
#  replicaDiskSoftAntiAffinity: "ignored"
#  nfsOptions: "soft,timeo=150,retrans=3"
#  dataEngine: "v1"
#  freezeFSForSnapshot: "ignored"
#  strictTopology: "false"
#  volumeTopology: "any"
# allowedTopologies:
#   - matchLabelExpressions:
#       - key: topology.kubernetes.io/zone
#         values:
#           - us-central-1a
#           - us-central-1b
```

## Built-in Fields

Some fields are common to all Kubernetes storage classes.
See also [Kubernetes Storage Class](https://kubernetes.io/docs/concepts/storage/storage-classes).

### Provisioner *(field: `provisioner`)*

Specifies the plugin that will be used for dynamic creation of persistent volumes. For Longhorn, that is always "driver.longhorn.io".

> See [Kubernetes Storage Class: Provisioner](https://kubernetes.io/docs/concepts/storage/storage-classes/#provisioner).

### Allow Volume Expansion *(field: `allowVolumeExpansion`)*

> Default: `true`
> See [Kubernetes Storage Class: Allow Volume Expansion](https://kubernetes.io/docs/concepts/storage/storage-classes/#allow-volume-expansion).

### Reclaim Policy *(field: `reclaimPolicy`)*

> Default: `Delete`
> See [Kubernetes Storage Class: Reclaim Policy](https://kubernetes.io/docs/concepts/storage/storage-classes/#reclaim-policy).

### Mount Options *(field: `mountOptions`)*

> Default: `[]`
> See [Kubernetes Storage Class: Mount Options](https://kubernetes.io/docs/concepts/storage/storage-classes/#mount-options).

### Volume Binding Mode *(field: `volumeBindingMode`)*

> Default: `Immediate`
> See [Kubernetes Storage Class: Volume Binding Mode](https://kubernetes.io/docs/concepts/storage/storage-classes/#volume-binding-mode).

`Immediate` provisions the volume immediately upon PVC creation.
When using `volumeTopology` or `strictTopology`, `WaitForFirstConsumer` is strongly recommended so the volume's failure domain and PV `nodeAffinity` follow the scheduled node of the first consumer pod.

### Allowed Topologies *(field: `allowedTopologies`)*

> See the Kubernetes reference: [StorageClass — Allowed Topologies](https://kubernetes.io/docs/concepts/storage/storage-classes/#allowed-topologies).

Specifies the set of nodes where volumes may be provisioned by matching node labels.
Longhorn uses this field to populate the PV’s `nodeAffinity` via the CSI `accessibleTopology` field.

For `allowedTopologies` to take effect, the Longhorn setting [`csi-allowed-topology-keys`](../settings#csi-allowed-topology-keys) must be configured with the corresponding topology keys (for example, `topology.kubernetes.io/zone`). Without this setting, no topology information is passed through and the PV will have no `nodeAffinity`.

`volumeTopology` has no effect on volumes with `dataLocality: strict-local`, and `allowedTopologies` is not written to the PV. Longhorn ignores the CSI topology for these volumes and places the data on the workload node.

> For a complete walkthrough with examples, see [Topology-Aware Provisioning](../../nodes-and-volumes/nodes/topology-aware-provisioning).

## Longhorn-specific Parameters

* **Parameter overrides:** Some of these parameters also exist and may be specified in global settings. When a volume is provisioned with Kubernetes against a particular `StorageClass`, the `StorageClass` parameters override the global settings.
* **New volumes only:** These fields will be applied for new volume creation only. If a `StorageClass` is modified, neither Longhorn nor Kubernetes is responsible for propagating changes to its parameters back to volumes previously created with it.

### Number Of Replicas *(field: `parameters.numberOfReplicas`)*

> Default: `3`

The desired number of copies (replicas) for redundancy.

- Must be between 1 and 20.
- When `dataLocality` is set to `strict-local`, `numberOfReplicas` must be `1`.
- Replicas will be placed across the widest possible set of zones, nodes, and disks in a cluster, subject to other constraints, such as NodeSelector.

> Global setting: [Default Replica Count](../settings#default-replica-count).

### Stale Replica Timeout *(field: `parameters.staleReplicaTimeout`)*

> Default: `2880`

The number of minutes after a replica is marked unhealthy before it is deemed useless for rebuilds and is deleted. The default value `2880` corresponds to 48 hours.

### From Backup *(field: `parameters.fromBackup`)*

> Default: `""`
> Example: `"s3://backupbucket@us-east-1?volume=minio-vol01&backup=backup-eeb2782d5b2f42bb"`

URL of a backup to be restored from.

### Backup Target Name *(field: `parameters.backupTargetName`)*

> Default: `default`

The name of the backup target to use for backups or restores.

> For more details, see [default backup target](../../snapshots-and-backups/backup-and-restore/set-backup-target#default-backup-target) and [Create Volumes](../../nodes-and-volumes/volumes/create-volumes).

### Backup Block Size *(field: `parameters.backupBlockSize`)*

> Default: `""`
> Example: `"2Mi"` or `"16Mi"`

Kubernetes quantity string for the backup block size. Specify the empty string `""` to use the global setting.

> Global setting: [default backup block size](../settings#default-backup-block-size).
> For more details, see [Configure The Block Size Of Backup](../../snapshots-and-backups/backup-and-restore/configure-backup-block-size).

### FS Type *(field: `parameters.fsType`)*

> Default: `ext4`

The filesystem used to format the volume. Supported filesystems are `ext4` and `xfs`.

> For more details, see [Creating Longhorn Volumes with Kubernetes](../../nodes-and-volumes/volumes/create-volumes).

### Mkfs Params *(field: `parameters.mkfsParams`)*

> Default: `""`

Additional parameters passed to the `mkfs.<fsType>` command during filesystem creation.

> For more details, see [Creating Longhorn Volumes with Kubernetes](../../nodes-and-volumes/volumes/create-volumes).

### Migratable *(field: `parameters.migratable`)*

> Default: `false`

Enables live migration capabilities for a Longhorn volume, allowing it to be migrated from one node to another while maintaining active I/O operations.

**When to use:**

- **`migratable: true`**: For workloads requiring live migration. Must be used with `ReadWriteMany` access mode and `volumeMode: Block`.
- **`migratable: false`**: For standard volumes that don't require live migration capabilities.

> **Note**: If specified on non-RWX volumes, Longhorn proceeds with non-migratable RWO volume creation. For more details, see [ReadWriteMany (RWX) Volumes](../../nodes-and-volumes/volumes/rwx-volumes).

### Encrypted *(field: `parameters.encrypted`)*

> Default: `false`

Enables volume encryption using dm-crypt/LUKS.

> For more details, see [Encrypted Volumes](../../advanced-resources/security/volume-encryption).

### Data Locality *(field: `parameters.dataLocality`)*

> Default: `disabled`

If enabled, try to keep the data on the same node as the workload for better performance.

- `"disabled"`: No co-location requirement.
- `"best-effort"`: A replica will be co-located if possible, but is permitted to find another node if not.
- `"strict-local"`: The replica count must be 1, or volume creation fails with a validation error. Longhorn places the volume data on the workload node and ignores CSI topology/accessibility requirements; `allowedTopologies` is not written to the PV `nodeAffinity`, and `volumeTopology` has no effect. A displaced `strict-local` replica will be marked as "Stopped".

> Global setting: [Default Data Locality](../settings#default-data-locality).
> For more details, see [Data Locality](../../high-availability/data-locality).

### Replica Auto-Balance *(field: `parameters.replicaAutoBalance`)*

> Default: `ignored`

If enabled, move replicas to more lightly-loaded nodes.

- `"ignored"`: Use the global setting.
- Other options are `"disabled"`, `"least-effort"`, `"best-effort"`.

> Global setting: [Replica Auto Balance](../settings#replica-auto-balance).
> For more details, see [Auto Balance Replicas](../../high-availability/auto-balance-replicas).

### Disk Selector *(field: `parameters.diskSelector`)*

> Default: `""`
> Example: `"ssd,fast"`

A comma-separated list of disk tags to select which disks are candidates for replica placement.

> For more details, see [Storage Tags](../../nodes-and-volumes/nodes/storage-tags).

### Node Selector *(field: `parameters.nodeSelector`)*

> Default: `""`
> Example: `"storage,fast"`

A comma-separated list of node tags to select which nodes are candidates for replica placement.

> For more details, see [Storage Tags](../../nodes-and-volumes/nodes/storage-tags).

### Recurring Job Selector *(field: `parameters.recurringJobSelector`)*

> Default: `""`
> Example: `[{"name":"snap-group", "isGroup":true}, {"name":"backup", "isGroup":false}]`

A JSON array of recurring job or group specifications to attach to the volume.

> For more details, see [Recurring Snapshots and Backups](../../snapshots-and-backups/scheduling-backups-and-snapshots).

### Backing Image *(field: `parameters.backingImage`)*

> Default: `""`

The name of the backing image to use for the volume.

> For more details, see [Backing Image](../../advanced-resources/backing-image/backing-image#create-and-use-a-backing-image-via-storageclass-and-pvc).

### Backing Image Data Source Type *(field: `parameters.backingImageDataSourceType`)*

> Default: `""`

The data source type if Longhorn must create a missing backing image during CSI volume provisioning.

- **Supported via CSI**: `download` and `export-from-volume`.
- **Unsupported (`upload`)**: `upload` is a valid Longhorn backing image source type, but it is rejected when creating a missing backing image through CSI provisioning.
- **Unsupported (`clone`)**: `clone` is a valid Longhorn backing image source type, but it is not created through this CSI StorageClass path.

If `backingImage` refers to an existing `backingImage`, this parameter is usually unnecessary. If specified, it must match the existing `backingImage` source type and source parameters.

> For more details, see [Backing Image](../../advanced-resources/backing-image/backing-image#create-and-use-a-backing-image-via-storageclass-and-pvc).

### Backing Image Data Source Parameters *(field: `parameters.backingImageDataSourceParameters`)*

> Default: `""`
> Example: `'{"url": "https://backing-image-example.s3-region.amazonaws.com/test-backing-image"}'`

A JSON string representing the parameters required by the specified `backingImageDataSourceType`.

> For more details, see [Backing Image](../../advanced-resources/backing-image/backing-image#create-and-use-a-backing-image-via-storageclass-and-pvc).

### Backing Image Checksum *(field: `parameters.backingImageChecksum`)*

> Default: `""`

Expected SHA512 checksum of the backing image file.

> For more details, see [Backing Image](../../advanced-resources/backing-image/backing-image#create-and-use-a-backing-image-via-storageclass-and-pvc).

### Backing Image Min Number Of Copies *(field: `parameters.backingImageMinNumberOfCopies`)*

> Default: `""`
> Example: `"2"`

The minimum number of backing image copies Longhorn will automatically maintain on different disks.

> For more details, see [Backing Image](../../advanced-resources/backing-image/backing-image#create-and-use-a-backing-image-via-storageclass-and-pvc).

### Backing Image Node Selector *(field: `parameters.backingImageNodeSelector`)*

> Default: `""`
> Example: `"storage,fast"`

A comma-separated list of node tags where copies of the backing image are allowed to be placed.

> For more details, see [Backing Image](../../advanced-resources/backing-image/backing-image#create-and-use-a-backing-image-via-storageclass-and-pvc).

### Backing Image Disk Selector *(field: `parameters.backingImageDiskSelector`)*

> Default: `""`
> Example: `"ssd"`

A comma-separated list of disk tags where copies of the backing image are allowed to be placed.

> For more details, see [Backing Image](../../advanced-resources/backing-image/backing-image#create-and-use-a-backing-image-via-storageclass-and-pvc).

### Unmap Mark Snap Chain Removed *(field: `parameters.unmapMarkSnapChainRemoved`)*

> Default: `ignored`

- `"ignored"`: Use the global setting.
- Other values are `"enabled"` and `"disabled"`.

> **Note**: For V2 Data Engine volumes, this parameter must be `"disabled"` (or left unset).
> Global setting: [Remove Snapshots During Filesystem Trim](../settings#remove-snapshots-during-filesystem-trim).  
> For more details, see [Trim Filesystem](../../nodes-and-volumes/volumes/trim-filesystem).

### Disable Revision Counter *(field: `parameters.disableRevisionCounter`)*

> Default: `true`

Controls whether to disable the volume revision counter. When set to `false`, Longhorn tracks revision counts to detect split-brain scenarios. When set to `true` (default), the revision counter is disabled.

> **Note**: Revision counters do not apply to V2 Data Engine volumes.
> Global setting: [Disable Revision Counter](../settings#disable-revision-counter).
> For more details, see [Revision Counter](../../advanced-resources/deploy/revision_counter).

### Replica Soft Anti-Affinity *(field: `parameters.replicaSoftAntiAffinity`)*

> Default: `ignored`

- `"ignored"`: Use the global setting.
- Other values are `"enabled"` and `"disabled"`.

> Global setting: [Replica Node Level Soft Anti-Affinity](../settings#replica-node-level-soft-anti-affinity).
> For more details, see [Scheduling](../../nodes-and-volumes/nodes/scheduling) and [Best Practices](../../best-practices#replica-node-level-soft-anti-affinity).

### Replica Zone Soft Anti-Affinity *(field: `parameters.replicaZoneSoftAntiAffinity`)*

> Default: `ignored`

- `"ignored"`: Use the global setting.
- Other values are `"enabled"` and `"disabled"`.

> Note: For zonal volumes (`volumeTopology: "zonal"`), `replicaZoneSoftAntiAffinity` must be `"enabled"`. If it is unset or set to `"ignored"`, Longhorn records `"enabled"` on the volume instead of following the global setting. Longhorn rejects `volumeTopology: "zonal"` if this is set to `"disabled"`, as all replicas of a zonal volume must reside in the same zone.
> Global setting: [Replica Zone Level Soft Anti-Affinity](../settings#replica-zone-level-soft-anti-affinity).
> For more details, see [Scheduling](../../nodes-and-volumes/nodes/scheduling).

### Replica Disk Soft Anti-Affinity *(field: `parameters.replicaDiskSoftAntiAffinity`)*

> Default: `ignored`

- `"ignored"`: Use the global setting.
- Other values are `"enabled"` and `"disabled"`.

> Global setting: [Replica Disk Level Soft Anti-Affinity](../settings#replica-disk-level-soft-anti-affinity).
> For more details, see [Scheduling](../../nodes-and-volumes/nodes/scheduling).

### NFS Options *(field: `parameters.nfsOptions`)*

> Default: `""`
> Example: `"hard,sync"`

Overrides for NFS mount of RWX volumes to the share-manager. Use this field with caution.
> **Note**: Built-in options vary by release. Check your release details before setting this.

> For more details, see [ReadWriteMany (RWX) Volume](../../nodes-and-volumes/volumes/rwx-volumes#configuring-volume-mount-options-for-generic-non-migratable-rwx-volumes).

### Data Engine *(field: `parameters.dataEngine`)*

> Default: `"v1"`

Specifies the data engine for the volume: `"v1"` or `"v2"`. When unspecified, Longhorn uses `"v1"`.

> Global setting: [V2 Data Engine](../settings#v2-data-engine).

### Frontend *(field: `parameters.frontend`)*

> Default: `"blockdev"`

Specifies the frontend exposure mechanism for the volume:

- For V1 Data Engine: `"blockdev"` or `"iscsi"`.
- For V2 Data Engine: `"blockdev"`, `"nvmf"`, or `"ublk"`.

### NVMe-TCP Number of IO Queues *(field: `parameters.nvmeTcpNrIoQueues`)*

> Default: `0`

The number of I/O queues the kernel initiator creates when connecting a volume frontend over NVMe-TCP.

- `0` means unspecified (uses the kernel default: one queue per online CPU core).
- Valid range: `1` to `128` (or `0`).
- Applies only to volumes using the V2 Data Engine with block device frontend.

> Global setting: [Default NVMe-TCP Number Of IO Queues](../settings#default-nvme-tcp-number-of-io-queues).

### Ublk Number of Queues *(field: `parameters.ublkNumberOfQueue`)*

> Default: `0`

The number of queues for the ublk frontend.

- `0` means unspecified and uses the global setting.
- Explicit values must be at least `1`.
- Applies only to volumes using the V2 Data Engine with `ublk` frontend.

> Global setting: [Default Ublk Number Of Queue](../settings#default-ublk-number-of-queue).

### Ublk Queue Depth *(field: `parameters.ublkQueueDepth`)*

> Default: `0`

The queue depth of each queue for the ublk frontend.

- `0` means unspecified and uses the global setting.
- Explicit values must be at least `32`.
- Applies only to volumes using the V2 Data Engine with `ublk` frontend.

> Global setting: [Default Ublk Queue Depth](../settings#default-ublk-queue-depth).

### Data Layout Type *(field: `parameters.dataLayout.type`)*

> Default: `replicated`

Controls how volume data is distributed.

- `replicated` (default): Each replica holds a full copy of the volume.
- `sharded`: Data is split into `dataChunks` data chunks and `parityChunks` parity chunks, then distributed across different nodes using erasure coding. Requires the V2 Data Engine.

The data layout is immutable after the volume is created.

> For more details, see [Sharding](../../advanced-resources/v2-data-engine/sharding).

### Data Layout Mode *(field: `parameters.dataLayout.mode`)*

> Default: `erasureCoding` when `dataLayout.type` is `sharded`

The data protection mechanism: `raid1` for replicated volumes, or `erasureCoding` for sharded volumes. The parameter can usually be omitted: `erasureCoding` is set automatically when `dataLayout.type` is `sharded`, and replicated volumes always use RAID1.

### Data Layout Data Chunks *(field: `parameters.dataLayout.dataChunks`)*

The number of data chunks (`k`) in the erasure-coded array. Required when `dataLayout.type` is `sharded`. Must be at least 1.

### Data Layout Parity Chunks *(field: `parameters.dataLayout.parityChunks`)*

The number of parity chunks (`m`) in the erasure-coded array. Required when `dataLayout.type` is `sharded`. Must be at least 1. The volume tolerates up to `m` simultaneous chunk failures. The total number of chunks (`dataChunks + parityChunks`) must not exceed 32.

### Data Layout Strip Size KB *(field: `parameters.dataLayout.stripSizeKB`)*

The strip size, in KiB, of the erasure-coded array: the amount of contiguous data placed on one chunk before striping moves to the next. Required when `dataLayout.type` is `sharded`. Must be a power of two between 4 and 1024.

### Freeze Filesystem For Snapshot *(field: `parameters.freezeFilesystemForSnapshot`)*

> Default: `ignored`

- `"ignored"` instructs Longhorn to use the global setting.
- Other values are `"enabled"` and `"disabled"`.

> Global setting: [Freeze File System For Snapshot](../settings#freeze-filesystem-for-snapshot).

### Strict Topology *(field: `parameters.strictTopology`)*

> Default: `"false"`

When set to `"true"`, the PV is pinned to the topology of the exact node selected by the Kubernetes scheduler. This is only effective when `volumeBindingMode` is set to `WaitForFirstConsumer`.

- `"false"` (default): The PV `nodeAffinity` includes all topology segments matching the `allowedTopologies` (or all segments if `allowedTopologies` is not set).
- `"true"`: The PV `nodeAffinity` is restricted to only the topology segment of the node where the pod was scheduled.

This parameter controls only Kubernetes PV `nodeAffinity`. It does not persist a Longhorn replica or shard placement constraint. Use [`volumeTopology`](#volume-topology) when Longhorn data placement must stay in the same zone or region as the PV.

> Requires `csi-allowed-topology-keys` to be configured. See [CSI Allowed Topology Keys](../settings#csi-allowed-topology-keys).

### Volume Topology *(field: `parameters.volumeTopology`)*

> Default: `"any"`

Controls whether Longhorn stores a topology requirement on newly provisioned volumes and enforces it during the placement of replicas, rebuilds, auto-balancing candidates, and erasure-coded shards.

**Options:**

- `"any"` (default): Longhorn does not store a topology requirement. Data placement remains unconstrained by CSI topology.
- `"zonal"`: Longhorn resolves a single zone during volume creation. Both the PV `nodeAffinity` and all Longhorn data placement are strictly confined to that zone.
- `"regional"`: Longhorn resolves a single region during volume creation. The PV `nodeAffinity` and all Longhorn data placement are confined to that region (though replicas can still spread across multiple zones **within** that region).

**Requirements and Constraints:**

- **Affinity Settings:** When using `"zonal"`, `replicaZoneSoftAntiAffinity` must be `"enabled"`. If it is unset or set to `"ignored"`, Longhorn records `"enabled"` on the volume instead of following the global setting. Longhorn will reject `volumeTopology: "zonal"` if this is set to `"disabled"`, as all replicas of a zonal volume must reside in the same zone.
- **CSI Topology Keys:** You must include the corresponding topology key in [`csi-allowed-topology-keys`](../settings#csi-allowed-topology-keys) (`topology.kubernetes.io/zone` for `"zonal"`, or `topology.kubernetes.io/region` for `"regional"`). If nodes report the requested key but your setting filters it out, provisioning will be rejected rather than falling back to an unconstrained volume.

> **Recommendation:** Use `volumeBindingMode: WaitForFirstConsumer` alongside `volumeTopology`. This ensures the resolved failure domain follows the scheduling decision of the first consumer pod. For more details, see [Topology-Aware Provisioning](../../nodes-and-volumes/nodes/topology-aware-provisioning).

## Helm Installs

If Longhorn is installed via Helm, values in the default storage class can be set by editing the corresponding item in the chart `values.yaml` file. All of the Storage Class parameters have a prefix of "persistence". For example, `persistence.defaultNodeSelector`.
