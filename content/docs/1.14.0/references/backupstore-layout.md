---
title: Backupstore Layout
weight: 8
---

This page describes the directory structure and the files that Longhorn writes to a backupstore. The information helps users and developers understand the internal data structures of Longhorn, for example when [recovering a backup without a Longhorn system](../../advanced-resources/data-recovery/recover-without-system) or investigating a backup that is not synchronized correctly.

> **Warning:** The lifecycle of the data in a backupstore is entirely managed by Longhorn. Do not create, modify, or delete any file in the backupstore manually, and do not configure a retention or lifecycle policy directly on the backupstore. Doing so can make the backups unrestorable. See [Setting a Backup Target](../../snapshots-and-backups/backup-and-restore/set-backup-target).

## Overview

Longhorn stores all of its data under a top-level directory named `backupstore` in the backup target. For example:

| Backup target | Location of the `backupstore` directory |
|---------------|-----------------------------------------|
| `nfs://<server>:/opt/backupstore` | `/opt/backupstore/backupstore/` on the NFS server |
| `s3://<bucket>@<region>/` | The `backupstore/` prefix in the bucket |
| `s3://<bucket>@<region>/<path>/` | The `<path>/backupstore/` prefix in the bucket |

Object storage services such as S3 do not have real directories. The paths on this page are the prefixes of the object keys.

The `backupstore` directory has the following structure:

```
backupstore/
├── volumes/            # Backups of volumes
├── backing-images/     # Backups of backing images
└── system-backups/     # System backups
```

## Volume Backups

The data of each backed-up volume is stored in its own directory, which is called a backup volume.

```
backupstore/
└── volumes/
    └── <hash-1>/
        └── <hash-2>/
            └── <volume-name>/
                ├── volume.cfg
                ├── backups/
                │   ├── backup_<backup-name>.cfg
                │   └── backup_<backup-name>.cfg
                ├── blocks/
                │   └── <checksum-1>/
                │       └── <checksum-2>/
                │           └── <checksum>.blk
                └── locks/
                    └── lock-<id>.lck
```

The following is a real example of a backup volume `pvc-0123abcd-test` that has two backups and uses the default 2 MiB block size:

```
backupstore/volumes/a7/9b/pvc-0123abcd-test/
├── volume.cfg
├── backups/
│   ├── backup_backup-854f6ced7b4942d4.cfg
│   └── backup_backup-bbc68bd15e6a416c.cfg
└── blocks/
    ├── 4b/ca/4bcaade1b34a396dc3c512d2c3b226c423969eb5093529291ce89ebad285d140.blk
    ├── bb/9d/bb9d1ff59852efbef9cb0f8c7c97052b455a2520a3b91ae2b8f17765d234fc58.blk
    ├── d9/cf/d9cf3e0942c46cf9c43d8f4e152c761bb88b3e8a5d9bb127d16d55f8a7402b50.blk
    └── ed/11/ed11a819f39f0f530591a172ab26833ffbe44a5b244f0ec7fc5c8f343fc2044c.blk
```

