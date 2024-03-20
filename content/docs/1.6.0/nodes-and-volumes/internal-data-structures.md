---
title: Internal Data Structures
weight: 3
---

**Table of Contents**
- [Node Disk](#node-disk)
  - [Filesystem-Type Disk](#filesystem-type-disk)
  - [Block-Type Disk](#block-type-disk)
- [Replica Directory on Node Disk](#replica-directory-on-node-disk)

## Node Disk

### Filesystem-Type Disk

A filesystem-type disk contains a configuration file named `longhorn-disk.cfg` and a directory called `replicas` that stores replica directories for volumes. The `longhorn-disk.cfg` file contains a JSON object with a single key `diskUUID` whose value is a 36-character UUID string, as shown below:
```
{
  "diskUUID": "${UUID}"
}
```

### Block-Type Disk

A block-type disk is managed by the Storage Performance Development Kit (SPDK). SPDK constructs a logical volume store (lvstore) that utilizes the super blob feature of the blobstore to hold the UUID and other metadata. The blobstore types are implemented within the blobstore itself and are persisted on disk.

## Replica Directory on Node Disk

When creating a Longhorn V1 volume, the Longhorn system creates its downstream replicas on filesystem-type disks. The path of a replica directory follows the pattern ${DISK_PATH}/replicas/${VOLUME_NAME}-${8-CHAR_ID}. A newly created volume replica directory will contain the following files:

```
revision.counter
volume-head-000.img
volume-head-000.img.meta
volume.meta
```

- revision.counter: Records the latest revision count of the replica for the volume.
- volume-head-000.img: The actual data file containing the volume data.
- volume-head-000.img.meta: Stores metadata related to the volume-head-000.img file, including the file name, parent file, creation timestamp, and other attributes.
- volume.meta: Records the attributes of the volume, such as size, current head file, parent snapshot, and other metadata.

After creating multiple snapshots, the disk chain will look like this:

```
snap 1 -----> snap 2 -----> ... -----> snap N -----> volume head
```

The file list of a practical volume containing two snapshots and one volume head might look like this:

```
revision.counter
volume-head-002.img
volume-head-002.img.meta
volume-snap-2e8bf0e9-3751-479c-a560-96a275d2672c.img
volume-snap-2e8bf0e9-3751-479c-a560-96a275d2672c.img.meta
volume-snap-dd51b6b5-c62a-4676-a0d1-9a61c5ff0907.img
volume-snap-dd51b6b5-c62a-4676-a0d1-9a61c5ff0907.img.meta
volume.meta
```

In this example, the disk chain is:
```
96a275d2672c -----> 9a61c5ff0907 -----> volume-head-002
```
Where 96a275d2672c and 9a61c5ff0907 are abbreviations for the snapshot file names.

The contents of the volume.meta and image metadata files (*.img.meta) are:
```
// volume.meta
{
  "Size": 2147483648,
  "Head": "volume-head-002.img",
  "Dirty": true,
  "Rebuilding": false,
  "Error": "",
  "Parent": "volume-snap-dd51b6b5-c62a-4676-a0d1-9a61c5ff0907.img",
  "SectorSize": 512,
  "BackingFilePath": ""
}

// volume-head-002.img.meta
{
  "Name": "volume-head-002.img",
  "Parent": "volume-snap-dd51b6b5-c62a-4676-a0d1-9a61c5ff0907.img",
  "Removed": false,
  "UserCreated": false,
  "Created": "2024-03-09T07:33:16Z",
  "Labels": null
}

// volume-snap-dd51b6b5-c62a-4676-a0d1-9a61c5ff0907.img.meta
{
  "Name": "volume-head-001.img",
  "Parent": "volume-snap-2e8bf0e9-3751-479c-a560-96a275d2672c.img",
  "Removed": false,
  "UserCreated": true,
  "Created": "2024-03-09T07:33:16Z",
  "Labels": null
}

// volume-snap-2e8bf0e9-3751-479c-a560-96a275d2672c.img.meta
{
  "Name": "volume-head-000.img",
  "Parent": "",
  "Removed": false,
  "UserCreated": true,
  "Created": "2024-03-09T07:32:51Z",
  "Labels": null
}
```

The `.img.meta` files store metadata related to the corresponding `.img` data files in the disk chain. The metadata files contain information about the relationships between the data files, which helps maintain the integrity of the disk chain and facilitate operations such as snapshots and rebuilds.

> **NOTICE**
>
> You can ignore the Name field in the .img.meta. The Parent field refers to the name of the parent .img file.

The relationship between the `.img.meta` files can be described as follows:
  - Parent-Child Relationship: Each `.img.meta` file contains a `Parent` field that references the `.img` file from which the current data file was derived. This creates a parent-child relationship between the data files, forming the disk chain.
  - Head File: The `volume.meta` file contains a `Head` field that specifies the current head data file, which represents the latest state of the volume. All other data files in the chain are snapshots or historical versions of the volume.
  - Snapshot Lineage: By following the Parent references in the `.img.meta` files, you can trace the lineage of snapshots back to the initial base data file. This lineage forms the disk chain, where each snapshot points to its parent snapshot or the base data file.

By maintaining this relationship between the `.img.meta` files, Longhorn can manage the disk chain, create new snapshots, and perform operations like rebuilding volumes from existing snapshots or the head data file.