---
title: Backupstore Layout
weight: 2
---

The backupstore is the external storage location where Longhorn backups are saved. It can be either an NFS share, CIFS share, or an S3-compatible object store. Unlike the local replica directory, the Backupstore is designed for **global deduplication** and **incremental storage**, breaking large volume images into small, manageable chunks.

## Directory Structure Overview

The root of the backupstore contains a `volumes` directory. Inside, each volume has its own unique directory structure:

```text
backupstore/
└── volumes/
    └── [volume-name]/
        ├── backup.cfg
        ├── last_backup.cfg
        ├── backups/
        │   ├── backup_backup-01.cfg
        │   └── backup_backup-02.cfg
        └── blocks/
            ├── 0a/
            │   └── 0a1b2c3d... (block file)
            ├── 1f/
            │   └── 1f8e9d7c... (block file)
            └── ...
```

## Core Components

### 1. The `blocks/` Directory

This is where the actual data resides. Longhorn uses **Content-Addressable Storage**:

- **Chunking**: Volume data is divided into **2MB blocks**.
- **Hashing**: Each block is hashed using **SHA512**.
- **Deduplication**: The filename of the block is its hash. If two different snapshots contain the same 2MB of data, they both point to the same file in the `blocks/` directory. This significantly reduces storage consumption for incremental backups.
- **Subdirectories**: To prevent having thousands of files in a single directory (which can cause performance issues on certain filesystems), Longhorn organizes blocks into subdirectories based on the first two characters of their hash.

### 2. The `backups/` Directory

This directory contains "Manifest" files for every backup taken.

- **`backup_[name].cfg`**: A JSON file that acts as a blueprint for a specific backup. It contains:
- The snapshot name and creation time.
- A mapping of the volume's address space to the specific hashes in the `blocks/` directory.
- Metadata like the original volume size and labels.

### 3. `backup.cfg`

A global configuration file for the volume within the backupstore. It tracks the volume's overall metadata and acts as the entry point for Longhorn to discover which backups are available for restoration.

### 4. `last_backup.cfg`

A small pointer file that records the name of the most recent successful backup. This is used by Longhorn to speed up incremental backup calculations.

## Backup Process Logic

When a new backup is initiated:

1. Longhorn identifies changed 2MB blocks between the current snapshot and the last backup.
2. It hashes the changed blocks.
3. If a block with that hash already exists in the `blocks/` directory (from a previous backup or a different volume), it skips the upload.
4. Only **new, unique blocks** are uploaded.
5. A new `.cfg` file is created in the `backups/` folder, referencing both the newly uploaded blocks and the existing ones.

## Troubleshooting and Maintenance

- **Orphaned Blocks**: Occasionally, if a backup is manually deleted from the storage backend rather than the Longhorn UI, blocks may remain in the `blocks/` folder. Longhorn's "Job" system handles the cleanup of these orphaned blocks.
- **Integrity**: Because filenames are hashes, data corruption can be detected by re-hashing a block and comparing it to its filename.
