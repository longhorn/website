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

When Longhorn detects a failed or deleted replica, it automatically initiates a rebuilding process. This document outlines the replica rebuilding workflow for v1 data engine, including **full**, **delta**, and **fast** rebuilding methods. It also explains the limitations associated with each method.

**Rebuilding will not start in the following scenarios**:

- The volume is migrating to another node.
- The volume is an old restore/DR volume.
- The volume is expanding in size.

## Replica Rebuilding Workflow

Replica rebuilding may be triggered in the following scenarios for v1 data engine:

- A node is rebooted, drained or evicted.
- A replica becomes unhealthy or is deleted.

 {{< figure alt="Replica Rebuilding Flow Diagram" src="/img/diagrams/architecture/replica-rebuilding-flow.png" >}}

1. Mark the target replica with `WO` (Write-Only) mode.
2. Create a new snapshot to serve as the volume head reference point for data integrity checks.
3. Generate the synchronization file list for the volume head and snapshot files.

- For **V1 Data Engine**:  
  4. Launch a receiver server on the target replica for each snapshot, then instruct the source replica to begin data synchronization.  
  5. For each snapshot synchronization:
    - Check whether the snapshot file exists in the target replica's data directory:
        - If **NO**, transfer the entire snapshot data from the source replica to the target replica. See [Full Replica Rebuilding](#full-replica-rebuilding)
        - If **YES**, check whether the snapshot checksum files exist, the modification time and checksums are identical between the target and source replicas:
            - If **YES**, Longhorn skips transferring that snapshot’s data. This optimization reduces CPU usage, disk I/O, network I/O, and overall rebuild time. See [Fast Replica Rebuilding](#fast-replica-rebuilding)
            - If **NO**, Longhorn calculates and compares block-by-block checksums for the snapshot file using the SHA-512 algorithm. If mismatches are found, only the differing data blocks are synchronized. See [Delta Replica Rebuilding](#delta-replica-rebuilding)
- For **V2 Data Engine**:  
  4. Expose the source and target replicas and prepare shallow copy with the SPDK engine.  
  5. For each snapshot:
    - Check if the snapshot timestamp, snapshot actual size, and snapshot checksum match between the source and target snapshots:
      - If **YES**, Longhorn skips transferring that snapshot’s data.
      - If **NO**, check if both the source and target snapshot hold ranged checksums
        - If **YES**, fetching and comparing the entire ranges' checksums of the source and target snapshot. If mismatches are found, only copy mismatched parts. See [Fast Replica Rebuilding](#fast-replica-rebuilding)
        - If **NO**, delete the existing target snapshot. Then start copying the entire snapshot from the source replica to the target replica. See [Full Replica Rebuilding](#full-replica-rebuilding)

### Full Replica Rebuilding

If the replica is unrecoverable or has no existing data, Longhorn synchronizes all data from a healthy replica. It reconstructs the replica by transferring the full snapshot chain.

Full replica rebuilding consumes significant network bandwidth and results in heavy disk write operations on the target node. However, it is required when the target replica has no usable data.

### Delta Replica Rebuilding

Delta replica rebuilding is only for v1 data engine. It starts with a reusable failed replica, and it checks the data integrity for all snapshots' data block by block.

- This is available for failed replica reuse only, and there is an existing snapshot file (with the same name) in the failed replica data directory
- When a snapshot has no checksum, Longhorn performs delta replica rebuilding for this snapshot instead.

- **Pros**:
  - Reduce network bandwidth consumption.
- **Cons**:
  - Increased CPU overhead because Longhorn will compute the checksum of the snapshot data block by block for data integrity check.
  - Rebuilding time is influenced by CPU performance.

### Fast Replica Rebuilding

Fast rebuilding is enabled when:

- The fast replica building setting is enabled:
  - `fast-replica-rebuild-enabled: true`
- Snapshot checksum files are created (the snapshot checksums are pre-computed) via one of the following methods:
  - `snapshot-data-integrity` is set to `enabled`:  scheduled job calculates checksums for all snapshots at a configured interval (default: 7 days), or
  - `snapshot-data-integrity-immediate-check-after-snapshot-creation` is set to `true`: the snapshot checksum is calculated immediately after snapshot creation.

  > **Note**: These checksum calculations consume storage and computing resources. The calculation time is unpredictable and may negatively impact the storage performance.  
  > For more details, see [Snapshot Data Integrity](../data-integrity/snapshot-data-integrity-check)

- **Pros**:
  - Minimize network bandwidth consumption.
  - Minimize disk IO.
- **Cons**:
  - Calculating the snapshot checksum can be time-consuming.
  - The timing of checksum calculation is unpredictable. It can be triggered even if the node is experiencing heavy IO load.

For more details, see [Fast Replica Rebuilding](./fast-replica-rebuilding).

## Factors That Affect Rebuilding Performance

- **Large volume head**
  - **Why it matters**:  
    The volume head is a special file that never has a precomputed checksum. If a replica fails, Longhorn must always synchronize the entire volume head file. The larger the volume head, the longer the rebuild process will take.
  - **How to prevent**:  
    Take snapshots regularly to reduce the amount of data in the volume head. Schedule snapshot creation before planned maintenance to minimize rebuild time.
- **No snapshots exist**
  - **Why it matters**:  
    Without snapshots, Longhorn cannot skip data transfer or reuse existing data. If a snapshot of the volume head was just created, but its checksum has not yet been calculated, Longhorn must perform delta rebuilding for that snapshot. This increases CPU load due to block-by-block checksum comparisons.
  - **How to prevent**:  
    1. Enable `snapshot-data-integrity-immediate-check-after-snapshot-creation` or `snapshot-data-integrity`, so checksums are precomputed.
       Trade-off: Increases CPU, disk I/O, and storage usage during checksum computation.
    2. Use a recurring job to take snapshots regularly.
- **Snapshot Purged**
  - **Why it matters**:  
    When snapshot purging starts, system-generated snapshots are coalesced into the next snapshot. As a result, the checksum of the next snapshot becomes invalid.
  - **How to prevent**:
    1. Enable `snapshot-data-integrity-immediate-check-after-snapshot-creation` to ensure the checksums are generated after purging.
    2. Proactively create a snapshot and allow time for its checksum to be computed before upgrades or rebuilds.
- **Concurrent rebuilds**
  - **Why it matters**:  
    Multiple rebuilds running simultaneously on a node can heavily consume CPU, disk I/O, and network I/O resources, impacting overall performance.
  - **How to prevent**:  
    Tune the number of concurrent rebuilds using the `concurrent-replica-rebuild-per-node-limit` setting.
- **Multiple replica failures**
  - **Why it matters**:  
    Increases rebuild complexity and duration. If the `auto-cleanup-system-generated-snapshot` setting is `true` and no user-created snapshots exist, then when two replicas fail before either has been rebuilt, Longhorn must perform at least one **full data transfer** to restore volume health.  
    For more details, see [Avoid "full data transfer" when rebuilding two failed replicas](https://github.com/longhorn/longhorn/issues/9335)
  - **How to prevent**:
    1. Manually disable `auto-cleanup-system-generated-snapshot before doing maintenance` before performing maintenance.
    2. Take user-created snapshots of all volumes before starting maintenance.
    3. Use a recurring job to take snapshots regularly.

## Use Cases

### Node Reboot During Upgrade

When a worker node with replicas is rebooted as part of a planned upgrade:

1. The replica on that node becomes temporarily unavailable and fails, but read/write operations continue.
2. If the node recovers within the `replica-replenishment-wait-interval`, Longhorn initiates a rebuild using the reusable failed replica.

During the rebuilding process:

  1. Longhorn selects the latest reusable failed replica if multiple reusable failed replicas are available.
  2. Based on the rebuild scenario:
      - **If fast replica rebuilding is enabled and all snapshot checksums exist:**
        [Fast Replica Rebuilding](#fast-replica-rebuilding) is triggered.
        - Only changed blocks in the volume head are synced, avoiding both full and delta rebuilding.
      - **If fast replica rebuilding is enabled but some snapshot checksums are missing:**
        [Delta Replica Rebuilding](#delta-replica-rebuilding) is used.
        - Changed blocks from snapshots without checksums are synced, avoiding full rebuilding.
      - **If fast replica rebuilding is disabled:**
        - Changed blocks of **all snapshots** are synced (delta rebuilding), avoiding full rebuilding.

### Short-Term Node Drain

If a worker node is drained for short-term maintenance and then quickly restored:

1. The replica on the drained node is marked as failed immediately.
2. If the node is uncordoned before `replica-replenishment-wait-interval` expires, Longhorn attempts to reuse the failed replica..
3. Rebuild behavior follows the same logic as described in the previous use case.

## Relevant Settings

| Setting| Default | Description |
| :--- | :---: | :--- |
| `fast-replica-rebuild-enabled` | `true` | Enables fast replica rebuilding. Relies on precomputed snapshot checksums. |
| [snapshot-data-integrity](../data-integrity/snapshot-data-integrity-check) | `fast-check` | Hashes snapshot disk files only if they are unhashed or their modification time has changed. |
| `snapshot-data-integrity-cronjob` | `0 0 */7 * *` | Cron schedule to compute checksums for all snapshots (default: every 7 days). |
| `snapshot-data-integrity-immediate-check-after-snapshot-creation` | `false` | If enabled, checksums are computed immediately after snapshot creation. |
| `replica-replenishment-wait-interval` | `600` |    Time in seconds to wait before creating a new replica, allowing reuse of failed replicas. |
| `concurrent-replica-rebuild-per-node-limit` | `5` | Limits the number of concurrent replica rebuilds per node. |
| `offline-replica-rebuilding` | `false` | Determines if degraded replicas are rebuilt while the volume is detached. |
||||

### Settings Trade-Off Analysis

- **[fast-replica-rebuild-enabled](../../references/settings#fast-replica-rebuild-enabled)**
  - `enabled`  
    Skips snapshot data transfer if checksums are up to date — fast rebuild, but data isn't re-validated.
  - `disabled`  
    Performs delta rebuilding using block comparisons — slower, but ensures snapshot data integrity.
- **[snapshot-data-integrity](../data-integrity/snapshot-data-integrity-check)**
  - `enabled`  
  By default, computes snapshot checksums every 7 days. This consumes resources and increases processing time.
- **[snapshot-data-integrity-cronjob](../../references/settings#snapshot-data-integrity-check-cronjob)**
  - Default: `0 0 */7 * *`  
  If the `snapshot-data-integrity` setting is `enabled`, it defines when snapshot checksums are recalculated. Snapshots created within this interval may lack precomputed checksums.
- **[snapshot-data-integrity-immediate-check-after-snapshot-creation](../../references/settings#immediate-snapshot-data-integrity-check-after-creating-a-snapshot)**
  - `true`  
  Immediately calculates checksums after snapshot creation, increasing CPU and disk I/O usage. Completes at an unpredictable time.
  - `false`  
  Snapshots may not have checksums until the next cron job runs with `snapshot-data-integrity` `enabled`. Delta rebuilding will be used if checksums are missing.
- **[replica-replenishment-wait-interval](../../references/settings#replica-replenishment-wait-interval)**
  - Default: `600` seconds
    - **Short interval**: May skip reusing failed replicas and trigger full rebuilds.
    - **Long interval**: Waits longer to reuse failed replicas but may delay recovery.
- **[concurrent-replica-rebuild-per-node-limit](../../references/settings#concurrent-replica-rebuild-per-node-limit)**
  - Default: `5`
    - **High limit**: May overload node resources and slow down rebuilds and workloads.
    - **Low limit**: Reduces resource strain but may increase total rebuild duration due to queuing.
