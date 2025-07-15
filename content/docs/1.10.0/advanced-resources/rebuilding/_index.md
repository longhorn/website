---
title: Replica Rebuilding
weight: 6
---
- [Rebuilding Types](#rebuilding-types)
  - [Full Replica Rebuilding](#full-replica-rebuilding)
  - [Delta Replica Rebuilding](#delta-replica-rebuilding)
    - [Fast Replica Rebuilding](#fast-replica-rebuilding)
- [Operations That Affect Rebuilding Performance](#operations-that-affect-rebuilding-performance)
- [Relevant Settings](#relevant-settings)

When Longhorn detects a failed replica or a replica deleted, it automatically triggers a rebuilding process. This document introduces the new replica rebuilding flow, designed to improve performance and support delta rebuilding and fast rebuilding optimizations.

Replica rebuilding may be triggered under the following scenarios:

- Node reboot or eviction.
- Replica becomes unhealthy or deleted.

## Rebuilding Types

| Type | Description |
| --- | --- |
| Full Rebuilding | The replica contains no valid data or is deleted and must sync the entire volume. |
| Delta Rebuilding | The replica is partially reusable; only changed blocks are synchronized. |
|||

 {{< figure alt="Replica Rebuilding Flow Diagram" src="/img/diagrams/architecture/replica-rebuilding-flow.png" >}}

### Full Replica Rebuilding

If the replica is unrecoverable or replenished:

- Enter full rebuild mode.
- Reconstruct the replica by sending the full snapshot chain.

### Delta Replica Rebuilding

1. Mark the target replica with `WO` (Write-Only) mode.

2. System will create a new snapshot as a reference point of the volume-head for integrity check.

3. Get Synchronizing File List of the volume head and snapshot files for checksum comparison.

4. Compare Checksums. If [Fast Replica Rebuilding](#fast-replica-rebuilding) is not enabled, use interval-based checksum comparison.

5. If local and remote checksums do not match, launch receiver of the target replica to synchronize missing or mismatched data.

#### Fast Replica Rebuilding

Fast rebuilding is enabled when:

- `fast-replica-rebuild-enabled: true`
- Snapshot checksums are created.

  - `snapshot-data-integrity`: `enabled` or
  - `snapshot-data-integrity-immediate-check-after-snapshot-creation: true`

Benefits:

- Skip checking unchanged snapshots.
- Reduce network IO and rebuilding time.

For more details, [Fast Replica Rebuilding](./fast-replica-rebuilding).

## Operations That Affect Rebuilding Performance

| Action | Impact |
| --- | --- |
| Large volume head | Slower checksum comparison |
| Snapshot purged | No checksums available; sending volume-head image is required |
| No snapshot exists | Delta replica rebuilding may not be possible |
| Concurrent rebuilds | Resource contention slows down rebuild |
| Multiple replica failures | Increases rebuild complexity and duration |

## Relevant Settings

| Setting| Default | Description |
| :--- | :---: | :--- |
| `fast-replica-rebuild-enabled` | true | It relies on the checksums of snapshot disk files. |
| `snapshot-data-integrity` | fast-check | Longhorn system only hashes snapshot disk files if they are not hashed or the modification time are changed. |
| `snapshot-data-integrity-immediate-check-after-snapshot-creatio` | false | The immediate snapshot hashing and checking can be disabled to minimize the impact after creating a snapshot. |
| `offline-replica-rebuilding` | false | Controls whether Longhorn automatically rebuilds degraded replicas while the volume is detached. |
||||
