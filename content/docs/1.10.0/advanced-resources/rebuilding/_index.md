---
title: Replica Rebuilding
weight: 6
---
- [Replica Rebuilding Workflow](#replica-rebuilding-workflow)
  - [Full Replica Rebuilding](#full-replica-rebuilding)
  - [Delta Replica Rebuilding](#delta-replica-rebuilding)
  - [Fast Replica Rebuilding](#fast-replica-rebuilding)
- [Factors That Affect Rebuilding Performance](#factors-that-affect-rebuilding-performance)
- [Use Cases](#use-cases)
  - [Node Reboot During Upgrade](#node-reboot-during-upgrade)
  - [Short-Term Node Drain](#short-term-node-drain)
- [Relevant Settings](#relevant-settings)
  - [Settings Trade-Off Analysis](#settings-trade-off-analysis)

When Longhorn detects a failed or deleted replica, it automatically triggers a rebuilding process to rebuild the failed replica. This document outlines the replica rebuilding flow, covering full rebuilding, delta rebuilding, and fast rebuilding. It also explains the limitations of each rebuilding method.

Rebuilding will not start when:

- The volume is being migrating to another node.
- The volume is old restore/DR volumes.
- The volume is expanding size.

## Replica Rebuilding Workflow

Replica rebuilding may be triggered under the following scenarios:

- Node reboot or eviction.
- A replica becomes unhealthy or deleted.

 {{< figure alt="Replica Rebuilding Flow Diagram" src="/img/diagrams/architecture/replica-rebuilding-flow.png" >}}

1. Mark the target replica with `WO` (Write-Only) mode.
2. System will create a new snapshot as a reference point of the volume-head for data integrity check.
3. Get a synchronizing file list of the volume head and snapshot files.
4. Launch a receiver server in the target replica for each snapshot, then ask the source replica to synchronize data.
5. For each snapshot synchronization,
    - Check whether the snapshot file exists in the target replica data directory
        - If **NO**, directly transfer all data from the source replica to the destination replica. [Full Replica Rebuilding](#full-replica-rebuilding)
        - If **YES**, check whether the value of snapshot checksum files between the target replica and the source replica exists and is identical:
            - If **YES**, Longhorn skips the corresponding snapshot data transfer, which reduces the CPU usage, disk IO, network IO, and rebuilding time. [Fast Replica Rebuilding](#fast-replica-rebuilding)
            - If **NO**, Longhorn calculates and compares block-by-block checksums for the snapshot file between the target replica and the source replica (The checksum is computed using SHA-512 method). If there is a mismatch, the corresponding data block will be synced. [Delta Replica Rebuilding](#delta-replica-rebuilding)

### Full Replica Rebuilding

If the replica is unrecoverable or replenished, Longhorn will synchronize the whole data from the healthy replica. Reconstruct the replica by sending the full snapshot chain.

Full replica rebuilding will waste network bandwidth and generate numerous disk WRITE operations on the target replica node, but it is the only way to rebuild a replica if there is no data on the target node.

### Delta Replica Rebuilding

- This is available for failed replica reusage only, and there is an existing snapshot file (with the same name) in the failed replica data directory
- There is no checksum/checksum file for the snapshot file. It's like a fallback of fast rebuilding

- **Pros**:
  - Reduce network bandwidth consumption.
- **Cons**:
  - Increased CPU overhead.
  - Rebuilding time is influenced by CPU performance.

### Fast Replica Rebuilding

Fast rebuilding is enabled when:

- The fast replica building setting is enabled:
  - `fast-replica-rebuild-enabled: true`
- Snapshot checksum files are created:
  - `snapshot-data-integrity`: `enabled`, and a scheduled job will calculate checksums of all snapshots in a configured interval or
  - `snapshot-data-integrity-immediate-check-after-snapshot-creation: true`, calculate the snapshot checksum after the snapshot is created.

  However, the checksum calculation negatively impacts the storage performance.

6. Skip checking unchanged snapshots if the checksums are the same in the checksum files of snapshots.
7. If the value of snapshot checksum files between the target replica and the source replica does not exist or is not identical, it will go to the delta rebuilding flow.

- **Pros**:
  - Minimize network bandwidth consumption.
  - Minimize disk IO.
- **Cons**:
  - Calculating the snapshot checksum can be time-consuming.
  - The timing of checksum calculation is unpredictable. It can be triggered even if the node is experiencing heavy IO load.

The snapshot checksum is computed:

- Immediately after the snapshot is created with the `snapshot-data-integrity-immediate-check-after-snapshot-creation` setting enabled.
- Regularly (by default: 7 days) if the `snapshot-data-integrity` setting is `enabled`.

For more details, [Fast Replica Rebuilding](./fast-replica-rebuilding).

## Factors That Affect Rebuilding Performance

- Large volume head or No snapshot exists
  - **WHY**:  
    - If the replica fails and rebuilding starts immediately, there is no opportunity to generate a checksum file for this large volume head. Then Longhorn has to do a full rebuild for all data in this large volume head
    - If the replica quickly fails and gets rebuilt after the snapshot of this large volume head is created, there is not enough time to calculate the checksum. As a result, Longhorn has to do a delta rebuilding for all data in this newly created snapshot, which will cause checksum calculation overhead and numerous checksum comparisons between the target replica and the source replica
  - **HOW**:
    1. Enable `snapshot-data-integrity-immediate-check-after-snapshot-creation` or `snapshot-data-integrity` setting, so checksums are precomputed.
    2. Take regularly snapshots by a recurring job.
- Snapshot Purged
  - **WHY**:  
  When the snapshot purged of volume starts, the system-generated snapshot will be coalesced to the next snapshot, and the checksum of the next snapshot will be invalid.
  - **HOW**:
    1. Enable `snapshot-data-integrity-immediate-check-after-snapshot-creation` to ensure the checksum precomputed after the snapshot purged.
    2. Create a snapshot proactively and wait for the checksum to be computed before upgrades or rebuild events
- Concurrent rebuilds
  - **WHY**:  
  The number of concurrent rebuild on a node will occupy the CPU usage, disk IO, and network IO resources.
  - **HOW**:  
  Tune the number of concurrent rebuilding by the `concurrent-replica-rebuild-per-node-limit` setting on a node.
- Multiple replica failures
  - **WHY**:  
  Increases rebuild complexity and duration. With the `auto-cleanup-system-generated-snapshot` setting `true` and no user-created snapshots, if two replicas fail before either has the chance to be rebuilt, at least one `full data transfer` is required to bring the volume back to a healthy state.  
  For more details, [Avoid "full data transfer" when rebuilding two failed replicas
](https://github.com/longhorn/longhorn/issues/9335)
  - **HOW**:
    1. Manually disable `auto-cleanup-system-generated-snapshot before doing maintenance`.
    2. Take a user-created snapshot of all volumes before maintenance.
    3. Use a recurring job to take a user-created snapshot regularly.

## Use Cases

### Node Reboot During Upgrade

When worker node with replicas is rebooted as part of a planned upgrade:

1. The replica on that node becomes temporarily unavailable and failed without pausing read/write operations.
2. Node is recovery before waiting `replica-replenishment-wait-interval` seconds, Longhorn initiates a rebuild.

During replica rebuilding:

  1. Longhorn will try to select the latest reusable failed replica if there are multiple reusable failed replicas.
  2. How to rebuild the selected reusable failed replica.
      - If fast replica rebuilding is enabled and all checksums of snapshots exist, [Fast Replica Rebuilding](#fast-replica-rebuilding)
        - only changed blocks of the volume-head are synced, avoiding a full rebuilding and a delta rebuilding.
      - If fast replica rebuilding is enabled and some checksums of snapshots do not exist, [Delta Replica Rebuilding](#delta-replica-rebuilding)
        - changed blocks of the snapshot that do not have the checksum are synced, avoiding a full rebuilding.
      - If fast replica rebuilding is not enabled,
        - changed blocks of all snapshots are synced, avoiding a full rebuilding.

### Short-Term Node Drain

If the worker node is drained for maintenance and comes back shortly after:

1. The replica on this worker node becomes failed immediately when this worker node is drained.
2. Node is uncordoned before waiting `replica-replenishment-wait-interval` seconds, Longhorn initiates a rebuild with the reusable failed replica.
3. During replica rebuilding, the process is the same as previous use case.

## Relevant Settings

| Setting| Default | Description |
| :--- | :---: | :--- |
| `fast-replica-rebuild-enabled` | true | The fast replica rebuilding feature for v1 data engine. It relies on the snapshot checksums. |
| `v2-data-engine-fast-replica-rebuilding` | false | The fast replica rebuilding feature for v2 data engine. It relies on the snapshot checksums. |
| [snapshot-data-integrity](../data-integrity/snapshot-data-integrity-check) | fast-check | Longhorn system only hashes snapshot disk files if they are not hashed or the modification time are changed. |
| `v2-data-engine-snapshot-data-integrity` | fast-check | Enable or disable snapshot hashing and data integrity checking for v2 data engine |
| `snapshot-data-integrity-cronjob` | 0 0 */7 * * | A schedule defined using the unix-cron string format specifies when Longhorn checks the data integrity of snapshot disk files. |
| `snapshot-data-integrity-immediate-check-after-snapshot-creation` | false | The immediate snapshot hashing and checking can be disabled to minimize the impact after creating a snapshot. |
| `replica-replenishment-wait-interval` | 600 |  Interval in seconds determines how long Longhorn will wait at most in order to reuse the existing data of the failed replicas rather than directly creating a new replica for this volume. |
| `concurrent-replica-rebuild-per-node-limit` | 5 | Controls how many replicas on a node can be rebuilt simultaneously. |
| `offline-replica-rebuilding` | false | Controls whether Longhorn automatically rebuilds degraded replicas while the volume is detached. |
||||

### Settings Trade-Off Analysis

- `fast-replica-rebuild-enabled`
  - `enabled`  
    Skip snapshot data integrity checks if the checksum is precomputed and up to date. Fast, but skipped snapshot data is not compared.
  - `disabled`  
    Always do delta replica rebuilding when a reusable failed replica is available. Slow, but the snapshot data matches exactly.
- [snapshot-data-integrity](../data-integrity/snapshot-data-integrity-check)
  - `enabled`  
  By default, it will compute the checksum of all snapshots every 7 days. Calculating checksums for all snapshots consumes worker node resources and adds processing time.
- `snapshot-data-integrity-cronjob`
  - `0 0 */7 * *`  
  If the `snapshot-data-integrity` setting is `enabled`, a cron job will be scheduled to start calculate all snapshot checksums. The snapshot checksum will not be computed during the configured interval. For example, by default, snapshots created within the last 7 days will not have their checksums precomputed.
- `snapshot-data-integrity-immediate-check-after-snapshot-creation`
  - `true`  
  Calculate the snapshot checksum after the snapshot is created immediately. It will also consume worker node resources and adds unexpectedly processing time. If numerous snapshots are created every day, it will have a negative impact.
  - `false`  
  By default, snapshots created within the last 7 days will not have their checksums precomputed if the `snapshot-data-integrity` is `enabled`. Therefore, if numerous snapshots are created every day, it will compare numerous data block of snapshot with calculating checksums during the failed replica rebuilding.
- `replica-replenishment-wait-interval`
  - `600` seconds  
  With a short replenishment interval, it will start to create a new replica and do a full replica rebuilding before the reusable failed replica is back. With a long replenishment interval, it will wait a long time to create a new replica and do a full replica rebuilding if no reusable failed replicas.
- `concurrent-replica-rebuild-per-node-limit`
  - `5`  
  With numerous concurrent replicas rebuild on a worker node, running applications may be negatively impacted, and running replica rebuild processes may slow down. With rare concurrent replicas rebuild on a worker node, the overall rebuild process may be delayed due to queuing.