| Path | Description |
|------|-------------|
| `volumes/<hash-1>/<hash-2>/` | Two levels of directories that spread the backup volumes over many directories. `<hash-1>` is the first two characters and `<hash-2>` is the third and fourth characters of the hexadecimal SHA-512 hash of the volume name. |
| `<volume-name>/` | The directory of the backup volume. The name is the same as the name of the volume that was backed up. |
| `volume.cfg` | The metadata of the backup volume. See [volume.cfg](#volumecfg). |
| `backups/backup_<backup-name>.cfg` | The metadata of a backup, one file for each backup. `<backup-name>` is the name of the Longhorn Backup, for example `backup-854f6ced7b4942d4`. See [backup_&lt;backup-name&gt;.cfg](#backup_backup-namecfg). |
| `blocks/<checksum-1>/<checksum-2>/<checksum>.blk` | The data blocks of all the backups of the volume. `<checksum>` is the checksum of the uncompressed block, which is the SHA-512 hash truncated to 64 hexadecimal characters. The two directory levels are the first two characters and the third and fourth characters of the checksum. See [Block Files](#block-files-blk). |
| `locks/lock-<id>.lck` | The lock files that Longhorn creates while it creates a backup, restores a backup, or deletes a backup, to prevent conflicting operations on the same backup volume. The lock files are removed when the operation completes, so the `locks` directory is usually empty or absent. A lock that is not renewed expires after 150 seconds. |

### volume.cfg

The `volume.cfg` file is a JSON file that contains the metadata of the backup volume. For example:

```json
{"Name":"pvc-0123abcd-test","Size":"18874368","Labels":{"k":"v"},"CreatedTime":"2026-10-05T00:40:38Z","LastBackupName":"backup-854f6ced7b4942d4","LastBackupAt":"2026-10-05T00:40:38Z","BlockCount":"4","BackingImageName":"\"\"","BackingImageChecksum":"\"\"","CompressionMethod":"\"lz4\"","StorageClassName":"\"\"","DataEngine":"\"v1\"","LinkedCloneSourceVolume":"\"\"","LinkedCloneSourceSnapshot":"\"\""}
```

| Field | Description |
|-------|-------------|
| `Name` | The name of the volume. |
| `Size` | The size of the volume in bytes. |
| `Labels` | The labels of the volume, for example the recurring job labels. |
| `CreatedTime` | The time when the backup volume was created. |
| `LastBackupName` | The name of the most recent backup of the volume. |
| `LastBackupAt` | The creation time of the snapshot that the most recent backup was created from. |
| `BlockCount` | The number of distinct blocks that are stored in the `blocks` directory for the volume. |
| `BackingImageName`, `BackingImageChecksum` | The name and checksum of the backing image of the volume. They are empty if the volume does not use a backing image. |
| `CompressionMethod` | The compression method of the blocks, which is `none`, `lz4`, or `gzip`. |
| `StorageClassName` | The name of the StorageClass of the volume. |
| `DataEngine` | The data engine of the volume, `v1` or `v2`. |
| `LinkedCloneSourceVolume`, `LinkedCloneSourceSnapshot` | The source volume and snapshot of a linked-clone volume. They are empty for other volumes. |

> **Note:** Some string fields, for example `CompressionMethod`, are stored with extra quotation marks, such as `"\"lz4\""`. This is the format that Longhorn writes and reads, and it does not affect the value.

### backup_&lt;backup-name&gt;.cfg

Each `backup_<backup-name>.cfg` file is a JSON file that contains the metadata of one backup and the list of blocks that make up the backup. For example:

```json
{"Name":"backup-854f6ced7b4942d4","VolumeName":"pvc-0123abcd-test","SnapshotName":"snap-1","SnapshotCreatedAt":"2026-10-05T00:40:38Z","CreatedTime":"2026-10-05T00:40:43Z","Size":"6291456","Labels":{"k":"v"},"Parameters":null,"IsIncremental":true,"CompressionMethod":"lz4","NewlyUploadedDataSize":"2097171","ReUploadedDataSize":"0","ProcessingBlocks":null,"Blocks":[{"Offset":0,"BlockChecksum":"d9cf3e0942c46cf9c43d8f4e152c761bb88b3e8a5d9bb127d16d55f8a7402b50"},{"Offset":2097152,"BlockChecksum":"bb9d1ff59852efbef9cb0f8c7c97052b455a2520a3b91ae2b8f17765d234fc58"},{"Offset":4194304,"BlockChecksum":"4bcaade1b34a396dc3c512d2c3b226c423969eb5093529291ce89ebad285d140"}],"SingleFile":{"FilePath":""}}
```

| Field | Description |
|-------|-------------|
| `Name` | The name of the backup. |
| `VolumeName` | The name of the volume that the backup belongs to. |
| `SnapshotName` | The name of the snapshot that the backup was created from. |
| `SnapshotCreatedAt` | The creation time of the snapshot. |
| `CreatedTime` | The time when the backup was completed. While the backup is still in progress, this field is empty and the backup is not listed. |
| `Size` | The size of the backup data in bytes, which is the number of blocks multiplied by the block size. |
| `Labels` | The labels of the backup. |
| `Parameters` | The parameters that were passed when the backup was created. For example, `{"backup-block-size":"16Mi"}` records the [backup block size](../../snapshots-and-backups/backup-and-restore/configure-backup-block-size). If it is `null`, the default block size of 2 MiB is used. |
| `IsIncremental` | `true` if the backup was created incrementally from the previous backup, `false` if all the blocks of the snapshot were scanned. |
| `CompressionMethod` | The compression method of the blocks of this backup. |
| `NewlyUploadedDataSize` | The size in bytes of the compressed data that was newly uploaded for this backup. |
| `ReUploadedDataSize` | The size in bytes of the compressed data that was uploaded again even though the block already existed, which happens when a full backup is created. |
| `Blocks` | The list of the blocks of the backup. `Offset` is the position of the block in the volume in bytes, and `BlockChecksum` is the checksum that names the file in the `blocks` directory. |

The `Blocks` list contains an entry for every block of the data in the backup, not only the blocks that changed since the previous backup. This is why each backup can be restored independently of the other backups, and why the blocks that did not change are shared by the backups. In the example above, the two backups share the blocks `bb9d…` and `4bca…`, and only differ in the first block of the volume, `d9cf…` and `ed11…`.

### Block Files (`.blk`)

A block file contains the data of one block of the volume. Its size before compression is the backup block size, 2 MiB by default. The block size is configurable when the volume is created. The supported sizes are 2 MiB and 16 MiB. All the blocks of a backup have the same size, which is recorded in the `Parameters` field of the backup. See [Configure The Block Size Of Backup](../../snapshots-and-backups/backup-and-restore/configure-backup-block-size).

Longhorn compresses each block with the compression method in `volume.cfg` and in the backup configuration file. A file name is the checksum of the uncompressed data, so blocks with identical content are stored only once for a volume, and are shared by all the backups of the volume.

When a backup is deleted, Longhorn removes its configuration file first. Then it removes only the blocks that are no longer referenced by any remaining backup of the volume. The block removal is skipped when it is not safe to do it, for example when another backup of the volume is still in progress.

## Backing Image Backups

The backups of backing images are stored in the `backing-images` directory:

```
backupstore/
└── backing-images/
    ├── backing-images/
    │   └── <backing-image-name>/
    │       └── backing-image.cfg
    └── blocks/
        └── <checksum-1>/
            └── <checksum-2>/
                └── <checksum>.blk
```

| Path | Description |
|------|-------------|
| `backing-images/backing-images/<backing-image-name>/backing-image.cfg` | A JSON file with the metadata of the backing image backup, which includes the name, size, checksum, labels, compression method, creation and completion time, and the list of blocks of the backing image. |
| `backing-images/blocks/<checksum-1>/<checksum-2>/<checksum>.blk` | The compressed blocks of all the backing images. They use the same checksum-based naming as the volume blocks, and are shared by all the backing images. |

For more information, see [Backing Image Backup](../../advanced-resources/backing-image/backing-image-backup).

## System Backups

The system backups are stored in the `system-backups` directory:

```
backupstore/
└── system-backups/
    └── <longhorn-version>/
        └── <system-backup-name>/
            ├── system-backup.cfg
            └── system-backup.zip
```

| Path | Description |
|------|-------------|
| `system-backups/<longhorn-version>/<system-backup-name>/` | The directory of a system backup. `<longhorn-version>` is the version of Longhorn that created the system backup, for example `v{{< current-version >}}`. |
| `system-backup.cfg` | A JSON file with the metadata of the system backup: `Name`, `LonghornVersion`, `LonghornGitCommit`, `BackupTargetURL`, `ManagerImage`, `EngineImage`, `CreatedAt`, and `Checksum`. `Checksum` is the SHA-256 checksum of `system-backup.zip`, which Longhorn uses to verify the file when it downloads it. |
| `system-backup.zip` | A ZIP archive of the Longhorn resources (custom resources and related Kubernetes objects) that were backed up. |

For more information, see [Backup Longhorn System](../../advanced-resources/system-backup-restore/backup-longhorn-system).
