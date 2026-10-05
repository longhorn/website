---
title: Replica Directory Layout
weight: 7
---

This page describes how a Longhorn V1 Data Engine replica stores its data on a node's disk. The information helps users and developers understand the internal data structures of Longhorn, for example when [exporting a volume from a single replica](../../advanced-resources/data-recovery/export-from-replica) or troubleshooting a [corrupted replica](../../advanced-resources/data-recovery/corrupted-replica).

> **Warning:** The files described on this page are managed by Longhorn. Do not create, modify, rename, or delete them manually while the replica is in use, because doing so can corrupt the volume data. Use the Longhorn UI or `kubectl` to manage volumes, snapshots, and replicas.

> **Note:** This page applies to replicas of the V1 Data Engine, which are stored as files in a filesystem-type disk. Replicas of the V2 Data Engine are stored as logical volumes in a block-type disk and do not have the files described here.

## Disk Directory

Each filesystem-type disk that Longhorn manages on a node (by default `/var/lib/longhorn`) contains the following entries:

```
<disk-path>/
├── longhorn-disk.cfg
└── replicas/
    ├── <volume-name>-<random-id>/
    └── <volume-name>-<random-id>/
```

| Path | Description |
|------|-------------|
| `longhorn-disk.cfg` | A JSON file that identifies the disk. Longhorn uses it to verify that the disk at the given path is the one registered in the Longhorn node. |
| `replicas/` | The directory that contains the data directory of every replica scheduled on this disk. |
| `replicas/<volume-name>-<random-id>/` | The data directory of a single replica. The name is the volume name (the same as the Kubernetes PV name) followed by a hyphen and a random 8-character ID, for example `pvc-06b4a8a8-b51d-42c6-a8cc-d8c8d6bc65bc-d890efb2`. The name is stored in the `dataDirectoryName` field of the Replica custom resource. |

The `longhorn-disk.cfg` file has the following content:

```json
{"diskName":"default-disk-fd1c3e5a3a9e1c3a","diskUUID":"b5d1f2c4-8c3e-4c9a-9a4e-6f1f2d9e7a10","diskDriver":"","state":"ready"}
```

| Field | Description |
|-------|-------------|
| `diskName` | The name of the disk in the Longhorn node. |
| `diskUUID` | The unique ID of the disk. |
| `diskDriver` | The disk driver. It is empty for filesystem-type disks. |
| `state` | The state of the disk. |

## Replica Data Directory

A replica data directory contains one sparse data file for the live data (the head), one sparse data file for each snapshot, the metadata files that describe how those files are chained together, and a revision counter file.

The following is an example of a replica data directory of a volume that has two snapshots, `snap1` and `snap2`:

```
pvc-06b4a8a8-b51d-42c6-a8cc-d8c8d6bc65bc-d890efb2/
├── revision.counter
├── volume.meta
├── volume-head-002.img
├── volume-head-002.img.meta
├── volume-snap-snap1.img
├── volume-snap-snap1.img.meta
├── volume-snap-snap2.img
└── volume-snap-snap2.img.meta
```

