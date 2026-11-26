---
title: V2 Data Engine Instance Manager Upgrade
weight: 5
---

After upgrading the Longhorn manager, V2 instance managers must also be upgraded to the new version. Longhorn supports two upgrade methods:

- **[Live upgrade](#live-upgrade):** Upgrade instance managers one node at a time without detaching volumes. This keeps volumes attached but requires specific prerequisites.
- **[Offline upgrade](#offline-upgrade):** Detach all V2 volumes, then upgrade instance managers. This is the simplest approach and works in all configurations.

## Live Upgrade

### Prerequisites

- Upgrade from Longhorn `v1.12.2` or later.

> **Warning:**
>
> - V2 live upgrade is not supported in single-node clusters. Use an [offline upgrade](#offline-upgrade) instead.
> - Use the V2 Data Engine with the NVMe/TCP frontend. Live upgrade does not support ublk or sharded volumes.
> - Ensure V2 volumes are healthy and have healthy replicas on at least two different nodes. Each affected volume must have an available RW replica outside the node being upgraded.
> - Ensure nodes that temporarily host engines have a running V2 instance manager and a schedulable block disk.
> - Reserve capacity for replica rebuilding.
> - Back up your V2 volumes before performing a live upgrade to protect against unexpected failures during the upgrade.

### Upgrade Considerations

Live upgrade upgrades instance managers one node at a time without detaching volumes. Longhorn temporarily moves the V2 Engine CRs (NVMe/TCP targets) to other nodes, upgrades the instance manager, and then moves the Engine CRs back to their original nodes. Throughout the process, volumes remain attached, while workloads and EngineFrontend CRs (host-side NVMe/TCP initiators) stay on their original nodes, allowing I/O to continue without interruption.

- When possible, pre-download the target instance manager image on all V2 nodes before upgrading. This is optional. For example, on Kubernetes v1.24 and later:

  ```bash
  sudo crictl pull longhornio/longhorn-instance-manager:v1.13.x-head
  ```

- Live upgrades can trigger substantial replica rebuilding.
- During a live upgrade, Longhorn temporarily relocates engines to other nodes, which may temporarily increase I/O load on those nodes.
- During certain upgrade stages, Longhorn temporarily suspends rebuilding and reuse of replicas planned for detachment. Normal replica recovery resumes after engine restoration.
- Consider increasing [Replica Replenishment Wait Interval](../../../references/settings/#replica-replenishment-wait-interval) before upgrading to give Longhorn more time to reuse existing replicas before creating replacements.
- Do not expand or perform live migration on V2 volumes while a live upgrade is in progress. Wait until all node upgrades are completed and volumes are healthy before performing these operations.
- If an upgrade needs more time, increase **Instance Manager Upgrade Timeout** (default: 60 minutes). Changes take effect immediately for ongoing upgrades. This timeout does not apply to the `waiting-for-healthy-volumes` stage.

### Upgrade Process

1. Upgrade the Longhorn manager to the target version and wait for all manager pods to be running and ready.
2. In the Longhorn UI, go to **Settings** and configure the V2 upgrade settings before enabling automatic upgrade:
   - **Instance Manager Upgrade Timeout** (`instance-manager-upgrade-timeout`): Set the timeout in minutes. The default is 60 minutes.
3. Enable **Allow Instance Manager Automatic Upgrade** (`allow-instance-manager-automatic-upgrade`) for V2. This setting is disabled by default.
4. Longhorn upgrades one node at a time:
   1. Temporarily relocate engines to eligible nodes.
   2. Detach replica backends on the node being upgraded from their engines.
   3. Update the instance manager container image and wait for it to become ready.
   4. Restore engines to their original nodes.
   5. Wait for affected volumes to become healthy as replicas are reused or rebuilt.
   
   *(Note: Nodes that only host replicas skip engine relocation and restoration. After a node completes its upgrade, Longhorn proceeds to the next node).*

5. Monitor progress:

   ```bash
   kubectl -n longhorn-system get instancemanagerupgradecontrol
   kubectl -n longhorn-system get instancemanagerupgrades
   ```

   Wait for all node upgrades to reach `completed` and confirm that V2 volumes are healthy.

### Node Upgrade Order

Longhorn upgrades one node at a time. It prioritizes nodes that host V2 engines, then upgrades the remaining nodes. Within each group, Longhorn selects nodes in lexicographical order by node name.

After every pending node receives an initial upgrade attempt, Longhorn retries failed nodes one at a time in lexicographical order.

### Troubleshooting and Manual Recovery

| Situation | Action |
|-----------|--------|
| Pause the rolling upgrade | Disable **Allow Instance Manager Automatic Upgrade** for V2. The current node upgrade continues, but Longhorn does not start upgrades on additional nodes. Re-enable the setting to resume. This does not reset retry counts. |
| Unsupported replica topology | Increase the replica count and distribute replicas across different nodes, then wait for the volume to become healthy. If the topology cannot meet the prerequisites, use an offline upgrade. |
| Upgrade remains in `waiting-for-healthy-volumes` | Check replica recovery, available disk capacity, and replica scheduling. The upgrade timeout does not apply to this stage. Longhorn waits for affected volumes to become healthy. |
| Engine restoration remains blocked after a timeout | Restore readiness of the original node and its V2 instance manager. A timeout triggers engine restoration; Longhorn must finish restoration before marking the attempt failed and proceeding to another node. |
| Retry limit reached | Resolve the underlying issue, ensure no node upgrade is active, and recreate the upgrade control as described below. Disabling and re-enabling automatic upgrade does not reset retry counts. |

#### Retry After the Retry Limit Is Reached

After all pending nodes receive an initial upgrade attempt, Longhorn retries failed nodes up to five times.

If a node recovers after reaching this limit, ensure no node upgrade is in progress and **Allow Instance Manager Automatic Upgrade** remains enabled for V2. Then delete the upgrade control:

```bash
kubectl -n longhorn-system delete instancemanagerupgradecontrol longhorn-instance-manager-upgrade-control
```

Longhorn recreates the control and starts a new cycle for nodes that still need upgrading. Nodes whose active instance manager already runs the target image are excluded from the new cycle; recreating the control does not resolve outstanding volume recovery problems on those nodes.

## Offline Upgrade

If live upgrade prerequisites are not met, or you prefer a simpler approach, use the offline method:

1. Detach all V2 volumes and ensure their replicas are stopped.
2. When a V2 instance manager has no running instances, Longhorn automatically recreates its Pod with the new version.
3. Reattach volumes after all instance managers are upgraded.

> **Note:** If a node's V2 instance manager has no running instances, Longhorn automatically recreates its Pod with the new version regardless of the upgrade method chosen.
