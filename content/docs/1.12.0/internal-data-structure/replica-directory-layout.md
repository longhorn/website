---
title: Replica Directory Layout
weight: 2
---

The replica directory contains the raw data and metadata for a volume replica on the host's local filesystem. By default, these are located at `/var/lib/longhorn/replicas/`.

## Directory Naming

Each replica is stored in a directory named using the format: `<pvc-name>-<random-id>`.

For example: `pvc-840804d8-6f11-49fd-afae-54bc5be639de-6f2d4c29`

## Core Files

### 1. `volume.meta`

The "Source of Truth" for the replica's state. It is a JSON file that defines the volume's parameters.

- **Size**: The total size of the volume in bytes.
- **Head**: The filename of the current active `.img` file receiving writes.
- **Parent**: The snapshot file that the current head is branched from.
- **BackingFilePath**: The path to a Backing Image, if one is being used.

### 2. `volume-head-###.img`

This is a **sparse file** representing the "live" data layer. 

- All new writes to the volume are directed here. 
- As a sparse file, it only consumes physical disk space for the blocks that have actually been written to, even if the logical size matches the full volume.

### 3. `volume-snap-<name>.img`

These are read-only binary files created when a snapshot is taken. 

- Once a snapshot is completed, the `.img` file becomes immutable.
- The data in these files is used to reconstruct the volume state at a specific point in time.

### 4. Metadata Files (`.img.meta`)

Every `.img` file (both head and snapshots) has a corresponding `.img.meta` JSON file.

- **Name**: The internal identifier for the image.
- **Parent**: The UUID of the previous snapshot in the chain. This creates the **Snapshot Chain** (a linked list) that Longhorn traverses to read data.
- **UserCreated**: A boolean indicating if the snapshot was triggered by a user or an internal Longhorn process (like a system-generated snapshot for rebuilding).

## Data Read Logic

Longhorn uses a "Top-Down" lookup:

1. When a read request occurs, the engine first looks at the **active head**.
2. If the requested block is not in the head, it moves to the **Parent** defined in the metadata.
3. It continues traversing down the chain through snapshots until it finds the data or reaches the base layer.

## Troubleshooting

If a replica fails to start with an "invalid chain" error, developers can inspect the `.img.meta` files to ensure the `Parent` fields correctly point to existing files on the disk, forming an unbroken sequence.
