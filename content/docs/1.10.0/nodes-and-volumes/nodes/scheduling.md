---
title: Scheduling
weight: 5
---

In this section, you'll learn how Longhorn schedules replicas based on multiple factors.

## Scheduling Policy

Longhorn's scheduling policy has two stages. The scheduler only goes to the next stage if the previous stage is satisfied. Otherwise, the scheduling will fail.

If any tag has been set in order to be selected for scheduling, the node tag and the disk tag have to match when the node or the disk is selected.

The first stage is the **node and zone selection stage.** Longhorn will filter the node and zone based on the `Replica Node Level Soft Anti-Affinity` and `Replica Zone Level Soft Anti-Affinity` settings.

The second stage is the **disk selection stage.** Longhorn will filter the disks that satisfy the first stage based on the `Replica Disk Level Soft Anti-Affinity`, `Storage Minimal Available Percentage`, `Storage Over Provisioning Percentage`, and other disk-related factors like requested disk space.

### The Node and Zone Selection Stage

Longhorn evaluates which **nodes** are suitable for scheduling a new replica based on a series of criteria. The decision-making process follows a specific order to ensure optimal placement for fault tolerance. 

#### 1. Node Tag Matching

Longhorn first checks for node selector tags on the volume.
- If the volume has node selector tags, only nodes with matching tags are eligible.
- If the volume has **no node selector**, the behavior depends on the setting **Allow Empty Node Selector Volume**:
    - `true` (default): Schedules on nodes **with or without tags**.
    - `false`: Schedules **only** on nodes **without tags**.

#### 2. Cordoned Node Handling

The setting **Disable Scheduling On Cordoned Node** determines whether cordoned nodes are eligible for replica scheduling:
- `true` (default): Cordoned nodes are **excluded**.
- `false`: Cordoned nodes are **eligible**.

#### 3.  Anti-Affinity Rules Across Nodes and Zones

Longhorn prioritizes spreading replicas across different **nodes** and **zones** to improve fault tolerance. A **"new"** node or zone is one that does **not** currently host any replica of the volume, while an **"existing"** node or zone already hosts a replica of the volume. The selection logic proceeds in the following order:

The scheduler attempts to place the new replica in the most "isolated" location possible, following this hierarchy of preference:
1.  **New Node in a New Zone** (most preferred)
2.  **New Node in an Existing Zone**
3.  **Existing Node in an Existing Zone** (least preferred)

The following table details the required settings for a replica to be scheduled in each scenario:

| **Scenario** | **Replica Zone Level Soft Anti-Affinity** | **Replica Node Level Soft Anti-Affinity** | **Scheduler Action** |
| :--- | :--- | :--- | :--- |
| **New Node in a New Zone** | `false` | `false` | **Schedules** the replica. |
| | Any other value | Any other value | **Does not** schedule the replica. |
| **New Node in an Existing Zone** | `true` | `false` | **Schedules** the replica if no new zone is available. |
| | Any other value | Any other value | **Does not** schedule the replica. |
| **Existing Node in an Existing Zone** | `true` | `true` | **Schedules** the replica if no other options are available. |
| | Any other value | Any other value | **Does not** schedule the replica. |

### Disk Selection Stage

Once the node and zone stage is satisfied, Longhorn decides whether it can schedule the replica on any disk of the selected node. It checks the available disks based on matching tags, total disk space, and available disk space. It also considers whether another replica already exists and the anti-affinity settings.

Longhorn checks all available disks on the selected node to ensure they meet the following criteria:

1.  **Disk Tag Matching**:
    - If the volume has disk tags, the disk must match any specified tags required for the replica.
    - If the volume has no disk tags, the behavior depends on the setting **Allow Empty Disk Selector Volume**:
        - `true` (default): Allows scheduling on disks **with or without tags**.
        - `false`: Only allows scheduling on disks **without tags**.
2.  **Available Space Check**:
    - The disk must have sufficient available space based on the configured `Storage Minimal Available Percentage`.
3.  **Anti-Affinity Settings**:
    - **Hard Anti-Affinity**: Prevents scheduling a replica on a disk that already hosts another replica of the same volume.
    - **Soft Anti-Affinity** (when enabled): Prefers scheduling the replica on a disk without an existing replica, even if it’s a less optimal choice in terms of space or other factors.
