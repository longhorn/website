---
title: Restore to a cluster contains data using Rancher snapshot
weight: 4
---

This doc describes what users need to do after restoring the cluster with a Rancher snapshot.

## Assumptions:
- **Most of the data and the underlying disks still exist** in the cluster before the restore and can be directly reused then.
- There is a backupstore holding all volume data.
- The setting [`Disable Revision Counter`](../../../references/settings/#disable-revision-counter) is false. (It's false by default.) Otherwise, users need to manually check if the data among volume replicas are consistent, or directly restore volumes from backup.

## Expectation:
- All settings and node & disk configs will be restored.
- As long as the valid data still exists, the volumes can be recovered without using a backup. In other words, we will try to avoid restoring backups, which may help reduce Recovery Time Objective (RTO) as well as save bandwidth.
- Detect the invalid or out-of-sync replicas as long as the related volume still contains a valid replica after the restore.

## Behaviors & Requirement of Rancher restore
- According to [the Rancher restore article](https://rancher.com/blog/2018/2018-05-30-recover-rancher-kubernetes-cluster-from-backup/), you have to restart the Kubernetes components on all nodes. Otherwise, there will be tons of resource update conflicts in Longhorn.

## Actions after the restore
- Restart all Kubernetes components for all nodes. See the above link for more details.

- Kill all longhorn manager pods then Kubernetes will automatically restart them. Wait for conflicts in longhorn manager pods to disappear.

- All volumes may be reattached. If a Longhorn volume is used by a single pod, users need to shut down then recreate it. For Deployments or Statefulsets, Longhorn will automatically kill then restart the related pods.

- If the following happens after the snapshot and before the cluster restore:
    - A volume is unchanged: Users don't need to do anything.
    - The data is updated: Users don't need to do anything typically. Longhorn will automatically fail the replicas that don't contain the latest data.
    - A new volume is created: This volume will disappear after the restore. Users need to recreate a new volume, launch [a single replica volume](../../data-recovery/export-from-replica) based on the replica of the disappeared volume, then transfer the data to the new volume.
    - A volume is deleted: Since the data is cleaned up when the volume is removed, the restored volume contains no data. Users may need to re-delete it.
    - For DR volumes: Users don't need to do anything. Longhorn will redo a full restore.
    - Some operations are applied for a volume:
        - Backup: The backup info of the volume should be resynced automatically.
        - Snapshot: The snapshot info of the volume should be resynced once the volume is attached.
        - Replica rebuilding & replica removal:
            - If there are new replicas rebuilt, those replicas will disappear from the Longhorn system after the restoring. Users need to clean up the replica data manually, or use the data directories of these replicas to export a single replica volume then do data recovery if necessary.
            - If there are some failed/removed replicas and there is at least one replica keeping healthy, those failed/removed replicas will be back after the restoration. Then Longhorn can detect these restored replicas do not contain any data, and copy the latest data from the healthy replica to these replicas.
            - If all replicas are replaced by new replicas after the snapshot, the volume will contain invalid replicas only after the restore. Then users need to export [a single replica volume](../../data-recovery/export-from-replica) for the data recovery.
        -  Engine image upgrade: Users need to redo the upgrade.
        - Expansion: The spec size of the volume will be smaller than the current size. This is like someone requesting volume shrinking but actually Longhorn will refuse to handle it internally. To recover the volume, users need to scale down the workloads and re-do the expansion.

    - **Notice**: If users don't know how to recover a problematic volume, the simplest way is always restoring a new volume from backup.

- If the Longhorn system is upgraded after the snapshot, the new settings and the modifications on the node config will disappear. Users need to re-do the upgrade, then re-modify the settings and node configurations.

- If a node is deleted from Longhorn system after the snapshot, the node won't be back, but the pods on the removed node will be restored. Users need to manually clean up them since these pod may get stuck in state `Terminating`.
- If a node to added to Longhorn system after the snapshot, Longhorn should automatically relaunch all necessary workloads on the node after the cluster restore. But users should be aware that all new replicas or engines on this node will be gone after the restore.


## References
- The related GitHub issue is https://github.com/longhorn/longhorn/issues/2228.
  In this GitHub post, one user is providing a way that restores the Longhorn to a new cluster that doesn't contain any data.
