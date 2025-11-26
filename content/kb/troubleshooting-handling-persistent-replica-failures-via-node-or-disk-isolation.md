---
title: "Troubleshooting: Handling Persistent Replica Failures via Node or Disk Isolation"
authors:
- "Derek Su"
draft: false
date: 2025-11-25
versions:
- "all"
categories:
- "replica rebuilding"
- "backing image"
- "troubleshooting"
---

## Applicable Versions

All Longhorn versions.

## Symptom

A Longhorn Replica enters a **Failed** state due to environmental instability. When the user deletes the failed replica to trigger a rebuild, the scheduler may place the new replica on the same problematic node or disk. This results in a **Rebuild Loop**, with each new replica failing immediately on the unstable node or disk.

Common scenarios causing this behavior include:

* Host Disk Physical Errors: Bad sectors, I/O timeouts, or SMART errors detected in kernel logs (`dmesg`).
* Network Instability: A specific node experiences high latency or packet loss, causing the Longhorn engine to mark replicas as failed due to connection timeouts.
* Resource Exhaustion: The node is under extreme memory/CPU pressure, causing the `longhorn-instance-manager` pod to crash.

## Root Cause

Longhorn's default behavior upon replica deletion is to rebuild it immediately to satisfy the `numberOfReplicas` requirement.

If the problematic node remains in the Kubernetes `Ready` state and its disk shows sufficient free space, the Longhorn replica scheduler may choose it again for the new replica. Because the scheduler has no visibility into the underlying instability, it can repeatedly select the same unstable node or disk unless the user intervenes.

## Mitigation

The standard recovery procedure requires a strategy of **Isolate then Rebuild**. This forces the scheduler to bypass the problematic node or disk and place the new replica on a different, healthy node or disk.

### Phase 1: Isolate the Unstable Node or Disk

Prevent the Longhorn Scheduler from assigning new workloads to the compromised infrastructure.

1. Open the Longhorn UI.
2. Navigate to the **Nodes** tab.
3. Locate the node hosting the failed replica and select **Edit node and disks**.
4. Unschedule node or disk

   - Disable the `Node Scheduling` box,
   - or, find the specific disk entry and disable the `Scheduling` box.

    > **Note**:
    > - Do not enable **Eviction Requested** at this stage; the goal is simply to stop new placement.
    > - Choose only one of these options depending on whether the entire node or only the disk is unstable.

5. Click **Save**.

### Phase 2: Delete the Failed Replica

Now that the unstable path is blocked, remove the failed replica.

1. Navigate to the **Volumes** tab.
2. Click on the name of the **Degraded** volume.
3. Scroll to the **Replicas** section.
4. Identify the replica located on the isolated node or disk with status **Failed**.
5. Click the context menu and select **Delete**.

### Phase 3: Rebuild the Replica

Upon detecting an insufficient replica count, Longhorn triggers the replica scheduler to scan the cluster. Because the original disk is now unschedulable, the scheduler selects a different node or disk. The new replica then begins rebuilding from a healthy source, eventually returning the Volume status to **Healthy**.

## Additional Scenario: Backing Image Rebuild Loops

This mitigation strategy also applies to **Backing Images** when `minNumberOfCopies` is enabled

Similar to volume replicas, if a disk failure prevents a Backing Image from syncing, the Backing Image Manager may repeatedly attempt to re-download the file to the same problematic disk to satisfy the minimum copy requirement.

By performing [Phase 1: Isolate the Unstable Node or Disk](#phase-1-isolate-the-unstable-node-or-disk), you force the system to bypass the compromised node or disk. Longhorn will then automatically select a different, healthy node or disk to fulfill the `minNumberOfCopies` requirement, effectively breaking the loop.
