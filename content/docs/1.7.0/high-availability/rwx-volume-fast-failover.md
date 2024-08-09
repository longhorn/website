---
  title: RWX Volume Fast Failover (Experimental)
  weight: 1
---

Release 1.7.0 adds a feature that minimizes the downtime for ReadWriteMany volumes when a node fails.  When enabled Longhorn uses a lease-based mechanism to monitor the state of the NFS server pod that exports the volume Longhorn reacts quickly to move it to another node if it becomes unresponsive.  See [RWX Volumes](../../nodes-and-volumes/volumes/rwx-volumes) for details on how the NFS server works.

To enable the feature, you set [RWX Volume Fast Failover](../../references/settings#rwx-volume-fast-failover-experimental) to "true".  Existing RWX volumes will need to be restarted to use the feature after the setting is changed.  That is done by scaling the workload down to zero and then back up again.  New volumes will pick up the setting at creation and be configured appropriately.  

With the feature enabled, when a pod is created or re-created, Longhorn also creates an associated lease object in the `longhorn-system` namespace, with the same name as the volume.  The NFS server pod keeps the lease renewed as proof of life.  If the renewal stops happening, Longhorn will take steps to create a new NFS server pod on another node and to re-attach the workload, even before the old node is marked as `Not Ready` by Kubernetes.

Along with adding the monitoring and fast reaction, the feature also changes the NFS server configuration to use a shortened grace period for client re-connection.

If the setting is changed back to "false", the lease check is disabled and pod relocation will use regular Kubernetes rules for node failure, even on existing volumes.  When the server pod is next restarted, it will revert to the normal grace period configuration.

For more information, see https://github.com/longhorn/longhorn/issues/6205.

> **Note:**  In rare circumstances, it is possible for the failover to become deadlocked. This happens if the NFS server pod creation is blocked by a recovery action that is itself blocked by the failover-in-process state.  If that is the case, and failover takes more than a minute or two, the workaround is to delete the associated lease object.  That clears the state, and a new lease is created along with the replacement server pod.  For example, if the stuck volume is named `pvc-2ce4e82e-7ccc-46c0-90a8-a141501fbf93` and the feature is enabled, there will be a lease with the same name.  To delete the associated lease object:
> ```bash
> kubectl -n longhorn-system delete lease pvc-2ce4e82e-7ccc-46c0-90a8-a141501fbf93
> ```
> See, for example, https://github.com/longhorn/longhorn/issues/9093.

### Performance Testing

If your cluster has many RWX volumes, enabling the RWX Volume Fast Failover feature has a high impact on system performance in terms of `API requests`, `RPC rate`, `CPU`, and `memory` usage. Below are key observations from testing:

#### **Environment:**
- **Setup:** 1 Control Node + 3 Worker Nodes (v1.27.15+rke2r1)
- **Workload:** 60 Deployments with 60 RWX volumes with `soft` mount

#### **Test Results:**

| **Metric**                           | **Fast Failover Enabled** | **Fast Failover Disabled** | **Difference**             |
|--------------------------------------|---------------------------|----------------------------|----------------------------|
| **1. Number of API Requests**        | 59 req/s                  | 37.5 req/s                 | **+57.3%**                 |
| **2. RPC Rate**                      | 57 ops/s                  | 37 ops/s                   | **+54.1%**                 |
| **3. Memory Usage**                  | Higher Peaks/Minima       | Lower Peaks/Minima         | More usage with Fast Failover Enabled |
| **4. Longhorn Manager CPU/RAM**      | 417MB / 0.13 CPU          | 405MB / 0.1 CPU            | **+3% RAM** / **+30% CPU** |
| **5. Share Manager CPU/RAM**         | 2.25GB / 0.26 CPU         | 2.2GB / 0.235 CPU          | **+2.3% RAM** / **+10.6% CPU** |

These results demonstrate that enabling Fast Failover leads to a significant increase in resource consumption if your cluster has many RWX volumes. You should monitor these metrics closely, after enabling this feature, to ensure your environment can handle the additional load.

For detailed screenshots and further context, please refer to the [related issue discussion](https://github.com/longhorn/longhorn/issues/6205#issuecomment-2262625965).
