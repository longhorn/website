---
title: Backup Longhorn System
weight: 1
---

- [Longhorn System Backup Bundle](#longhorn-system-backup-bundle)
- [Create Longhorn System Backup](#create-longhorn-system-backup)
  - [Prerequisite](#prerequisite)
  - [Configuration](#configuration)
    - [Volume Backup Policy](#volume-backup-policy)
  - [Single Execution](#single-execution)
    - [Create a System Backup Using the Longhorn UI](#create-a-system-backup-using-the-longhorn-ui)
    - [Create a System Backup Using `kubectl`](#create-a-system-backup-using-kubectl)
  - [Recurring Job](#recurring-job)
    - [Create a Recurring Backup Job Using the Longhorn UI](#create-a-recurring-backup-job-using-the-longhorn-ui)
    - [Create a Recurring Backup Job Using `kubectl`](#create-a-recurring-backup-job-using-kubectl)
- [Delete Longhorn System Backup](#delete-longhorn-system-backup)
  - [Delete a System Backup Using the Longhorn UI](#delete-a-system-backup-using-the-longhorn-ui)
  - [Delete a System Backup Using `kubectl`](#delete-a-system-backup-using-kubectl)
- [History](#history)

## Longhorn System Backup Bundle

Longhorn system backup creates a resource bundle and uploads it to the remote backup target.

It includes below resources associating with the Longhorn system:
- BackingImages
- ClusterRoles
- ClusterRoleBindings
- ConfigMaps
- CustomResourceDefinitions
- DaemonSets
- Deployments
- EngineImages
- PersistentVolumes
- PersistentVolumeClaims
- RecurringJobs
- Roles
- RoleBindings
- Settings
- Services
- ServiceAccounts
- StorageClasses
- Volumes

> **Note:**
>
> - The default backup target (`default`) is always used to store system backups.
> - The Longhorn system backup bundle only includes resources operated by Longhorn.
> - Longhorn does not back up the `Nodes` resource. The Longhorn Manager on the target cluster is responsible for creating its own Longhorn `Node` custom resources.
> - Longhorn is unable to back up V2 Data Engine backing images.
>
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
 - `if-not-present`: Longhorn will create a backup for volumes that either lack an existing backup or have an outdated latest backup.
 - `always`: Longhorn will create a backup for all volumes, regardless of their existing backups.
 - `disabled`: Longhorn will not create any backups for volumes.

### Single Execution

#### Create a System Backup Using the Longhorn UI

1. Go to the `System Backups` page in the `Backup and Restore` drop-down list.

1. Click `Create` under `System Backup`.

1. Give a `Name` for the system backup.

1. Select a `Volume Backup Policy` for the system backup.

1. The system backup will be ready to use when the state changes to `Ready`.

#### Create a System Backup Using `kubectl`

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

### Recurring Job

#### Create a Recurring Backup Job Using the Longhorn UI

1. Go to the `Recurring Jobs` page.

1. Click on `Create Recurring Job`.

1. Configure the following settings:
   - **Name**: Specify a name for the recurring job.
   - **Task**: Select **System Backup**.
   - **Retain**: Specify the number of system backups that Longhorn must retain.
   - **Cron**: Specify the cron expression (a string consisting of fields separated by whitespace characters) that defines the schedule properties.
   - **Parameters**: Select **volume-backup-policy**.

1. Click **OK**.

Longhorn creates system backups according to the schedule defined in the **Cron** field.

#### Create a Recurring Backup Job Using `kubectl`

Run `kubectl create` to create a Longhorn `RecurringJob` custom resource with the task `system-backup`.

Example:
   ```yaml
   apiVersion: longhorn.io/v1beta2
   kind: RecurringJob
   metadata:
     name: demo
     namespace: longhorn-system
   spec:
     task: system-backup
     cron: '* * * * *'
     retain: 1
     parameters:
       volume-backup-policy: if-not-present
   ```

Longhorn creates system backup according to the schedule defined in the `cron` field.

## Delete Longhorn System Backup

You can delete the Longhorn system backup in the remote backup target using the Longhorn UI. Or with the `kubectl` command.

### Delete a System Backup Using the Longhorn UI

1. Go to the `System Backup` page in the `Setting` drop-down list.

1. Delete a single system backup in the `Operation` drop-down menu next to the system backup. Or delete in batch with the `Delete` button.

   > **Note:** Deleting the system backup will also make a deletion in the backup store.

### Delete a System Backup Using `kubectl`

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
