---
title: Shallow Copy and Deep Copy
weight: 4
---

The Longhorn V2 data engine uses SPDK's **shallow copy** and **deep copy** primitives for efficient replica rebuilds and data synchronization. These copy mechanisms operate at the cluster level, copying only allocated data and skipping unallocated (zero) regions.

## Shallow Copy

Shallow copy copies only the clusters that the source lvol has allocated, writing them onto the destination bdev. Unallocated clusters in the source are skipped — the destination keeps whatever it already had there.

### Pipelined Shallow Copy

Shallow copy can be pipelined with a configurable depth, allowing concurrent in-flight copy operations. The depth is controlled by the `data-engine-shallow-copy-pipeline-depth` setting:

```json
{"v2": "4"}
```

Default depth is 1 (sequential). Higher values allow more concurrent copy operations, speeding up rebuilds on storage backends that can handle parallel I/O.

### Range Shallow Copy

Range shallow copy copies a specific list of clusters and unmaps (TRIMs) all others on the destination. This is used when the destination already has a partial copy of the data — only the mismatching clusters need to be copied, and the rest are unmapped to ensure consistency.

Range shallow copy is the mechanism used for incremental rebuilds when the destination already has most of the data and only a subset of clusters have changed.

## Deep Copy

Deep copy copies all allocated clusters from the source lvol **and its snapshot ancestors** to a destination bdev. Unlike shallow copy, deep copy reads through the entire snapshot chain, duplicating all data.

Deep copy is used when a complete, independent copy of the data is needed (e.g., for volume cloning or backup operations).

## Rebuild Usage

During a v2 volume rebuild:
1. The engine creates a rebuild snapshot on the source replica
2. The destination head lvol is cloned from the rebuild snapshot (thin clone — no data copied yet)
3. For each snapshot in the chain, shallow copy copies the allocated clusters from source to destination
4. If the destination already has an intact snapshot (from a previous partial rebuild), it is reused — no copy needed
5. If the destination has a corrupted but range-checksum-eligible snapshot, range shallow copy copies only the mismatching clusters

This cluster-level copy approach means that rebuild time and space usage are proportional to the **actual data size**, not the volume's logical size.