---
title: V1 and V2 Volume Feature Support
weight: 4
---

This page summarizes the expected behavior differences between V1 and V2 volumes and provides a feature support matrix for the Longhorn v1.12.0 documentation set.

## Expected Behavioral Differences

### Snapshot Deletion Behavior

When deleting the snapshot that is the direct parent of `volume-head`, V1 and V2 volumes behave differently.

| Behavior | V1 Volume | V2 Volume |
| --- | --- | --- |
| Snapshot list result | The snapshot remains in the list and is marked as removed. | The snapshot is deleted immediately and disappears from the list. |
| Snapshot CR behavior | The Snapshot CR remains and reflects the removed state. | The Snapshot CR is removed immediately. |
| Reason | The latest snapshot cannot be coalesced into the live `volume-head` immediately, so cleanup is deferred until a later purge opportunity. | The V2 Data Engine supports live merging of the parent snapshot into `volume-head`, so cleanup can finish immediately. |
| Cleanup timing | Cleanup happens later, typically after another snapshot is created and purge can proceed. | Cleanup completes as part of the delete operation. |

### Snapshot Purge Behavior

Snapshot purge behavior also differs between V1 and V2 volumes.

In V1, purge is the operation that coalesces snapshots previously marked as removed. It runs separately from snapshot deletion and is subject to a per-node concurrency limit (`Snapshot Heavy Task Concurrent Limit`). As a result, removed snapshots may remain visible in the snapshot chain or API response until purge completes.

In V2, purge runs immediately and removes eligible system-created snapshots (those not created by the user) from the replica chain in one operation. The underlying storage layer performs the merge during the purge.

### Revision Counter Behavior

Revision counter behavior differs between V1 and V2 volumes.

In V1, Longhorn supports revision counters for tracking replica updates. This mechanism can be used during startup and auto-salvage to help identify the replica with the latest update. For more information, see [Revision Counter](../advanced-resources/deploy/revision_counter).

In V2, revision counters are not supported. V2 volumes do not maintain revision-counter-based replica tracking, and V1-specific revision counter settings do not apply.

### Replica Rebuilding Settings

The configuration settings for controlling and optimizing replica rebuilding behaviors differ between V1 and V2 volumes:

- **Replica Rebuild Concurrent Sync Limit**: This setting specifies the maximum number of replicas that can be concurrently synchronized on a single node. This setting applies **only to V1 volumes**.
- **Replica Rebuilding Bandwidth Limit**: This setting specifies the maximum network bandwidth allowed for replica rebuilding tasks. This setting applies **only to V2 volumes**.

## Feature Support Matrix

### Data Protection

| Feature | V1 | V2 | Support Notes |
| --- | --- | --- | --- |
| Snapshot | ✔️ | ✔️ | - |
| Backup and Restore | ✔️ | ✔️ | - |
| DR Volume | ✔️ | ✔️ | - |
| System Backup and Restore | ✔️ | ✔️ | - |
| Snapshot Data Integrity Check | ✔️ | ✔️ | - |

### RWX Volume

| Feature | V1 | V2 | Support Notes |
| --- | --- | --- | --- |
| Creation and Deletion | ✔️ | ✔️ | - |
| Encryption | ✔️ | ✔️ | - |
| Migratable RWX Volume | ✔️ | ✔️ | - |

### Volume Operations

| Feature | V1 | V2 | Support Notes |
| --- | --- | --- | --- |
| Volume Expansion | ✔️ | ✔️ | - |
| Volume Cloning | ✔️ | ✔️ | - |
| Fast Volume Cloning | Not planned | Planned | Planned for Longhorn v1.12.1. |
| Volume Encryption | ✔️ | ✔️ | - |
| Filesystem Trim | ✔️ | ✔️ | - |

### Replica Scheduling

| Feature | V1 | V2 | Support Notes |
| --- | --- | --- | --- |
| Replica Scheduling | ✔️ | ✔️ | - |

### High Availability

| Feature | V1 | V2 | Support Notes |
| --- | --- | --- | --- |
| Data Locality: disabled and best-effort | ✔️ | ✔️ | - |
| Data Locality: strict local | ✔️ | Not supported | TBD |
| Auto Balance Replicas | ✔️ | ✔️ | - |

### Recurring Jobs

| Feature | V1 | V2 | Support Notes |
| --- | --- | --- | --- |
| Recurring Job | ✔️ | ✔️ | - |

### Replica Rebuilding

| Feature | V1 | V2 | Support Notes |
| --- | --- | --- | --- |
| Online Full Rebuilding | ✔️ | ✔️ | - |
| Online Delta Rebuilding | ✔️ | ✔️ | - |
| Online Fast Rebuilding | ✔️ | ✔️ | - |
| Offline Full Rebuilding | ✔️ | ✔️ | - |
| Offline Delta Rebuilding | ✔️ | ✔️ | - |
| Offline Fast Rebuilding | ✔️ | Not supported | TBD |
| QoS | Not supported | ✔️ | - |
| Replica Rebuild Concurrent Sync Limit | ✔️ | Not supported | Only supported for V1 volumes. |
| Replica Rebuilding Bandwidth Limit | Not supported | ✔️ | Only supported for V2 volumes. |

### Backing Image

| Feature | V1 | V2 | Support Notes |
| --- | --- | --- | --- |
| Creation and Deletion | ✔️ | Not supported | Replaced by Containerized Data Importer (CDI) in V2 |
| Encryption | ✔️ | Not supported | Replaced by Containerized Data Importer (CDI) in V2 |
| Backup | ✔️ | Not supported | Replaced by Containerized Data Importer (CDI) in V2 |

### Networking

| Feature | V1 | V2 | Support Notes |
| --- | --- | --- | --- |
| Storage Network | ✔️ | ✔️ | - |
| IPv4 | ✔️ | ✔️ | - |
| IPv6 | ✔️ | ✔️ | - |

### Orphan Resource

| Feature | V1 | V2 | Support Notes |
| --- | --- | --- | --- |
| Orphaned Replica Data Management | ✔️ | ✔️ | - |
| Orphaned Instance Management | ✔️ | Not supported | - |

### Volume Live Migration

| Feature | V1 | V2 | Support Notes |
| --- | --- | --- | --- |
| Volume Live Migration | ✔️ | ✔️ | - |

### Engine Live Upgrade

| Feature | V1 | V2 | Support Notes |
| --- | --- | --- | --- |
| Engine Live Upgrade | ✔️ | Not supported | V2 volumes do not support live upgrades between Longhorn v1.12 patch releases and must be detached before upgrading. Support is planned when upgrading from a Longhorn v1.12 release to a Longhorn v1.13 release. |

### Storage Sharding

| Feature | V1 | V2 | Support Notes |
| --- | --- | --- | --- |
| Storage Sharding | Not planned | Planned | Planned as an experimental feature for Longhorn v1.12.1. |
