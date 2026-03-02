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

This is effective if you have sufficient healthy replicas and available space on other nodes.

1. **Disable scheduling for the stressed node**: In the Longhorn UI, go to the **Nodes** tab, select the stressed node, and set **Scheduling** to `Disable`. This prevents Longhorn from rebuilding the replacement replica on the same full node.
2. **Identify a volume with a replica on the stressed node**:
    > **CRITICAL**: Only proceed if the volume status is **Healthy** and you have at least 2 other healthy replicas on different nodes.
3. **Delete the replica**: Navigate to the **Volume Detail** page for the identified volume. In the **Replicas** section, find the replica located on the stressed node and select **Delete**.
4. **Verification**: Longhorn will automatically detect the missing replica and rebuild it on a different node with available space.
5. **Re-enable scheduling**: Once the node has sufficient space or you have added more capacity, remember to set **Scheduling** back to `Enable`.

### Method 2 - Reclaim Space from Snapshots

Longhorn volumes can consume more space than their actual data size due to historical snapshots.

- **Delete Manual Snapshots**: Identify volumes with large or numerous snapshots and delete them via the Volume Detail page to merge data into the base image.
- **Setup Recurring Jobs**: To prevent future buildup, implement a `snapshot-delete` recurring job. This job periodically removes and purges snapshots that exceed a specified retention count. See [Recurring Snapshots and Backups](../../docs/archives/1.11.0/snapshots-and-backups/scheduling-backups-and-snapshots) for configuration details.

### Method 3 - Filesystem Trim (Unmap)

Deleting files within the workload's filesystem does not automatically free up blocks on the underlying Longhorn block device.

- **Prerequisites**: Ensure you are on Longhorn v1.4.0+ and using a trimmable filesystem like EXT4 or XFS.
- **Manual Trim**: You can trigger this via the Longhorn UI using the `Trim Filesystem` operation for attached volumes, or manually via the `fstrim` command.
- **Recurring Trim**: Apply a `filesystem-trim` recurring job to automate reclamation. For more information, see [Trim Filesystem](../../docs/1.12.0/nodes-and-volumes/volumes/trim-filesystem.md).

### Method 4 - Replica Auto-Balance

If space issues are caused by uneven replica distribution, you can trigger a rebalance.

- **Global/Volume Settings**: Longhorn supports `least-effort` and `best-effort` balancing modes. You can also set a `Replica Auto Balance Disk Pressure Threshold (%)` to trigger migrations once a disk reaches a specific capacity.
- **Limitations**: Auto-balancing only activates for volumes with a `Healthy` status. Unhealthy or detached volumes require manual intervention.

See [Replica Auto Balance](../../docs/1.12.0/high-availability/auto-balance-replicas.md) for detailed setup and behavior.

## Recommended Long-term Solutions

- **Enable Replica Auto-Balance**: Use `best-effort` or `least-used-node-filling` settings.
- **Adjust Overprovisioning**: Lower the `Storage Overprovisioning Percentage` to a safer margin (for example, 150-200%).
- **Automate Cleanup**: Use **Recurring Jobs** for `snapshot-delete` and `filesystem-trim`.
