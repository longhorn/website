---
title: Scheduling
weight: 5
---

In this section, you'll learn how Longhorn schedules replicas based on multiple factors.

### Scheduling Policy

Longhorn's scheduling policy has two stages. The scheduler only goes to the next stage if the previous stage is satisfied. Otherwise, the scheduling will fail.

If any tag has been set in order to be selected for scheduling, the node tag and the disk tag have to match when the node or the disk is selected.

The first stage is the **node and zone selection stage.** Longhorn will filter the node and zone based on the `Replica Node Level Soft Anti-Affinity` and `Replica Zone Level Soft Anti-Affinity` settings.

The second stage is the **disk selection stage.** Longhorn will filter the disks that satisfy the first stage based on the `Replica Disk Level Soft Anti-Affinity`, `Storage Minimal Available Percentage`, `Storage Over Provisioning Percentage`, and other disk-related factors like requested disk space.

#### The Node and Zone Selection Stage

First, Longhorn will always try to schedule the new replica on a new node with a new zone if possible. In this context, "new" means that a replica for the volume has not already been scheduled to the zone or node, and "existing" refers to a node or zone that already has a replica scheduled to it.

At this time, if both the `Replica Node Level Soft Anti-Affinity` and `Replica Zone Level Soft Anti-Affinity` settings are un-checked, and if there is no new node with a new zone, Longhorn will not schedule the replica.

Then, Longhorn will look for a new node with an existing zone. If possible, it will schedule the new replica on the new node with an existing zone.

At this time, if `Replica Node Level Soft Anti-Affinity` is un-checked and `Replica Zone Level Soft Anti-Affinity` is checked, and there is no new node with an existing zone, Longhorn will not schedule the replica.

Last, Longhorn will look for an existing node with an existing zone to schedule the new replica. At this time both `Replica Node Level Soft Anti-Affinity` and `Replica Zone Level Soft Anti-Affinity` should be checked.

#### Disk Selection Stage

Once the node and zone stage is satisfied, Longhorn will decide whether it can schedule the replica on any disk of the node. Longhorn will check the available disks on the selected node with the matching tag, the total disk space, and the available disk space. It will also check whether another replica already exists and whether anti-affinity is set to be "hard" (no sharing) or "soft" (prefer not to share.)

Longhorn checks all available disks on the selected node to ensure they meet the following criteria:

1. **Disk Tag Matching**: The disk must match any specified tags required for the replica.
2. **Available Space Check**: The disk must have sufficient available space based on the configured `Storage Minimal Available Percentage`.
3. **Anti-Affinity Settings**:
   - **Hard Anti-Affinity**: Prevents scheduling a replica on a disk that already hosts another replica of the same volume.
   - **Soft Anti-Affinity** (when enabled): Prefers scheduling the replica on a disk without an existing replica, even if it’s a less optimal choice in terms of space or other factors.
4. **Space Conditions**: Two formulas determine if a disk is schedulable:
   - **Actual Space Usage Condition**: Ensures sufficient usable storage remains after accounting for currently used space.
     - Formula: `(Storage Available - Actual Size) > (Storage Maximum × Minimal Available Percentage) / 100`
   - **Scheduling Space Condition**: Ensures the replica’s size (plus any scheduled but unwritten data) fits within the over-provisioning limit.
     - Formula: `(Size + Storage Scheduled) ≤ ((Storage Maximum - Storage Reserved) × Over Provisioning Percentage) / 100`
   - **Note**: During disk evaluation, since no specific replica is being scheduled, `Actual Size` and `Size` are treated as 0 in these formulas.

If either condition fails or the disk does not meet tag or anti-affinity requirements, it is marked unschedulable, and Longhorn will not place the replica on that disk.

**Example Scenario**
Consider a node (Node A) selected during the node and zone stage, with two disks:
- **Disk X**: 1 GB available space, 4 GB max space
- **Disk Y**: 2 GB available space, 8 GB max space

**Disk Evaluation**

`Actual Size` and `Size` are treated as 0 in this stage.

- **Disk X**:
  - Available space: `1 GB`
  - `Storage Minimal Available Percentage` : 25% (default)
  - Minimum required available space: `(Storage Maximum × Storage Minimal Available Percentage) / 100` ➔ `(4 GB × 25) / 100 = 1 GB`
  - Disk X not pass the **Actual Space Usage Condition**, Since available space (1 GB) is not greater than Minimum required available space (1 GB), Disk X is unschedulable unless `Storage Minimal Available Percentage` is set to 0.
  
- **Disk Y**:
  - Available space: `2 GB`
  - `Storage Minimal Available Percentage`: 10%
  - Minimum required available space: `(Storage Maximum × Storage Minimal Available Percentage) / 100` ➔`(8 GB × 10) / 100 = 0.8 GB`
  - Disk Y pass the **Actual Space Usage Condition**, Since available space (2 GB) is greater than minimum required available space (0.8 GB).

  Next, check the **Scheduling Space Condition**
  - Scheduled space: `2 GB`
  - Storage Reserved: `1 GB`
  - `Over Provisioning Percentage`: 100% (default)
  - Max provisionable storage: 
  `(Storage Maximum - Storage Reserved) × Over Provisioning Percentage / 100` ➔ `(8 GB - 1 GB) × 100 / 100 = 7 GB`
  - Disk Y pass the **Scheduling Space Condition**, Since scheulded space (2 GB) is less than max provisionable storage (7 GB), Disk Y is schedulable. If Disk Y matches the disk tag, Longhorn can schedule the replica on Disk Y.

