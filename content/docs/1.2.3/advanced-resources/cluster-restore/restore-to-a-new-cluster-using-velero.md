---
title: Restore to a new cluster using Velero
weight: 4
---

This doc instructs how users can restore workloads with Longhorn system to a new cluster via Velero.

## Assumptions:
- A new cluster means there is **no Longhorn volume data** in it.
- There is a remote backup target holds all Longhorn volume data.
- There is a remote backup server that can store the cluster backups created by Velero.

## Expectation:
- All settings will be restored. But the node & disk configurations won't be applied.
- All workloads using Longhorn volumes will get started after the volumes are restored from the remote backup target.

## Workflow

### Create backup for the old cluster
1. Install Velero into a cluster using Longhorn.
2. Create backups for all Longhorn volumes.
3. Use Velero to create a cluster backup. Here, some Longhorn resources should be excluded from the cluster backup:
    ```bash
    velero backup create lh-cluster --exclude-resources persistentvolumes,persistentvolumeclaims,backuptargets.longhorn.io,backupvolumes.longhorn.io,backups.longhorn.io,nodes.longhorn.io,volumes.longhorn.io,engines.longhorn.io,replicas.longhorn.io,backingimagedatasources.longhorn.io,backingimagemanagers.longhorn.io,backingimages.longhorn.io,sharemanagers.longhorn.io,instancemanagers.longhorn.io,engineimages.longhorn.io
    ```
### Restore Longhorn and workloads to a new cluster
1. Install Velero with the same remote backup sever for the new cluster.
2. Restore the cluster backup. e.g.,
    ```bash
    velero restore create --from-backup lh-cluster
    ```
3. Removing all old instance manager pods and backing image manager pods from namespace `longhorn-system`. These old pods should be created by Longhorn rather than Velero and there should be corresponding CRs for them. The pods are harmless but they would lead to the endless logs printed in longhorn-manager pods. e.g.,:
    ```log
    [longhorn-manager-q6n7x] time="2021-12-20T10:42:49Z" level=warning msg="Can't find instance manager for pod instance-manager-r-1f19ecb0, may be deleted"
    [longhorn-manager-q6n7x] time="2021-12-20T10:42:49Z" level=warning msg="Can't find instance manager for pod instance-manager-e-6c3be222, may be deleted"
    [longhorn-manager-ldlvw] time="2021-12-20T10:42:55Z" level=warning msg="Can't find instance manager for pod instance-manager-e-bbf80f76, may be deleted"
    [longhorn-manager-ldlvw] time="2021-12-20T10:42:55Z" level=warning msg="Can't find instance manager for pod instance-manager-r-3818fdca, may be deleted"
    ```
4. Re-config nodes and disks for the restored Longhorn system if necessary.
5. Re-create backing images if necessary.
6. Restore all Longhorn volumes from the remote backup target.
7. If there are RWX backup volumes, users need to manually update the access mode to `ReadWriteMany` since all restored volumes are mode `ReadWriteOnce` by default.
8. Create PVCs and PVs with previous names for the restored volumes.

Note: We will enhance Longhorn system so that users don't need to apply step3 and step8 in the future.

## References
- The related GitHub issue is https://github.com/longhorn/longhorn/issues/3367
