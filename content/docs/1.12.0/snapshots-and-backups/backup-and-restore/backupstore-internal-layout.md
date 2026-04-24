---
title: Backupstore Internal Structure
weight: 2
---

The backupstore is the external storage location where Longhorn backups are saved. It can be either an NFS share, CIFS share, or an S3-compatible object store. Unlike the local replica directory, the Backupstore is designed for **deduplication** and **incremental storage**, breaking large volumes into small, manageable blocks.

## Directory Structure Overview

The root of the backupstore contains a `volumes` directory. Inside, each volume is organized using a hashed path to ensure scalability:

```text
backupstore/
└── volumes/
    └── 4b/
        └── e2/
            └── [volume-name]/
                ├── volume.cfg
                ├── backups/
                │   ├── backup_backup-01.cfg
                │   └── backup_backup-02.cfg
                └── blocks/
                    ├── 0a/
                    │   └── 0a1b2c3d... (block file)
                    └── ...
```

## Core Components

### 1. `volume.cfg`

This is the primary configuration file for a specific volume within the backupstore. It tracks the volume's overall metadata and acts as the entry point for Longhorn to discover which backups are available for restoration.

**Example Content (`volume.cfg`):**

```json
{
  "Name": "pvc-b43f2832-33ef-4ff1-ac7e-b097f71a5977",
  "Size": 1073741824,
  "Labels": {
    "BackupTarget": "minio-persistent"
  },
  "CreatedTime": "2026-03-18T14:07:12Z",
  "Backups": {
    "backup-01": {
      "Name": "backup-01",
      "SnapshotName": "snap-457233d...",
      "SnapshotCreated": "2026-03-18T14:50:28Z",
      "CreatedTime": "2026-03-18T15:13:02Z",
      "Size": "128Ki",
      "Labels": null
    }
  }
}
```

**Field Descriptions**:

* **Name**: The original PV/PVC name.
* **Size**: Total provisioned size of the volume in bytes.
* **Backups**: A dictionary indexing all successful backups currently stored in this target.

### 2. The `backups/` Directory

Contains "Manifest" files for every individual backup.

* **`backup_[name].cfg`**: A JSON blueprint for a specific backup point-in-time.

**Example Content (`backup_backup-01.cfg`):**

```json
{
  "Name": "backup-01",
  "VolumeName": "pvc-b43f2832-33ef-4ff1-ac7e-b097f71a5977",
  "SnapshotName": "snap-457233d...",
  "SnapshotCreated": "2026-03-18T14:50:28Z",
  "CreatedTime": "2026-03-18T15:13:02Z",
  "Size": 131072,
  "Blocks": [
    {
      "Address": 0,
      "Size": 2097152,
      "Hash": "0a1b2c3d4e5f..."
    }
  ]
}

```

**Field Descriptions**:

* **Size**: The actual data size of the backup (not the full volume size).
* **Blocks**: An array mapping the volume's offset (`Address`) to a specific physical chunk in the `blocks/` directory via its `Hash`.

### 3. The `blocks/` Directory

This is where the actual data resides. Longhorn uses **Content-Addressable Storage**:

* **Chunking**: Volume data is divided into blocks. The **default block size is 2MB** (2097152 bytes), but since v1.10.0, this is configurable up to **16MB**.
* **Hashing**: Each block is hashed (SHA512), and the filename is the hash itself.
* **Deduplication**: If two snapshots share the same data, they reference the same hash, saving significant space.
* **Subdirectories**: Blocks are organized into subdirectories (e.g., `/0a/`) based on the first two characters of their hash to maintain filesystem performance.

## Backup Process Logic

1. **Identification**: Longhorn identifies changed blocks between the current snapshot and the previous backup.
2. **Hashing**: Changed blocks are hashed.
3. **Upload**: Only **new, unique blocks** (hashes not already in the `blocks/` folder) are uploaded.
4. **Manifest Creation**: A new `backup_*.cfg` is created, and `volume.cfg` is updated to include the new entry.

> **Note**: Previous versions of Longhorn used a `last_backup.cfg` file. In modern versions (v1.2.0+), this has been replaced by an asynchronous Custom Resource (CR) model where the cluster tracks the state directly, making `last_backup.cfg` obsolete.
