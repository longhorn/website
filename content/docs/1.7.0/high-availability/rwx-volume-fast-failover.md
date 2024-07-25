---
  title: RWX Volume Fast Failover (Experimental)
  weight: 1
---

Release 1.7.0 adds a feature that minimizes the downtime for ReadWriteMany volumes when a node fails.  When enabled Longhorn uses a lease-based mechanism to monitor the state of the NFS server pod that exports the volume Longhorn reacts quickly to move it to another node if it becomes unresponsive.  See [RWX Volumes](../../nodes-and-volumes/volumes/rwx-volumes) for details on how the NFS server works.

To enable the feature, you set [RWX Volume Fast Failover](../../references/settings#rwx-volume-fast-failover) to "true".  Existing RWX volumes will need to be restarted to use the feature after the setting is changed.  That is done by scaling the workload down to zero and then back up again.  New volumes will pick up the setting at creation and be configured appropriately.  

With the feature enabled, when a pod is created or re-created, Longhorn will also create an associated lease object in the `longhorn-system` namespace, with the same name as the volume.  The NFS server pod keeps the lease renewed as proof of life.  If the renewal stops happening, Longhorn will take steps to create a new NFS server pod on another node and to re-attach the workload, even before the old node is marked as `Not Ready` by Kubernetes.

Along with adding the monitoring and fast reaction, the feature also changes the NFS server configuration to use a shortened grace period for client re-connection.

If the setting is changed back to "false", the lease check is disabled and pod relocation will use regular Kubernetes rules for node failure, even on existing volumes.  When the server pod is next restarted, it will revert to the normal grace period configuration.

For more information, see https://github.com/longhorn/longhorn/issues/6205.
