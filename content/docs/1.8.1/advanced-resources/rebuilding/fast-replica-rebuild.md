---
title: Fast Replica Rebuild
weight: 5
---

Longhorn supports fast replica rebuilding based on the checksums of snapshot disk files.

## Introduction

The legacy replica rebuilding process walks through all snapshot disk files. For each data block, the client (healthy replica) hashes the local data block as well as requests the checksum of the corresponding data block on the remote side (rebuilt replica). Then, the client compares the two checksums to determine if the data block needs to be sent to the remote side and override the data block. Thus, it is an IO- and computing-intensive process, especially if the volume is large or contains a large number of snapshot files.

If users enable the snapshot data integrity check feature by configuring `snapshot-data-integrity` to `enabled` or `fast-check`, the change timestamps and the checksums of snapshot disk files are recorded. As long as the two below conditions are met, we can skip the synchronization of the snapshot disk file. 
- The change timestamps on the snapshot disk file and the value recorded are the same.
- Both the local and remote snapshot disk files have the same checksum.

Then, a reduction in the number of unnecessary computations can speed up the entire process as well as reduce the impact on the system performance.

## Settings
### Global Settings
- fast-replica-rebuild-enabled <br>

    The setting enables fast replica rebuilding feature. It relies on the checksums of snapshot disk files, so setting the snapshot-data-integrity to **enable** or **fast-check** is a prerequisite. Please refer to [Snapshot Data Integrity Check](../../data-integrity/snapshot-data-integrity-check).

