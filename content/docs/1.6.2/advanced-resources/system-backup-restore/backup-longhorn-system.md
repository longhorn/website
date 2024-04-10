---
title: Backup Longhorn System
weight: 1
---

- [What is in the Longhorn system backup bundle](#longhorn-system-backup-bundle)
- [How to create a Longhorn system backup](#create-longhorn-system-backup)
    - [Prerequisite](#prerequisite)
    - [Configuration](#configuration)
    - [Using Longhorn UI](#using-longhorn-ui)
    - [Using kubectl command](#using-kubectl-command)
- [How to delete Longhorn system backup](#delete-longhorn-system-backup)
    - [Using Longhorn UI](#using-longhorn-ui-1)
    - [Using kubectl command](#using-kubectl-command-1)
- [History](#history)

## Longhorn System Backup Bundle

Longhorn system backup creates a resource bundle and uploads it to the remote backup target.

It includes below resources associating with the Longhorn system:
- ClusterRoles
- ClusterRoleBindings
- ConfigMaps
- CustomResourceDefinitions
- DaemonSets
- Deployments
- EngineImages
- PersistentVolumes
- PersistentVolumeClaims
- PodSecurityPolicies
- RecurringJobs
- Roles
- RoleBindings
- Settings
- Services
- ServiceAccounts
- StorageClasses
- Volumes

> **Warning:** Longhorn does not backup `BackingImages`. We will improve this part in the future. See [Restore Longhorn System - Prerequisite](../restore-longhorn-system/#prerequisite) for restoring volumes created with the backing image.

> **Note:** Longhorn does not backup `Nodes`. The Longhorn manager on the target cluster is responsible for creating its own Longhorn `Node` custom resources.

> **Note:**  Longhorn system backup bundle only includes resources operated by Longhorn.  
> Here is an example of a cluster workload with a bare `Pod` workload. The system backup will collect the `PersistentVolumeClaim`, `PersistentVolume`, and `Volume`. The system backup will exclude the `Pod` during system backup resource collection.

## Create Longhorn System Backup

You can create a Longhorn system backup using the Longhorn UI. Or with the `kubectl` command.

### Prerequisite

- [Set the backup target](../../../snapshots-and-backups/backup-and-restore/set-backup-target). Longhorn saves the system backups to the remote backup store. You will see an error during creation when the backup target is unset.

   > **Note:** Unsetting the backup target clears the existing `SystemBackup` custom resource. Longhorn syncs to the remote backup store after setting the backup target. Another cluster can also sync to the same list of system backups when the backup target is the same.

- Create a backup for all volumes (optional).

  > **Note:** Longhorn system restores volume with the latest backup. We recommend updating the last backup for all volumes. By taking volume backups, you ensure that the data is up-to-date with the system backup. For more information, please refer to the [Configuration - Volume Backup Policy](#volume-backup-policy) section.

### Configuration

#### Volume Backup Policy
The Longhorn system backup offers the following volume backup policies:
 - `if-not-present`: Longhorn will create a backup for volumes that currently lack a backup.
 - `always`: Longhorn will create a backup for all volumes, regardless of their existing backups.
 - `disabled`: Longhorn will not create any backups for volumes.

### Using Longhorn UI

1. Go to the `System Backup` page in the `Setting` drop-down list.
1. Click `Create` under `System Backup`.
1. Give a `Name` for the system backup.
1. Select a `Volume Backup Policy` for the system backup.
1. The system backup will be ready to use when the state changes to `Ready`.

### Using `kubectl` Command

1. Execute `kubectl create` to create a Longhorn `SystemBackup` custom resource.
   ```yaml
   apiVersion: longhorn.io/v1beta2
   kind: SystemBackup
   metadata:
     name: demo
     namespace: longhorn-system
   spec:
     volumeBackupPolicy: if-not-present
   ```
1. The system backup will be ready to use when the state changes to `Ready`.
   ```
   > kubectl -n longhorn-system get systembackup
   NAME   VERSION   STATE   CREATED
   demo   v1.4.0    Ready   2022-11-24T04:23:24Z
   ```

## Delete Longhorn System Backup

You can delete the Longhorn system backup in the remote backup target using the Longhorn UI. Or with the `kubectl` command.

### Using Longhorn UI

1. Go to the `System Backup` page in the `Setting` drop-down list.
1. Delete a single system backup in the `Operation` drop-down menu next to the system backup. Or delete in batch with the `Delete` button.

   > **Note:** Deleting the system backup will also make a deletion in the backup store.

### Using `kubectl` Command

1. Execute `kubectl delete` to delete a Longhorn `SystemBackup` custom resource.
   ```
   > kubectl -n longhorn-system get systembackup
   NAME   VERSION   STATE   CREATED
   demo   v1.4.0    Ready   2022-11-24T04:23:24Z
   
   > kubectl -n longhorn-system delete systembackup/demo
   systembackup.longhorn.io "demo" deleted
   ```

## History
[Original Feature Request](https://github.com/longhorn/longhorn/issues/1455)

Available since v1.4.0