4.  **Space Conditions**: Two formulas determine if a disk is schedulable:
    - **Actual Space Usage Condition**: Ensures sufficient usable storage remains after accounting for currently used space.
        - Formula: `(Storage Available - Actual Size) > (Storage Maximum × Minimal Available Percentage) / 100`
    - **Scheduling Space Condition**: Ensures the replica’s size (plus any scheduled but unwritten data) fits within the over-provisioning limit.
        - Formula: `(Size + Storage Scheduled) ≤ ((Storage Maximum - Storage Reserved) × Over Provisioning Percentage) / 100`

    > **Note:** During disk evaluation, since no specific replica is being scheduled yet, `Actual Size` and `Size` are temporarily treated as `0` in these formulas.

If any of these conditions fail including disk tag, anti-affinity, or space requirements, the disk is marked unschedulable, and Longhorn will not place the replica on it.

If either condition fails or the disk does not meet tag or anti-affinity requirements, it is marked unschedulable, and Longhorn will not place the replica on that disk.

#### Example Scenario

Consider a node (**Node A**) with two disks:
- **Disk X**: 1 GB available, 4 GB max space
- **Disk Y**: 2 GB available, 8 GB max space

##### Stage 1: Initial Disk Evaluation

During the initial disk selection stage, Longhorn performs a basic check on all available disks. At this point, no specific replica has been selected, so `Actual Size` and `Size` are treated as `0`.

**Disk X Evaluation**
- **Available Space**: 1 GB
- **`Storage Minimal Available Percentage`**: 25% (default)
- **Minimum required available space**: `(4 GB × 25) / 100 = 1 GB`
- **Result**: **Disk X** fails the `Actual Space Usage Condition` because its available space (1 GB) is **not greater than** the minimum required (1 GB). Therefore, Disk X is not schedulable unless the `Storage Minimal Available Percentage` is set to 0.

**Disk Y Evaluation**
- **Available Space**: 2 GB
- **`Storage Minimal Available Percentage`**: 10%
- **Minimum required available space**: `(8 GB × 10) / 100 = 0.8 GB`
- **Result**: **Disk Y** passes the `Actual Space Usage Condition` because its available space (2 GB) is greater than the minimum required (0.8 GB).

Next, we check the **Scheduling Space Condition**:
- **Scheduled Space**: 2 GB
- **`Storage Reserved`**: 1 GB
- **`Over Provisioning Percentage`**: 100% (default)
- **Max Provisionable Storage**: `(8 GB - 1 GB) × 100 / 100 = 7 GB`
- **Result**: **Disk Y** passes the `Scheduling Space Condition` because the currently scheduled space (2 GB) is less than the max provisionable storage (7 GB).

Since Disk Y passes all conditions, it is marked as a schedulable disk candidate.

##### Stage 2: Anti-Affinity Rules

Let's assume both Disk X and Disk Y pass the initial space checks and Disk X already hosts a replica for the same volume.

**Hard Anti-Affinity**
- If **hard anti-affinity** is enabled, Longhorn will not schedule the new replica on Disk X. It will instead attempt to schedule it on Disk Y.
* If Disk Y is not suitable (e.g., mismatched disk tags), scheduling for this replica will fail.

**Soft Anti-Affinity**
- If **soft anti-affinity** is enabled, Longhorn **prefers** to schedule the replica on Disk Y to avoid co-locating replicas.
- However, if Disk Y is unsuitable for any reason, Longhorn **may still schedule** the replica on Disk X. This allows for sharing a disk as a fallback option when no other viable candidates are available.

## Settings

For more information on settings that are relevant to scheduling replicas on nodes and disks, refer to the settings reference:

- [Disable Scheduling On Cordoned Node](../../../references/settings/#disable-scheduling-on-cordoned-node)
- [Replica Soft Anti-Affinity](../../../references/settings/#replica-node-level-soft-anti-affinity) (also called Replica Node Level Soft Anti-Affinity)
- [Replica Zone Level Soft Anti-Affinity](../../../references/settings/#replica-zone-level-soft-anti-affinity)
- [Replica Disk Level Soft Anti-Affinity](../../../references/settings/#replica-disk-level-soft-anti-affinity)
- [Storage Minimal Available Percentage](../../../references/settings/#storage-minimal-available-percentage)
- [Storage Over Provisioning Percentage](../../../references/settings/#storage-over-provisioning-percentage)
- [Allow Empty Node Selector Volume](../../../references/settings/#allow-empty-node-selector-volume)
- [Allow Empty Disk Selector Volume](../../../references/settings/#allow-empty-disk-selector-volume)

## Notice
Longhorn relies on label `topology.kubernetes.io/zone=<Zone name of the node>` or `topology.kubernetes.io/region=<Region name of the node>` in the Kubernetes node object to identify the zone/region.

Since these are reserved and used by Kubernetes as [well-known labels](https://kubernetes.io/docs/reference/labels-annotations-taints/#topologykubernetesiozone).
