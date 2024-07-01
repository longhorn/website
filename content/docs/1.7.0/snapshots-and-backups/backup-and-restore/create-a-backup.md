---
title: Create a Backup
weight: 2
---

## Incremental Backup
Backups in Longhorn are objects in an off-cluster backupstore. A backup of a snapshot is copied to the backupstore, and the endpoint to access the backupstore is the backup target. For more information, see [this section.](../../../concepts/#31-how-backups-work)

> **Prerequisite:** A backup target must be set up. For more information, see [Set the BackupTarget](../set-backup-target). If the BackupTarget has not been set, you'll be presented with an error.

### Create an Incremental Backup Using UI
To create a backup,

1. Navigate to the **Volume** menu.
2. Select the volume you wish to back up.
3. Click **Create Backup.**
4. Add any appropriate labels and click OK.

**Result:** The backup is created. To see it, click **Backup** in the top navigation bar.

For information about restoring a volume from a snapshot, see [Restore from a Backup](../restore-from-a-backup).

### Create an Incremental Using YAML Code

1. Obtain the name of the snapshot that you want to back up (from either the Longhorn UI or the CR).
2. Apply the YAML.

Example:

```yaml
apiVersion: longhorn.io/v1beta2
kind: Backup
metadata:
  name: backup-example
  namespace: longhorn-system
spec:
  backupMode: incremental
  snapshotName: snapshot-name-example
  labels:
    app: test
```

## Full Backup

By default, Longhorn backs up only data that was changed since the last backup. This approach, known as *delta backup*, enhances time efficiency and conserves network throughput. However, when a data block in the backupstore becomes corrupted, Longhorn does not replace that data block with a healthy one during subsequent backup operations.

Starting with v1.7.0, Longhorn can perform full backups that upload all data blocks in the volume and overwrite existing data blocks in the backupstore.

### Create a Full Backup Using the Longhorn UI
1. Go to the **Volume** screen.
2. Select the volume that you want to back up.
3. Click **Create Backup**.
4. Add appropriate labels.
5. Select Full Backup.
6. Click **OK**.

### Create a Full Backup Using YAML Code
1. Obtain the name of the snapshot that you want to back up (from either the Longhorn UI or the CR).
2. Apply the YAML.

Example:

```yaml
apiVersion: longhorn.io/v1beta2
kind: Backup
metadata:
  name: backup-example
  namespace: longhorn-system
spec:
  backupMode: full
  snapshotName: snapshot-name-example
  labels:
    app: test
```

## Uploaded Data Size

To facilitate collection of data transfer information for each backup, Longhorn records the information using two metrics in the CR status.

### Newly Uploaded Data Size
`status.newlyUploadDataSize` records the size of data that was uploaded *for the first time* to the backupstore during the latest backup. In other words, it tracks the size of data blocks that did not previously exist in the backupstore.

### Re-Uploaded Data Size
`status.reUploadDataSize` records the size of data that was overwritten during the latest full backup. In other words, it tracks the size of data blocks that previously existed in the backupstore.