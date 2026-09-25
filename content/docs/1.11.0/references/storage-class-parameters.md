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

### Allowed Topologies *(field: `allowedTopologies`)*

> See the Kubernetes reference: [StorageClass — Allowed Topologies](https://kubernetes.io/docs/concepts/storage/storage-classes/#allowed-topologies).

Specifies the set of nodes where volumes may be provisioned by matching node labels.
Longhorn uses this field to populate the PV’s `nodeAffinity` via the CSI `accessibleTopology` field.

`allowedTopologies` is not written to the PV for volumes with `dataLocality: strict-local`. Longhorn ignores the CSI topology for these volumes and places the data on the workload node.

## Longhorn-specific Parameters

Note that some of these parameters also exist and may be specified in global settings. When a volume is provisioned with Kubernetes against a particular StorageClass, StorageClass parameters override the global settings.
These fields will be applied for new volume creation only. If a StorageClass is modified, neither Longhorn nor Kubernetes is responsible for propagating changes to its parameters back to volumes previously created with it.

### Number Of Replicas *(field: `parameters.numberOfReplicas`)*

> Default: `3`

The desired number of copies (replicas) for redundancy.

- Must be between 1 and 20.
- When `dataLocality` is set to `strict-local`, `numberOfReplicas` must be `1`.
- Replicas will be placed across the widest possible set of zones, nodes, and disks in a cluster, subject to other constraints, such as NodeSelector.

> Global setting: [Default Replica Count](../settings#default-replica-count).

### Stale Replica Timeout *(field: `parameters.staleReplicaTimeout`)*

> Default: `2880`

Minutes after a replica is marked unhealthy before it is deemed useless for rebuilds and is just deleted. The default value `2880` corresponds to 48 hours.

### From Backup *(field: `parameters.fromBackup`)*

> Default: `""`
> Example: `"s3://backupbucket@us-east-1?volume=minio-vol01&backup=backup-eeb2782d5b2f42bb"`

URL of a backup to be restored from.

### Backup Target Name *(field: `parameters.backupTargetName`)*

> Default: `default`

The name of the backup target to use for backups or restores.

> More details in [default backup target](../../snapshots-and-backups/backup-and-restore/set-backup-target#default-backup-target) and [Create Volumes](../../nodes-and-volumes/volumes/create-volumes).

### Backup Block Size *(field: `parameters.backupBlockSize`)*

> Default: `""`
> Example: `"2Mi"` or `"16Mi"`

Kubernetes quantity string for the backup block size. Specify the empty string `""` to use the global setting.

> Global setting: [default backup block size](../settings#default-backup-block-size).
> More details in [Configure The Block Size Of Backup](../../snapshots-and-backups/backup-and-restore/configure-backup-block-size).

### FS Type *(field: `parameters.fsType`)*

> Default: `ext4`

Filesystem to format the volume with. Supported filesystems are `ext4` and `xfs`.

> For more details, see [Creating Longhorn Volumes with Kubernetes](../../nodes-and-volumes/volumes/create-volumes#creating-longhorn-volumes-with-kubectl).

### Mkfs Params *(field: `parameters.mkfsParams`)*

> Default: `""`

Additional parameters passed to the `mkfs.<fsType>` command during filesystem creation.

> For more details, see [Creating Longhorn Volumes with Kubernetes](../../nodes-and-volumes/volumes/create-volumes#creating-longhorn-volumes-with-kubectl).

### Migratable *(field: `parameters.migratable`)*

> Default: `false`

Enables live migration capabilities for a Longhorn volume, allowing it to be migrated from one node to another while maintaining active I/O operations.

**When to use:**

- **`migratable: true`**: For workloads requiring live migration. Must be used with `ReadWriteMany` access mode and `volumeMode: Block`.
- **`migratable: false`**: For standard volumes that don't require live migration capabilities.

> Note: If specified on non-RWX volumes, Longhorn proceeds with non-migratable RWO volume creation.
> More details in [ReadWriteMany (RWX) Volume](../../nodes-and-volumes/volumes/rwx-volumes).

### Encrypted *(field: `parameters.encrypted`)*

> Default: `false`

Enables volume encryption using dm-crypt/LUKS.

> More details in [Encrypted Volumes](../../advanced-resources/security/volume-encryption).

### Data Locality *(field: `parameters.dataLocality`)*

> Default: `disabled`

If enabled, try to keep the data on the same node as the workload for better performance.

- `"disabled"`: No co-location requirement.
- `"best-effort"`: A replica will be co-located if possible, but is permitted to find another node if not.
- `"strict-local"`: The replica count must be 1, or volume creation fails with a validation error. Longhorn places the volume data on the workload node and ignores CSI topology/accessibility requirements; `allowedTopologies` is not written to the PV `nodeAffinity`. A displaced `strict-local` replica will be marked as "Stopped".

> Global setting: [Default Data Locality](../settings#default-data-locality).
> More details in [Data Locality](../../high-availability/data-locality).

### Replica Auto-Balance *(field: `parameters.replicaAutoBalance`)*

> Default: `ignored`

If enabled, move replicas to more lightly-loaded nodes.

- `"ignored"`: Use the global setting.
- Other options are `"disabled"`, `"least-effort"`, `"best-effort"`.

> Global setting: [Replica Auto Balance](../settings#replica-auto-balance).
> More details in [Auto Balance Replicas](../../high-availability/auto-balance-replicas).

### Disk Selector *(field: `parameters.diskSelector`)*

> Default: `""`
> Example: `"ssd,fast"`

A comma-separated list of disk tags to select which disks are candidates for replica placement.

> More details in [Storage Tags](../../nodes-and-volumes/nodes/storage-tags).

### Node Selector *(field: `parameters.nodeSelector`)*

> Default: `""`
> Example: `"storage,fast"`

A comma-separated list of node tags to select which nodes are candidates for replica placement.

> More details in [Storage Tags](../../nodes-and-volumes/nodes/storage-tags).

### Recurring Job Selector *(field: `parameters.recurringJobSelector`)*

> Default: `""`
> Example: `[{"name":"snap-group", "isGroup":true}, {"name":"backup", "isGroup":false}]`

A JSON array of recurring job or group specifications to attach to the volume.

> More details in [Recurring Snapshots and Backups](../../snapshots-and-backups/scheduling-backups-and-snapshots).

### Backing Image *(field: `parameters.backingImage`)*

> Default: `""`

The name of the backing image to use for the volume.

> See [Backing Image](../../advanced-resources/backing-image/backing-image#create-and-use-a-backing-image-via-storageclass-and-pvc).

### Backing Image Data Source Type *(field: `parameters.backingImageDataSourceType`)*

> Default: `""`

The data source type if Longhorn must create a missing backing image during CSI volume provisioning.

- Supported through StorageClass/PVC provisioning: `download` and `export-from-volume`.
- `upload` is a Longhorn backing image source type, but it is rejected when creating a missing backing image through CSI provisioning.
- `clone` is a Longhorn backing image source type, but it is not created through this CSI StorageClass path.

If `backingImage` refers to an existing BackingImage, this parameter is usually unnecessary. If specified, it must match the existing BackingImage source type and source parameters.

> See [Backing Image](../../advanced-resources/backing-image/backing-image#create-and-use-a-backing-image-via-storageclass-and-pvc).

### Backing Image Data Source Parameters *(field: `parameters.backingImageDataSourceParameters`)*

> Default: `""`
> Example: `'{"url": "https://backing-image-example.s3-region.amazonaws.com/test-backing-image"}'`

A JSON string representing the parameters required by the specified `backingImageDataSourceType`.

> See [Backing Image](../../advanced-resources/backing-image/backing-image#create-and-use-a-backing-image-via-storageclass-and-pvc).

### Backing Image Checksum *(field: `parameters.backingImageChecksum`)*

> Default: `""`

Expected SHA512 checksum of the backing image file.

> See [Backing Image](../../advanced-resources/backing-image/backing-image#create-and-use-a-backing-image-via-storageclass-and-pvc).

### Backing Image Min Number Of Copies *(field: `parameters.backingImageMinNumberOfCopies`)*

> Default: `""`
> Example: `"2"`

The minimum number of backing image copies Longhorn will automatically maintain on different disks.

> See [Backing Image](../../advanced-resources/backing-image/backing-image#create-and-use-a-backing-image-via-storageclass-and-pvc).

### Backing Image Node Selector *(field: `parameters.backingImageNodeSelector`)*

> Default: `""`
> Example: `"storage,fast"`

A comma-separated list of node tags where copies of the backing image are allowed to be placed.

> See [Backing Image](../../advanced-resources/backing-image/backing-image#create-and-use-a-backing-image-via-storageclass-and-pvc).

### Backing Image Disk Selector *(field: `parameters.backingImageDiskSelector`)*

> Default: `""`
> Example: `"ssd"`

A comma-separated list of disk tags where copies of the backing image are allowed to be placed.

> See [Backing Image](../../advanced-resources/backing-image/backing-image#create-and-use-a-backing-image-via-storageclass-and-pvc).

### Unmap Mark Snap Chain Removed *(field: `parameters.unmapMarkSnapChainRemoved`)*

> Default: `ignored`

- `"ignored"`: Use the global setting.
- Other values are `"enabled"` and `"disabled"`.

> Note: For V2 Data Engine volumes, this parameter must be `"disabled"` (or left unset).
> Global setting: [Remove Snapshots During Filesystem Trim](../settings#remove-snapshots-during-filesystem-trim).
> More details in [Trim Filesystem](../../nodes-and-volumes/volumes/trim-filesystem).

### Disable Revision Counter *(field: `parameters.disableRevisionCounter`)*

> Default: `true`

Controls whether to disable the volume revision counter. When set to `false`, Longhorn tracks revision counts to detect split-brain scenarios. When set to `true` (default), the revision counter is disabled.

> Note: Revision counters do not apply to V2 Data Engine volumes.
> Global setting: [Disable Revision Counter](../settings#disable-revision-counter).
> More details in [Revision Counter](../../advanced-resources/deploy/revision_counter).

### Replica Soft Anti-Affinity *(field: `parameters.replicaSoftAntiAffinity`)*

> Default: `ignored`

- `"ignored"`: Use the global setting.
- Other values are `"enabled"` and `"disabled"`.

> Global setting: [Replica Node Level Soft Anti-Affinity](../settings#replica-node-level-soft-anti-affinity).
> More details in [Scheduling](../../nodes-and-volumes/nodes/scheduling) and [Best Practices](../../best-practices#replica-node-level-soft-anti-affinity).

### Replica Zone Soft Anti-Affinity *(field: `parameters.replicaZoneSoftAntiAffinity`)*

> Default: `ignored`

- `"ignored"`: Use the global setting.
- Other values are `"enabled"` and `"disabled"`.

> Global setting: [Replica Zone Level Soft Anti-Affinity](../settings#replica-zone-level-soft-anti-affinity).
> More details in [Scheduling](../../nodes-and-volumes/nodes/scheduling).

### Replica Disk Soft Anti-Affinity *(field: `parameters.replicaDiskSoftAntiAffinity`)*

> Default: `ignored`

- `"ignored"`: Use the global setting.
- Other values are `"enabled"` and `"disabled"`.

> Global setting: [Replica Disk Level Soft Anti-Affinity](../settings#replica-disk-level-soft-anti-affinity).
> More details in [Scheduling](../../nodes-and-volumes/nodes/scheduling).

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

### Freeze Filesystem For Snapshot *(field: `parameters.freezeFilesystemForSnapshot`)*

> Default: `ignored`

- `"ignored"` instructs Longhorn to use the global setting.
- Other values are `"enabled"` and `"disabled"`.

> Global setting: [Freeze File System For Snapshot](../settings#freeze-filesystem-for-snapshot).

## Helm Installs

If Longhorn is installed via Helm, values in the default storage class can be set by editing the corresponding item in the chart `values.yaml` file. All of the Storage Class parameters have a prefix of "persistence". For example, `persistence.defaultNodeSelector`.