**Evaluating Candidate Disks for Replica** 

The replica to be scheduled requires 1 GB of space, so `Size` is 1 GB. Assume that the `Actual Size` on both disks is 0.5 GB.

- **Disk X**:
  - Remain available space: `(Storage Available - Actual Size) ➔ (1 GB - 0.5 GB = 0.5 GB)`
  - `Storage Minimal Available Percentage` : 25% (default)
  - Minimum required available space: `(Storage Maximum × Storage Minimal Available Percentage) / 100` ➔ `(4 GB × 25) / 100 = 1 GB`
  - Disk X not pass the **Actual Space Usage Condition**, Since no remaining available space (0.5 GB) is not greater than Minimum required available space (1 GB).
  
- **Disk Y**:
  - Remain available space: `(Storage Available - Actual Size) ➔ (2 GB - 0.5 GB = 1.5 GB)`
  - `Storage Minimal Available Percentage`: 10%
  - Minimum required available space: `(Storage Maximum × Storage Minimal Available Percentage) / 100` ➔`(8 GB × 10) / 100 = 0.8 GB`
  - Disk Y pass the **Actual Space Usage Condition**, Since remaining available space (1.5 GB) is greater than minimum required available space (0.8 GB).

  Then check if satisfies the **Scheduling Space Condition**
  - Scheduled space: `2 GB`
  - Total Scheduled space: `(Size + Storage Scheduled) ➔ (1 GB + 2 GB = 3 GB)`
  - Storage Reserved: `1 GB`
  - `Over Provisioning Percentage`: 100% (default)
  - Max provisionable storage: 
  `(Storage Maximum - Storage Reserved) × Over Provisioning Percentage / 100` ➔ `(8 GB - 1 GB) × 100 / 100 = 7 GB`
  - Disk Y pass the **Scheduling Space Condition**, Since total scheulded space (3 GB) is less than max provisionable storage (7 GB), Disk Y is schedulable. If Disk Y matches the disk tag, Longhorn can schedule the replica on Disk Y.


**Anti-Affinity Behavior**

Let’s assume both Disk X and Disk Y pass the **Actual Space Usage Condition** and **Scheduling Space Condition**, and Disk X already hosts a replica. 


Now consider the anti-affinity setting:

- **Hard Anti-Affinity**
    - Longhorn will schedule the new replica on Disk Y to avoid co-locating replicas. 
    - If Disk Y is unsuitable (e.g., mismatched tags), scheduling fails—replicas cannot share the same disk under hard anti-affinity.


- **Soft Anti-Affinity**
    - The setting `Replica Disk Soft Anti-Affinity` is enabled.
    - Longhorn prefers to schedule the new replica on Disk Y (if it meets tag and space requirements) to avoid co-locating replicas, even if Disk X is otherwise viable.
    - If Disk Y is unsuitable (e.g., insufficient space or mismatched tags), Longhorn may still schedule on Disk X if it meets all other conditions, as soft anti-affinity allows sharing as a fallback.
    
    **Soft Anti-Affinity Levels**
    -   **Replica Disk Level Soft Anti-Affinity**  
    Allow scheduling on disks with existing healthy replicas of the same volume

    -   **Replica Node Level Soft Anti-Affinity**  
    Allow scheduling on nodes with existing healthy replicas of the same volume

    -   **Replica Zone Level Soft Anti-Affinity**  
    Allow scheduling on zones with existing healthy replicas of the same volume


### Settings

For more information on settings that are relevant to scheduling replicas on nodes and disks, refer to the settings reference:

- [Disable Scheduling On Cordoned Node](../../../references/settings/#disable-scheduling-on-cordoned-node)
- [Replica Soft Anti-Affinity](../../../references/settings/#replica-node-level-soft-anti-affinity) (also called Replica Node Level Soft Anti-Affinity)
- [Replica Zone Level Soft Anti-Affinity](../../../references/settings/#replica-zone-level-soft-anti-affinity)
- [Replica Disk Level Soft Anti-Affinity](../../../references/settings/#replica-disk-level-soft-anti-affinity)
- [Storage Minimal Available Percentage](../../../references/settings/#storage-minimal-available-percentage)
- [Storage Over Provisioning Percentage](../../../references/settings/#storage-over-provisioning-percentage)
- [Allow Empty Node Selector Volume](../../../references/settings/#allow-empty-node-selector-volume)
- [Allow Empty Disk Selector Volume](../../../references/settings/#allow-empty-disk-selector-volume)

### Notice
Longhorn relies on label `topology.kubernetes.io/zone=<Zone name of the node>` or `topology.kubernetes.io/region=<Region name of the node>` in the Kubernetes node object to identify the zone/region.

Since these are reserved and used by Kubernetes as [well-known labels](https://kubernetes.io/docs/reference/labels-annotations-taints/#topologykubernetesiozone).
