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

This usually occurs due to the high overprovisioning, snapshot accumulation, or uneven replica scheduling. The node's disk is full, preventing Longhorn from writing data or creating new replicas.

## Workaround - Manual Replica Evacuation

If you have sufficient healthy replicas on other nodes, follow these steps to manually free up space:

### 1. Identify the Stressed Node

Locate the node running out of storage via the **Longhorn UI (Nodes tab)** or by checking for the `DiskPressure` condition in Kubernetes.

### 2. Locate Redundant Replicas

Find a volume with a replica on the stressed node.

> **CRITICAL**: Only proceed if the volume status is **Healthy** and you have at least 2 other healthy replicas on different nodes.

### 3. Manually Remove the Replica

- Navigate to the **Volumes Detail** page in the Longhorn UI.
- In the **Replicas** section, find the replica on the stressed node and select **Delete**.

### 4. Verification

Longhorn automatically schedules and rebuilds a new replica on a different node with available space.

## Recommended Long-term Solutions
- **Enable Replica Auto-Balance**: Use `best-effort` or `least-used-node-filling` settings.
- **Adjust Overprovisioning**: Lower the `Storage Overprovisioning Percentage` to a safer margin (for example, 150-200%).
- **Automate Cleanup**: Use **Recurring Jobs** for `snapshot-delete` and `filesystem-trim`.