| File | Description |
|------|-------------|
| `volume.meta` | The metadata of the replica. See [volume.meta](#volumemeta). |
| `volume-head-<NNN>.img` | The head file of the replica, which receives all the live writes of the volume. `<NNN>` is a zero-padded sequence number that is increased every time a new snapshot is taken. There is exactly one head file in a replica directory. |
| `volume-snap-<snapshot-name>.img` | The data file of a snapshot. It is the former head file, which becomes read-only when the snapshot is created. `<snapshot-name>` is the name of the Longhorn snapshot. |
| `volume-head-<NNN>.img.meta`, `volume-snap-<snapshot-name>.img.meta` | The metadata of the head file or snapshot with the same name. See [Disk Metadata Files](#disk-metadata-files). |
| `volume-snap-<snapshot-name>.img.checksum` | Optional. The checksum of the snapshot data, which is generated when Longhorn hashes the snapshot, for example when [snapshot data integrity](../../advanced-resources/data-integrity/snapshot-data-integrity-check) is enabled. See [Snapshot Checksum Files](#snapshot-checksum-files). |
| `revision.counter` | The counter that tracks the number of writes the replica has received. See [revision.counter](#revisioncounter). |

Longhorn can also create the following temporary files in the directory during an operation. They are removed or renamed when the operation completes:

- `*.tmp`: A temporary file that is renamed to the final metadata file after it is completely written.
- `volume-snap-<snapshot-name>.img.snap_tmp`: A temporary file that receives the data while a backup is being restored into a new snapshot. It is renamed to the snapshot file after the restore completes.
- `volume-delta-<backup-name>.img`: A temporary file that holds the data differences while a volume is being incrementally restored from a backup, for example a [disaster recovery volume](../../snapshots-and-backups/setup-disaster-recovery-volumes).

### Data Files (`.img`)

Each `.img` file is a [sparse file](https://en.wikipedia.org/wiki/Sparse_file) whose apparent size is the size of the volume. Only the blocks that were written while the file was the head of the volume are physically allocated. A snapshot file therefore contains only the changes made between the snapshot and its parent snapshot.

The chain of data files forms the layers of the volume:

```
volume-snap-snap1.img  <-  volume-snap-snap2.img  <-  volume-head-002.img
  (oldest snapshot)                                       (live data)
```

When the volume is read, Longhorn looks up each block starting from the head and falls back to the parent files for the blocks that were not written in the newer layers. When a volume is created from a backing image, the backing image is the base layer of the chain.

> **Note:** Because the files are sparse, use `du` to see the actual disk usage and `ls -l` to see the apparent size.

### Disk Metadata Files

Every `.img` file has a companion `.img.meta` file that contains a JSON object. For example:

```json
{"Name":"volume-head-001.img","Parent":"volume-snap-snap1.img","Removed":false,"UserCreated":true,"Created":"2026-10-05T00:41:33Z","Labels":null}
```

| Field | Description |
|-------|-------------|
| `Name` | The name of the data file. When the file name and this field differ, the file name is the one that Longhorn uses. This can happen because a snapshot file is created by renaming the former head file and its metadata file. |
| `Parent` | The name of the parent data file, which is the previous layer in the chain. It is empty for the oldest file. |
| `Removed` | Whether the file is marked as removed. A removed snapshot is kept until it is coalesced into its child during snapshot purge. |
| `UserCreated` | `true` for snapshots that are created by a user-initiated operation. `false` for the head file and for snapshots that Longhorn creates internally. |
| `Created` | The creation time in RFC 3339 format. |
| `Labels` | The labels of the snapshot. |

Longhorn rebuilds its in-memory snapshot tree from the `.meta` files when the replica starts. Longhorn reads the chain by following the `Parent` fields from the head file defined in `volume.meta`.

### volume.meta

The `volume.meta` file contains the metadata of the replica in a JSON object. For example:

```json
{"Size":1073741824,"Head":"volume-head-002.img","Dirty":false,"Rebuilding":false,"Error":"","Parent":"volume-snap-snap2.img","SectorSize":4096,"BackingFilePath":"","Encrypted":false}
```

| Field | Description |
|-------|-------------|
| `Size` | The size of the volume in bytes. |
| `Head` | The name of the current head file. |
| `Dirty` | `true` while the replica is open by an engine. It is set to `false` when the replica is closed cleanly. A replica that is `true` while no engine is running was not closed cleanly, for example because of a node crash. |
| `Rebuilding` | `true` while the replica is being rebuilt from another replica. A replica with this field set to `true` is incomplete and must not be used to recover data. |
| `Error` | The last error that the replica has recorded. |
| `Parent` | The name of the data file that is the parent of the head file, which is the latest snapshot. It is empty if no snapshot exists. |
| `SectorSize` | The sector size in bytes. |
| `BackingFilePath` | The path of the backing image file, if the volume uses a backing image. |
| `Encrypted` | Whether the volume is encrypted. |

### Snapshot Checksum Files

When a snapshot is hashed, for example by the [snapshot data integrity check](../../advanced-resources/data-integrity/snapshot-data-integrity-check), Longhorn stores the result in `volume-snap-<snapshot-name>.img.checksum`. For example:

```json
{"method":"crc64","checksum":"8f2c4b3a6d1e9a07","change_time":"2026-10-05 00:41:33.123456789 +0000 UTC","last_hashed_at":"2026-10-05T01:10:12Z","silently_corrupted":false}
```

| Field | Description |
|-------|-------------|
| `method` | The hash algorithm. |
| `checksum` | The checksum of the snapshot data. |
| `change_time` | The inode change time (`ctime`) of the snapshot file when it was hashed. If the change time of the file differs from this value, Longhorn considers the file modified after it was hashed. |
| `last_hashed_at` | The time when the snapshot was last hashed. |
| `silently_corrupted` | `true` if Longhorn detects that the checksum of the snapshot data no longer matches the recorded checksum while the change time of the file did not change. |

### revision.counter

The `revision.counter` file is a 4096-byte file that contains the number of write operations the replica has handled as a decimal text value, padded with null bytes. For example, `2`. Longhorn uses it to find the replica with the latest data when it starts a volume or salvages a faulted volume. The counter is updated only when the revision counter is enabled. For more information, see [Revision Counter](../../advanced-resources/deploy/revision_counter).
