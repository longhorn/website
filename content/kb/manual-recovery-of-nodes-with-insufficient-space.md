---
title: "Manual Recovery of Nodes with Insufficient Space"
authors:
- "Sushant Gaurav"
draft: false
date: 2026-02-09
versions:
- all
categories:
- "instruction"
- "nodes"
---

> **Warning**: High storage overprovisioning ratios are a leading cause of disk exhaustion. Ensure your `Storage Overprovisioning Percentage` aligns with physical capacity.

## Symptoms

- The node is marked as `NotReady` or shows a `DiskPressure` taint.
- Longhorn replicas on the node are stuck or failing to sync.
- New pods cannot be scheduled to the node.

## Cause

This usually occurs due to high overprovisioning, snapshot accumulation, or uneven replica scheduling. The node's disk is full, preventing Longhorn from writing data or creating new replicas.

## Recovery Measures

If a node is facing disk exhaustion, you can use the following methods to reclaim space.

### Method 1 - Manual Replica Evacuation

1. **Disable scheduling for the stressed node or disk**:
    - **Node Level**: In the Longhorn UI, go to the **Nodes** tab, select the stressed node, and set **Scheduling** to `Disable`.
    - **Disk Level**: Alternatively, you can disable scheduling for a specific disk by selecting **Edit Node and Disks** and setting **Scheduling** to `Disable` for that specific path.
    - This ensures that when a replica is removed, Longhorn cannot rebuild the replacement on the same exhausted storage resource. For more details on how Longhorn selects placement sites, see [Scheduling](../../docs/1.12.0/nodes-and-volumes/nodes/scheduling).
2. **Identify a volume with a replica on the stressed node**:
    > **CRITICAL**: Only proceed if the volume status is **Healthy** and you have at least 2 other healthy replicas on different nodes.
3. **Delete the replica**: Navigate to the **Volumes Detail** page for the identified volume. In the **Replicas** section, find the replica located on the stressed node and select **Delete**.
4. **Verification**: Longhorn will automatically detect the missing replica and rebuild it on a different node with available space.
5. **Re-enable scheduling**: Once the node or disk has sufficient space, remember to set **Scheduling** back to `Enable`.

### Method 2 - Reclaim Space from Snapshots

Longhorn volumes can consume more space than their actual data size due to historical snapshots.

- **Delete Manual Snapshots**: Identify volumes with large or numerous snapshots and delete them via the **Volumes Detail** page to merge data into the parent snapshot.
    > **WARNING**: Deleting and purging snapshots requires extra temporary disk space to perform the data merge. If a disk is already at 100% capacity, the purge operation may fail or get stuck. Ensure there is a small buffer of available space before initiating a large-scale snapshot purge.
- **Setup Recurring Jobs**: To prevent future buildup, implement a `snapshot-delete` recurring job. This job periodically removes and purges snapshots that exceed a specified retention count. See [Recurring Snapshots and Backups](../../docs/1.12.0/snapshots-and-backups/scheduling-backups-and-snapshots) for configuration details.

> **Note**: Users must not manually touch or delete the files inside the replica directories on the node's filesystem, as this will lead to data corruption.

### Method 3 - Filesystem Trim (Unmap)

Deleting files within the workload's filesystem does not automatically free up blocks on the underlying Longhorn block device.

- **Prerequisites**: Ensure you are on Longhorn v1.4.0+ and using a trimmable filesystem like EXT4 or XFS.
- **Manual Trim**: You can trigger this via the Longhorn UI using the `Trim Filesystem` operation for attached volumes, or manually via the `fstrim` command.
- **Recurring Trim**: Apply a `filesystem-trim` recurring job to automate reclamation. 
- **Optimizing Effectiveness**:
    - By default, trim only applies to the volume head and snapshots already marked as removed.
    - If a trim request hits a valid snapshot, the filesystem may discard the trimmable file info without reclaiming space, requiring a remount to retry.
    - **Recommendation**: Enable the global setting [Remove Snapshots During Filesystem Trim](../../docs/1.12.0/references/settings#remove-snapshots-during-filesystem-trim) or the per-volume `UnmapMarkSnapChainRemoved` setting. This allows Longhorn to automatically mark ancestor snapshots as removed during a trim to maximize space reclamation.

For more information, see [Trim Filesystem](../../docs/1.12.0/nodes-and-volumes/volumes/trim-filesystem).

### Method 4 - Replica Auto-Balance

If space issues are caused by uneven replica distribution, you can trigger a rebalance.

- **Global/Volume Settings**: Longhorn supports `least-effort` and `best-effort` balancing modes. You can also set a `Replica Auto Balance Disk Pressure Threshold (%)` to trigger migrations once a disk reaches a specific capacity.
- **Limitations**: Auto-balancing only activates for volumes with a `Healthy` status. Unhealthy or detached volumes require manual intervention.

See [Replica Auto Balance](../../docs/1.12.0/high-availability/auto-balance-replicas) for detailed setup and behavior.

### Method 5 - Orphaned Replica Cleanup

Orphaned replica directories are untracked data folders on your disks that are no longer associated with any active Longhorn volume. This can happen if a node or disk goes down and is later reintroduced after its replicas have been removed from the system.

- **Identify Orphaned Data**: In the Longhorn UI, navigate to **Setting > Orphan Resources > Replica Data** to see a list of untracked directories grouped by node and disk.
- **Manual Deletion**: You can manually delete these directories by clicking **Operation > Delete** in the UI, or via `kubectl` by deleting the corresponding `orphan` resource.
- **Automatic Deletion**: To automate this, enable the `orphan-resource-auto-deletion` setting in Longhorn. This will automatically clean up orphaned resources after a defined grace period.

For detailed steps and `kubectl` examples, see [Orphaned Data Cleanup](../../docs/1.12.0/advanced-resources/data-cleanup/orphaned-data-cleanup).
