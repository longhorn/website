---
title: Restore Longhorn System
weight: 2
---

- [What does the Longhorn system restore rollout to the cluster](#longhorn-system-restore-rollouts)
- [What are the limitations](#limitations)
    - [Restore Path](#restore-path)
- [How to restore from Longhorn system backup](#create-longhorn-system-restore)
    - [Prerequisite](#prerequisite)
    - [Using Longhorn UI](#using-longhorn-ui)
    - [Using kubectl command](#using-kubectl-command)
- [How to delete Longhorn system restore](#delete-longhorn-system-restore)
    - [Using Longhorn UI](#using-longhorn-ui-1)
    - [Using kubectl command](#using-kubectl-command-1)
- [How to restart Longhorn System Restore](#restart-longhorn-system-restore)
- [What settings are configurable](#configurable-settings)
- [How to troubleshoot](#troubleshoot)
- [History](#history)

## Longhorn System Restore Rollouts

- Longhorn restores the resource from the [Longhorn System Backup Bundle](../backup-longhorn-system#longhorn-system-backup-bundle).
- Longhorn does not restore existing `Volumes` and their associated `PersistentVolume` and `PersistentVolumeClaim`.
- Longhorn automatically restores a `Volume` from its latest backup.
- To prevent overwriting eligible settings, Longhorn does not restore the `ConfigMap/longhorn-default-setting`.
- Longhorn does not restore [configurable settings](#configurable-settings).

## Limitations
### Restore Path

Longhorn does not support cross-major/minor version system restore except for upgrade failures, ex: 1.4.x -> 1.5.
## Create Longhorn System Restore

You can restore the Longhorn system using Longhorn UI. Or with the `kubectl` command.

### Prerequisite

- A running Longhorn cluster for Longhorn to roll out the resources in the system backup bundle.
- Set up the `Nodes` and disk tags for `StorageClass`.
- Have a Longhorn system backup.

  See [Backup Longhorn System - Create Longhorn System Backup](../backup-longhorn-system#create-longhorn-system-backup) for instructions.
- Have volume `BackingImages` available in the cluster.

  In case of the `BackingImage` absence, Longhorn will skip the restoration for that `Volume` and its `PersistentVolume` and `PersistentVolumeClaim`.
- All existing `Volumes` are detached.

### Using Longhorn UI

1. Go to the `System Backup` page in the `Setting`.
1. Select a system backup to restore.
1. Click `Restore` in the `Operation` drop-down menu.
1. Give a `Name` for the system restore.
1. The system restore starts and show the `Completed` state when done.

## Using `kubectl` Command

1. Find the Longhorn `SystemBackup` to restore.
   ```
   > kubectl -n longhorn-system get systembackup
   NAME     VERSION   STATE   CREATED
   demo     v1.4.0    Ready   2022-11-24T04:23:24Z
   demo-2   v1.4.0    Ready   2022-11-24T05:00:59Z
   ```
1. Execute `kubectl create` to create a Longhorn `SystemRestore` of the `SystemBackup`.
   ```yaml
   apiVersion: longhorn.io/v1beta2
   kind: SystemRestore
   metadata:
     name: restore-demo
     namespace: longhorn-system
   spec:
     systemBackup: demo
   ```
1. The system restore starts.
1. The `SystemRestore` change to state `Completed` when done.
   ```
   > kubectl -n longhorn-system get systemrestore
   NAME           STATE       AGE
   restore-demo   Completed   59s
   ```

## Delete Longhorn System Restore

> **Warning:** Deleting the SystemRestore also deletes the associated job and will abort the remaining resource rollouts. You can [Restart the Longhorn System Restore](#restart-longhorn-system-restore) to roll out the remaining resources.

You can abort or remove a completed Longhorn system restore using Longhorn UI. Or with the `kubectl` command.

### Using Longhorn UI

1. Go to the `System Backup` page in the `Setting`.
1. Delete a single system restore in the `Operation` drop-down menu next to the system restore. Or delete in batch with the `Delete` button.

### Using `kubectl` Command

1. Execute `kubectl delete` to delete a Longhorn `SystemRestore`.
   ```
   > kubectl -n longhorn-system get systemrestore
   NAME           STATE       AGE
   restore-demo   Completed   2m37s
   
   > kubectl -n longhorn-system delete systemrestore/restore-demo
   systemrestore.longhorn.io "restore-demo" deleted
   ```

## Restart Longhorn System Restore

1. [Delete Longhorn System Restore](#delete-longhorn-system-restore) that is in progress.
1. [Create Longhorn System Restore](#create-longhorn-system-restore).

## Configurable Settings

Some settings are excluded as configurable before the Longhorn system restore.
- [Concurrent volume backup restore per node limit](../../../references/settings/#concurrent-volume-backup-restore-per-node-limit)
- [Concurrent replica rebuild per node limit](../../../references/settings/#concurrent-replica-rebuild-per-node-limit)
- [Backup Target](../../../references/settings/#backup-target)
- [Backup Target Credential Secret](../../../references/settings/#backup-target-credential-secret)

## Troubleshoot

### System Restore Hangs

1. Check the longhorn-system-rollout Pod log for any errors.
```
> kubectl -n longhorn-system logs --selector=job-name=longhorn-system-rollout-<SYSTEM-RESTORE-NAME>
```
1. Resolve if the issue is identifiable, ex: remove the problematic restoring resource.
1. [Restart the Longhorn system restore](#restart-longhorn-system-restore).

## History
[Original Feature Request](https://github.com/longhorn/longhorn/issues/1455)

Available since v1.4.0
