---
title: V1 and V2 Volume Feature Support
weight: 4
---

This page summarizes the expected behavior differences between v1 and v2 volumes and provides a feature support matrix for the Longhorn v1.12.0 documentation set.

## Expected Behavioral Differences

### Snapshot Deletion Behavior

When deleting the snapshot that is the direct parent of `volume-head`, v1 and v2 volumes behave differently.

| Behavior | v1 Volume | v2 Volume |
| --- | --- | --- |
| Snapshot list result | The snapshot remains in the list and is marked as removed. | The snapshot is deleted immediately and disappears from the list. |
| Snapshot CR behavior | The Snapshot CR remains and reflects the removed state. | The Snapshot CR is removed immediately. |
| Reason | The latest snapshot cannot be coalesced into the live `volume-head` immediately, so cleanup is deferred until a later purge opportunity. | The v2 data engine supports live merging of the parent snapshot into `volume-head`, so cleanup can finish immediately. |
| Cleanup timing | Cleanup happens later, typically after another snapshot is created and purge can proceed. | Cleanup completes as part of the delete operation. |

This difference is expected and is the behavior referenced by [longhorn/longhorn#7624](https://github.com/longhorn/longhorn/issues/7624).

### Snapshot Purge Behavior

Snapshot purge behavior also differs between v1 and v2 volumes.

In v1, snapshot deletion and snapshot purge are clearly separated operations. Snapshot deletion marks a snapshot as removed but does not free its space. The actual data coalescing is handled later by a separate purge operation, which is subject to a per-node concurrency limit (`Snapshot Heavy Task Concurrent Limit`). As a result, users may observe removed snapshots in the snapshot chain or API response until purge completes.

In v2, snapshot deletion itself performs the coalesce immediately (the underlying storage layer merges the snapshot data into its child automatically). Snapshot purge is a separate bulk operation that removes all eligible system-created snapshots (those not created by the user) from the replica chain. Because both delete and purge complete inline without concurrency throttling, v2 volumes are unlikely to retain intermediate removed snapshot states visible to users.

In general, the expected differences are as follows:

| Behavior | v1 Volume | v2 Volume |
| --- | --- | --- |
| Delete behavior | Marks the snapshot as removed; coalesce is deferred to purge. | Deletes and coalesces the snapshot immediately. |
| Purge target | Coalesces all snapshots previously marked as removed. | Removes all system-created (non-user) snapshots from the replica chain. |
| Concurrency control | Purge is subject to a per-node concurrency limit. | No concurrency limit; purge executes immediately. |
| Removed snapshot visibility | Removed snapshots remain visible until purge completes. | Snapshots disappear from the chain as soon as delete or purge finishes. |

## Feature Support Matrix

The following table is adapted from the Longhorn wiki page [V1 and V2 Feature Parities](https://github.com/longhorn/longhorn/wiki/V1-and-V2-Feature-Parities).

| Feature | v1 | v2 | Support Notes |
| --- | --- | --- | --- |
| **Data Protection** |  |  |  |
| Snapshot | ✔️ | ✔️ | - |
| Backup and Restore | ✔️ | ✔️ | - |
| DR Volume | ✔️ | ✔️ | - |
| System Backup and Restore | ✔️ | ✔️ | - |
| Snapshot Data Integrity Check | ✔️ | ✔️ | - |
| **RWX Volume** |  |  |  |
| Creation and Deletion | ✔️ | ✔️ | - |
| Encryption | ✔️ | ✔️ | - |
| Migratable RWX Volume | ✔️ | ✔️ | - |
| **Volume Operations** |  |  |  |
| Volume Expansion | ✔️ | ✔️ | - |
| Volume Cloning | ✔️ | ✔️ | - |
| Fast Volume Cloning | Not planned | ✔️ | - |
| Volume Encryption | ✔️ | ✔️ | - |
| Filesystem Trim | ✔️ | ✔️ | - |
| **Replica Scheduling** |  |  |  |
| Replica Scheduling | ✔️ | ✔️ | - |
| **High Availability** |  |  |  |
| Data Locality: disabled and best-effort | ✔️ | ✔️ | - |
| Data Locality: strict local | ✔️ | Not supported | TBD |
| Auto Balance Replicas | ✔️ | ✔️ | - |
| **Recurring Jobs** |  |  |  |
| Recurring Job | ✔️ | ✔️ | - |
| **Replica Rebuilding** |  |  |  |
| Online Full Rebuilding | ✔️ | ✔️ | - |
| Online Delta Rebuilding | ✔️ | ✔️ | - |
| Online Fast Rebuilding | ✔️ | ✔️ | - |
| Offline Full Rebuilding | ✔️ | ✔️ | - |
| Offline Delta Rebuilding | ✔️ | ✔️ | - |
| Offline Fast Rebuilding | ✔️ | Not supported | TBD |
| QoS | Not supported | ✔️ | - |
| **Backing Image** |  |  |  |
| Creation and Deletion | ✔️ | Not supported | Replaced by Containerized Data Importer (CDI) in v2 |
| Encryption | ✔️ | Not supported | Replaced by Containerized Data Importer (CDI) in v2 |
| Backup | ✔️ | Not supported | Replaced by Containerized Data Importer (CDI) in v2 |
| **Networking** |  |  |  |
| Storage Network | ✔️ | ✔️ | - |
| IPv4 | ✔️ | ✔️ | - |
| IPv6 | ✔️ | ✔️ | - |
| **Orphan Resource** |  |  |  |
| Orphaned Replica Data Management | ✔️ | ✔️ | - |
| Orphaned Instance Management | ✔️ | Not supported | - |
| **Volume Live Migration** |  |  |  |
| Volume Live Migration | ✔️ | ✔️ | - |
| **Engine Live Upgrade** |  |  |  |
| Engine Live Upgrade | ✔️ | Not supported | Supported when upgrading from v1.12.x to v1.13.x |
| **Storage Sharding** |  |  |  |
| Storage Sharding | Not planned | ✔️ | Experimental Feature for v2 |
