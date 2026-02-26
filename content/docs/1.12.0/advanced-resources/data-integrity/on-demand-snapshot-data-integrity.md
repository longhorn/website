---
title: On Demand Snapshot Data Integrity
weight: 2
---

The Longhorn CLI supports on-demand snapshot data integrity.

## Introduction

In addition to periodic snapshot data integrity checks, Longhorn provides an **on-demand snapshot checksum** mechanism. This feature allows users to manually trigger checksum recalculation for all user-created snapshots of a volume without waiting for the scheduled cron job.

On-demand checksum is useful when users need immediate verification of snapshot integrity, such as before performing a restore, after infrastructure instability, or during troubleshooting situations where silent data corruption is suspected.

## Related Custom Resource Information

### Volume

Longhorn uses the following fields to track the lifecycle of an on-demand checksum request:

- **Spec.OnDemandChecksumRequestedAt**  
  Timestamp (RFC3339) indicating when the on-demand checksum request was issued.

- **Status.LastOnDemandChecksumCompletedAt**  
  Timestamp (RFC3339) indicating when the request was considered completed by Longhorn.

### Snapshot

Each snapshot records the timestamp of its latest checksum calculation:

- **Status.ChecksumCalculatedAt**  
  Timestamp (RFC3339) representing the last time this snapshot’s checksum was successfully calculated by the SnapshotMonitor.

## How It Works

When a user triggers an on-demand checksum request, Longhorn performs the following actions:

### 1. User issues an on-demand request

The request is initiated through the Longhorn CLI:

```bash
longhornctl checksum volume --name <volume-name>
```

Longhorn updates `Volume.Spec.OnDemandChecksumRequestedAt`

### 2. Detects a new request

Compares the newly requested timestamp with the previous completion timestamp (`Status.LastOnDemandChecksumCompletedAt`). If the request is new and valid, it enqueues checksum tasks for all related snapshots. Only **user-created** snapshots that existed at the time of the request are included.

### 3. Recalculates snapshot checksums

Performs the checksum calculation using the standard snapshot data integrity logic. Each snapshot updates `Snapshot.Status.ChecksumCalculatedAt`

### 4. VolumeController evaluates completion

Longhorn considers the on-demand request completed when:

- All relevant **user-created** snapshots have a checksum
- Fresh checksums (created after the request) are preferred
- If the rehash does not succeed within a bounded timeout window, Longhorn accepts an existing checksum to prevent the request from blocking indefinitely

### 5. Completion is recorded

When all snapshots satisfy the criteria above, Longhorn updates `Volume.Status.LastOnDemandChecksumCompletedAt` This indicates that the on-demand checksum request has been processed.

## CLI Usage

Longhorn provides a CLI interface to trigger on-demand snapshot checksum operations through the [longhornctl command-line tool](https://github.com/longhorn/cli).

> **Note:** This is an asynchronous operation. When the request is marked as complete in the output log, it only means the request has been submitted successfully. There is no true request object; the log entry indicates that the checksum computation process has started, but actual completion depends on the volume size and may take additional time. You can monitor the progress and check snapshot checksums using `kubectl`.

### Sample

- Command

```bash
longhornctl checksum volume --name=test
```
- Output

```bash
INFO[2026-02-24T14:22:50+08:00] Triggering on-demand snapshot checksum calculation  volume=test
INFO[2026-02-24T14:22:50+08:00] Snapshot snap-005b44e3601c4193 has no checksum 
INFO[2026-02-24T14:22:50+08:00] Snapshot snap-87248970341e4bb6 with checksum 14371324507521616000 
INFO[2026-02-24T14:22:50+08:00] Requested on-demand checksum calculation for volume test 
INFO[2026-02-24T14:22:50+08:00] Calculating snapshot checksums may take some time. You can check the snapshot checksum by kubectl. 
INFO[2026-02-24T14:22:50+08:00] Checksum request submitted                    volume=test
INFO[2026-02-24T14:22:50+08:00] Cleaning volume on-demand checksum requester  volume=test
INFO[2026-02-24T14:22:50+08:00] Completed volume on-demand checksum requester  volume=test
```

## Limitations

- On-demand snapshot checksum only applies to volumes with at least `two` replicas, consistent with the behavior of periodic snapshot data integrity checks.

- The global or per-volume setting **snapshot-data-integrity** must be set to either **enabled** or **fast-check**. The feature is not available when data integrity is **disabled**.
