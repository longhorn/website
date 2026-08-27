---
title: Sharding with Erasure Coding (Experimental)
weight: 60
---

> **Note**: This feature is **Experimental** and should only be used for evaluation and testing. It is not recommended for production use.

Starting with v1.12.1, the Longhorn V2 Data Engine supports **sharding** as an alternative data protection strategy to replication.

With replication, every replica stores a full copy of the volume data. Longhorn uses thin provisioning and supports over-provisioning, allowing the configured volume size to exceed the currently available physical storage. However, each replica is stored on a single disk, so the actual data written to a volume cannot exceed the available capacity of the disk hosting each replica. With n replicas, storing `x` bytes of user data consumes approximately `n × x` bytes of physical storage.

With sharding, Longhorn uses erasure coding to encode written data into `k` data chunks and `m` parity chunks, which are distributed across different nodes. Unlike replication, no node stores a complete copy of the volume. This enables a volume to scale beyond the capacity of a single disk while requiring less physical storage than replication to tolerate the same number of failures.

A sharded volume can tolerate the loss of up to `m` chunks while remaining available. When chunks are unavailable, the volume continues to serve read and write operations using the remaining chunks and parity information. Longhorn reconstructs the missing data and rebuilds the lost chunks in the background.

## Sharding compared to replication

| Aspect              | Replication (RAID1)                      | Sharding (Erasure Coding)           |
| ------------------- | ---------------------------------------- | ----------------------------------- |
| Usable capacity     | `1 / numberOfReplicas` of the disk space | `k / (k + m)` of the disk space     |
| Maximum volume size | Limited to one disk or node              | Can be larger than one disk or node |
| Fault tolerance     | Up to `numberOfReplicas - 1` failures    | Up to `m` failures (`parityChunks`) |
| Recovery            | Full copy from a healthy replica         | Rebuild only the failed chunk       |
| CPU overhead        | Low                                      | Higher (encoding and decoding)      |
| Maturity            | Generally available                      | Experimental                        |

Here, *disk space* means the total space used to store the volume, counting every replica copy or every data and parity chunk.

Examples:

- A `2 + 1` layout (`dataChunks: 2`, `parityChunks: 1`) survives one failure and lets you use **66%** of the disk space. Two replicas survive the same one failure but let you use only **50%**.
- A `4 + 2` layout survives two failures at once and lets you use **66%** of the disk space. Three replicas survive the same two failures but let you use only **33%**.

## Requirements

- **V2 Data Engine enabled.** Sharding only works with the V2 Data Engine.
- **At least `k + m` nodes with schedulable V2 disks.** Each chunk requires its own node and a V2 (block-type) disk with sufficient capacity. For example, a `4 + 2` layout needs at least six nodes.

## Supported functionality

Sharded volumes support the following operations:

- Create, attach, detach, and delete the volume
- Read and write through the block device frontend
- ReadWriteMany (RWX) access mode
- Create, delete, revert, and purge snapshots
- Expand the volume online and offline, up to 10 times the size the volume was created with
- Keep reading, and rebuild chunks in the background, when up to `m` chunks fail
- Volume encryption

> **Note**: A sharded volume can grow in place only up to 10 times its original size. The erasure-coding metadata is reserved once when the volume is created and does not grow later, so this limit is fixed for the life of the volume. To go beyond it, create a new, larger volume and copy the data over. Growing the shard group itself is not supported yet.

## Unsupported functionality

The following features are not supported in the initial release:

- Backup and restore, including creating a volume from a backup
- Volume cloning (creating a volume from another volume or snapshot)
- Backing images
- Disaster recovery (standby) volumes
- Live migration (including the migratable RWX variant)
- Snapshot data integrity check (snapshot hashing)
- Changing the replica count or rebuilding replicas. A sharded volume has no replicas; parity chunks provide fault tolerance instead.

Creating a sharded volume through the Longhorn UI is not available yet. Use a StorageClass manifest as described in [How to use](#how-to-use).

## Data layout parameters

You set the data layout through StorageClass parameters. The `dataLayout.*` parameters only apply to V2 volumes.

| Parameter                 | Description                                                                                                           |
| ------------------------- | --------------------------------------------------------------------------------------------------------------------- |
| `dataLayout.type`         | `sharded` to use erasure coding, or `replicated` (the default) for RAID1.                                             |
| `dataLayout.mode`         | `erasureCoding` for sharded volumes.                                                                                  |
| `dataLayout.dataChunks`   | Required for sharded volumes. The number of data chunks (`k`); at least 1.                                            |
| `dataLayout.parityChunks` | Required for sharded volumes. The number of parity chunks (`m`); at least 1. The volume tolerates up to `m` failures. |
| `dataLayout.stripSizeKB`  | Required for sharded volumes. Strip size in KiB. Must be a power of two between 4 and 1024.                           |

The total number of chunks (`dataChunks + parityChunks`) cannot be more than 32.

> **Note**: The data layout is immutable once the volume is created. You cannot switch a volume between `replicated` and `sharded`, and you cannot change `dataChunks`, `parityChunks`, or `stripSizeKB` later. A sharded volume always uses `numberOfReplicas: 1` and `dataLocality: disabled`, which Longhorn sets automatically.

## How to use

Create a sharded volume by using a StorageClass that sets the `dataLayout.*` parameters, then reference the StorageClass from a PersistentVolumeClaim. For the step-by-step manifests, see [Creating V2 Longhorn Volumes with kubectl (sharding)](../../../nodes-and-volumes/volumes/create-volumes#creating-v2-longhorn-volumes-with-kubectl-sharding).

## Inspecting the shards

Instead of replicas, a sharded volume uses the following Longhorn resources:

- `ShardGroup` (short name `lhsg`): the erasure-coded array for the volume. Its state tells you the overall health of the array (`healthy`, `degraded`, `offline`, `rebuilding`, `growing`).
- `Shard` (short name `lhsd`): one member of the EC array. Its role is `data` or `parity`, and its state is `normal`, `failed`, or `replacing`.

List both with kubectl:

```bash
kubectl -n longhorn-system get shardgroup,shard
```

The `ShardGroup` shows the overall health and how many chunks have failed. Each `Shard` shows its position in the group, its role (`data` or `parity`), the node it runs on, and its state.

## Reference

Original GitHub issue tracking V2 Data Engine sharding: [GitHub Issue #1061](https://github.com/longhorn/longhorn/issues/1061)
