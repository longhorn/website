---
title: Offline Replica Rebuilding
weight: 5
---

Starting with v1.9.0, Longhorn supports offline replica rebuilding, allowing degraded volumes to automatically rebuild replicas while detached.​

## Global Setting `offline-replica-rebuilding`

- When enabled, Longhorn automatically initiates offline rebuilding for eligible volumes.​
- For more information, see [settings](../../../references/settings#offline-replica-rebuilding).

## Per-Volume Override

- You can override the global `Offline Replica Rebuilding` setting for each volume individually using the Longhorn UI or by running `kubectl -n longhorn-system edit volume [volume-name]` and modifying the `Spec.OfflineRebuilding` field.
- When set to `enabled` or `disabled`, this per-volume setting takes precedence over the global configuration. The default value is `ignored`.

| Global Setting (`offline-replica-rebuilding`) | Per-Volume Setting (`spec.offlineRebuilding`) | Offline Rebuilding Enabled |
| :-------------------------------------------: | :-------------------------------------------: | :------------------------: |
| `true`                                        | `ignored`                                     | Yes                        |
| `false`                                       | `ignored`                                     | No                         |
| `true`                                        | `enabled`                                     | Yes                        |
| `false`                                       | `enabled`                                     | Yes                        |
| `true`                                        | `disabled`                                    | No                         |
| `false`                                       | `disabled`                                    | No                         |

## Rebuilding Process

- When triggered, Longhorn attaches the volume without activating the frontend, rebuilds any missing replicas, and then detaches the volume upon completion.
- This process can be interrupted if the workload scales up.

## Rebuilding Not Started or Canceled

When offline rebuilding starts, degraded volumes can get stuck in the attached state if rebuilding conditions are not met. To prevent this, if the necessary conditions are not satisfied, offline rebuilding will not start or will be canceled.

- **Benefits:**
  - It ensures volumes don't remain stuck in the attached state if rebuilding never finishes.
  - It prevents wasteful rebuilding attempts.
  - It reduces unnecessary volume attachment and detachment cycles.
  - It provides predictable rebuilding behavior based on resource availability.

- **Required conditions:**

  Offline rebuilding automatically starts for degraded volumes once the required conditions are met. These conditions include:

  - A reusable failed replica exists, or
  - A disk candidate exists:
    - The instance manager on the node hosting the disk must be ready.
    - The disk's containing node is schedulable.
    - The disk itself is schedulable.

### Before Offline Rebuilding Starts

When offline rebuilding is enabled, Longhorn determines whether it should start.

1. Longhorn detects a degraded, detached volume.
2. The system validates whether the required conditions are met before starting the rebuild.
3. If the conditions are met, rebuilding proceeds. Otherwise, the volume remains detached.
4. The required conditions are re-evaluated when a node is added, becomes ready, or becomes schedulable.

### During Offline Rebuilding

Longhorn determines if a rebuilding process should be canceled while in progress.

1. Longhorn detects the volume's status when offline rebuilding starts and the volume is attached.
2. If the volume's `Scheduled` condition status becomes `False`, the offline rebuilding is canceled, and the volume is detached.
3. If the required conditions are met again, offline rebuilding restarts; otherwise, the volume remains detached.

### Examples

- Successful offline rebuilding:
  1. A volume is created with 3 replicas in a 3-worker-node cluster.
  2. Offline rebuilding is enabled.
  3. The volume is detached and then a replica of the volume is deleted.
  4. Offline rebuilding begins, and the volume is attached.
  5. After rebuilding finishes, the volume is detached.
- Offline rebuilding does not start even when it is enabled:
  1. A volume is created with 3 replicas in a 3-worker-node (A, B, and C) cluster.
  2. Offline rebuilding is enabled.
  3. Worker node A is unschedulable.
  4. The volume replica on worker node A is deleted.
  5. Because only two schedulable worker nodes exist, offline rebuilding will not start.
- A worker node is drained during offline rebuilding:
  1. A volume is created with 3 replicas in a 3-worker-node (A, B, and C) cluster.
  2. Offline rebuilding is enabled.
  3. The volume is detached, and then the volume replica on worker node A is deleted.
  4. Offline rebuilding begins, and the volume is attached to rebuild a replica on worker node A.
  5. Worker node A is drained making it unschedulable, and the volume replica on worker node A is deleted.
  6. The volume remains attached until the volume's `Scheduled` condition status becomes `False`.
  7. The volume is detached until worker node A is uncordoned or a new schedulable node is added.

## Limitations

Offline rebuilding is not supported for faulted volumes.
