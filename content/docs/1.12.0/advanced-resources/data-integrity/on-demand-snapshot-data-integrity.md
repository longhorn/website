---
title: On Demand Snapshot Data Integrity
weight: 2
---

Longhorn supports **on-demand snapshot checksum** calculation via the CLI.

## Introduction

In addition to periodic snapshot data integrity checks, Longhorn provides an **on-demand snapshot checksum** mechanism. This feature allows users to manually trigger checksum calculation for all user-created snapshots of a volume without waiting for the scheduled cron job.

On-demand checksum is useful when users need immediate verification of snapshot integrity, such as before performing a restore, after infrastructure instability, or during troubleshooting situations where silent data corruption is suspected.

## Related Custom Resource Information

### Volume

Longhorn uses the following fields to track the lifecycle of an on-demand checksum request:

- **Spec.SnapshotHashingRequestedAt**  

	`SnapshotHashingRequestedAt` is the RFC3339 timestamp (e.g., "2026-03-16T10:30:00Z") when an on-demand snapshot checksum calculation is requested. When this value is set and is later than `LastOnDemandSnapshotHashingCompleteAt`, the system will calculate checksums for all user snapshots.

	If `SnapshotHashingRequestedAt` differs from `LastOnDemandSnapshotHashingCompleteAt`, it indicates that a hashing request is still in progress, and a new request will be rejected.

- **Status.LastOnDemandSnapshotHashingCompleteAt**  

	LastOnDemandSnapshotHashingCompleteAt is the RFC3339 timestamp (e.g., "2026-03-16T10:30:00Z") when the most recent on-demand snapshot checksum calculation completed. When this value matches `SnapshotHashingRequestedAt`, the requested on-demand checksum calculation is considered complete.

### Snapshot

Each snapshot records the timestamp of its latest checksum calculation:

- **Status.ChecksumCalculatedAt**  

	ChecksumCalculatedAt is the RFC3339 timestamp indicating when the checksum for this snapshot was last calculated or updated.

## How It Works

When a user triggers an on-demand checksum request, Longhorn performs the following actions:

### 1. User issues an on-demand request

The request is initiated through the Longhorn CLI:

```bash
./longhornctl checksum volume --name=<volume-name> --namespace=longhorn-system
```

```bash
./longhornctl checksum volume --node-id=v<node-name> --namespace=longhorn-system
```

```bash
./longhornctl checksum volume --all=true --namespace=longhorn-system
```


### 2. Detects a new request

The **Volume Controller** compares `Spec.SnapshotHashingRequestedAt` with `Status.LastOnDemandSnapshotHashingCompleteAt`. If the requested timestamp is newer, Longhorn triggers the SnapshotMonitor to calculate checksums for all existing **user-created** snapshots that are missing checksum data.

### 3. Calculates snapshot checksums

Performs the checksum calculation using the standard snapshot data integrity logic.

### 4. VolumeController evaluates completion

Longhorn considers the on-demand request completed when all relevant **user-created** snapshots have a checksum

### 5. Completion is recorded

When all snapshots satisfy the criteria above, Longhorn updates `Volume.Status.LastOnDemandChecksumCompletedAt` This indicates that the on-demand checksum request has been processed.

## CLI Usage

Longhorn provides a CLI interface to trigger on-demand snapshot checksum operations through the [longhornctl command-line tool](https://github.com/longhorn/cli).

**Usage**

  longhornctl checksum volume [flags] [options]

**Options**

`--all`: Apply to all volumes (default: false)

`--name`: Name of the Longhorn volume

`--node-id`: Compute snapshots for all volumes on the specified node


> **Note**: This is an asynchronous operation. When the request is marked as complete in the output log, it indicates the trigger was successful. Since there is no dedicated Request CRD, the CLI output confirms the controller has acknowledged the Spec update. Actual computation occurs in the background and duration scales with volume size. You can monitor the progress and check snapshot checksums using `kubectl`

### Example

**Command**:

```bash
./longhornctl-linux-amd64 checksum volume --all=true
```

**Output**
```bash
INFO[2026-03-18T17:04:27+08:00] Triggering on-demand snapshot checksum calculation 
INFO[2026-03-18T17:04:27+08:00] Requested on-demand checksum calculation for volume tmp1  volume=tmp1
INFO[2026-03-18T17:04:27+08:00] Requested on-demand checksum calculation for volume tmp2  volume=tmp2
INFO[2026-03-18T17:04:27+08:00] Snapshot checksum calculation may take some time. You can check the snapshot checksum via kubectl. 
INFO[2026-03-18T17:04:27+08:00] Checksum request submitted                   
INFO[2026-03-18T17:04:27+08:00] Cleaning volume on-demand checksum requester 
INFO[2026-03-18T17:04:27+08:00] Completed volume on-demand checksum requester 
```

## Limitations

- On-demand snapshot checksum only applies to volumes with at least `two` replicas, consistent with the behavior of periodic snapshot data integrity checks.
- The global or per-volume setting **snapshot-data-integrity** must be set to either **enabled** or **fast-check**. The feature is not available when data integrity is **disabled**.
