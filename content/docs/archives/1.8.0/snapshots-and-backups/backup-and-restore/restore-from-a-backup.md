---
title: Restore from a Backup
weight: 3
---

Longhorn can easily restore backups to a volume. 

For more information on how backups work, refer to the [concepts](../../../concepts/#3-backups-and-secondary-storage) section.

When you restore a backup, it creates a volume of the same name by default. If a volume with the same name as the backup already exists, the backup will not be restored.

To restore a backup,

1. Navigate to the **Backup.** menu
2. Select the backup(s) you wish to restore and click **Restore Latest Backup.**
3. In the **Name** field, select the volume you wish to restore.
4. Click **OK.**

You can then create the PV/PVC from the volume after restoring a volume from a backup. Here you can specify the `storageClassName` or leave it empty to use the `storageClassName` inherited from the PVC of the backup volume. The `StorageClass` should be already in the cluster to prevent any further issue.

**Result:** The restored volume is available on the **Volume** page.