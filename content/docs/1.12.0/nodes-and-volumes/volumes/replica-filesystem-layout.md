---
title: Replica Directory Layout
weight: 2
---

The replica directory contains the raw data and metadata for a volume replica on the host's local filesystem. By default, these are located at `/var/lib/longhorn/replicas/`.

## Directory Naming

Each replica is stored in a directory named using the format: `<pvc-name>-<random-id>`.

Example: `pvc-b43f2832-33ef-4ff1-ac7e-b097f71a5977-6f2d4c29`

## Core Files

### 1. `volume.meta`
The "Source of Truth" for the replica's state. It is a JSON file that defines the volume's operational parameters.

* **Size**: The total logical size of the volume in bytes.
* **Head**: The filename of the current active `.img` file receiving writes.
* **Parent**: The snapshot file that the current head is branched from.
* **BackingFilePath**: The path to a Backing Image, if used.
* **backupBlockSize**: (Added in v1.10.0) The block size used for backups (e.g., `2097152` for 2MiB or `16777216` for 16MiB).

### 2. `revision.counter`
A critical metadata file used for data consistency. It contains a single integer that increments with every write operation. When a replica starts, Longhorn compares the `revision.counter` across all replicas; the one with the highest number is considered the most up-to-date.

### 3. `volume-head-###.img`
A **sparse file** representing the "live" data layer. 
* All new writes are directed here. 
* It only consumes physical disk space for written blocks, even if its logical size matches the volume capacity.

### 4. `volume-snap-<name>.img`
Read-only binary files created during a snapshot. 
* Once a snapshot is completed, the `.img` file becomes immutable.
* These files represent the volume's state at a specific point in time.

### 5. Metadata Files (`.img.meta`)
Every `.img` file has a corresponding `.img.meta` JSON file.
* **Name**: Internal identifier for the image.
* **Parent**: The UUID/Name of the previous snapshot. This creates the **Snapshot Chain** (a linked list).
* **UserCreated**: Indicates if the snapshot was user-triggered or system-generated (e.g., during a rebuild).

## Data Read Logic

Longhorn employs a "Top-Down" lookup strategy:
1. **Active Head**: The engine first checks the `volume-head`.
2. **Chain Traversal**: If the block isn't found, it follows the `Parent` link in the `.img.meta` to the previous snapshot.
3. **Base Layer**: It continues down the chain until the data is located or the beginning of the volume is reached.

## Troubleshooting

If a replica fails with an "invalid chain" error, administrators can inspect the `Parent` fields in the `.img.meta` files to ensure they form an unbroken sequence pointing to existing files on the disk.