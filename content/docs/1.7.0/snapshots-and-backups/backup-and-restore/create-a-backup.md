---
title: Create a Backup
weight: 2
---

## Backup
Backups in Longhorn are objects in an off-cluster backupstore. A backup of a snapshot is copied to the backupstore, and the endpoint to access the backupstore is the backup target. For more information, see [this section.](../../../concepts/#31-how-backups-work)

> **Prerequisite:** A backup target must be set up. For more information, see [Set the BackupTarget](../set-backup-target). If the BackupTarget has not been set, you'll be presented with an error.

### Create a Backup Through UI
To create a backup,

1. Navigate to the **Volume** menu.
2. Select the volume you wish to back up.
3. Click **Create Backup.**
4. Add any appropriate labels and click OK.

**Result:** The backup is created. To see it, click **Backup** in the top navigation bar.

For information on how to restore a volume from a snapshot, refer to [this page.](../restore-from-a-backup)

### Create a Backup Through YAML Code
To create a backup using YAML code,

1. Get the snapshot name you would like to back up. You can get the name from the UI or the CR.
3. Apply the YAML

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

By default, Longhorn performs delta backup on the snapshot, meaning it only backs up data that has been newly updated since the last backup. This approach enhances time efficiency and conserves network throughput. However, in the event of a corrupted data block in the backupstore, Longhorn does not replace it with a healthy one during subsequent backup operations.

Starting with v1.7.0, Longhorn allows users to perform full backup to upload all the data blocks of the volume. Longhorn overrides data block on the backup store if it already exists.

### Create a Full Backup Through UI
To create a full backup,

1. Navigate to the **Volume** menu.
2. Select the volume you wish to back up.
3. Click **Create Backup.**
4. Add any appropriate labels.
5. Check the "Full Backup".
6. Click OK.

### Create a Full Backup Through YAML Code
To create a backup using YAML code,

1. Get the snapshot name you would like to back up. You can get the name from the UI or the CR.
3. Apply the YAML

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

To allow users to collect the data transfer usage of each backup, longhorn records the information in two metrics in the CR status.

### Newly Uploaded Data Size
`status.newlyUploadDataSize` records the size of data that has been newly uploaded to the backupstore during this backup process. In other words, it tracks the size of data blocks that did not previously exist in the backupstore and have been uploaded for the first time in the current backup operation.

### Re-Uploaded Data Size
`status.reUploadDataSize` records the size of data that already exists in the backupstore and is being overwritten during this full backup. In other words, it tracks the size of data blocks that were previously stored in the backupstore and are now being overwritten as part of the current full backup operation.