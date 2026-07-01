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

## Limitations

It does not apply to faulted volumes.​
