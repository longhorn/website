---
title: Restore from a Backup
weight: 3
---

Longhorn can easily restore backups to a volume. 

For more information on how backups work, refer to the [concepts](../../../concepts/#3-backups-and-secondary-storage) section.

When you restore a backup, it creates a volume of the same name by default. If a volume with the same name as the backup already exists, the backup will not be restored.

> **Warning:** Restore backup on XFS filesystem cluster
>
> The restored data can differ from the backup on the XFS file system. This is due to the finding in https://github.com/longhorn/longhorn/issues/2503#issuecomment-828158607.
>
> If your cluster is already on the XFS file system and needs to restore from backup before the upgrade. We suggest restoring to an ext4 filesystem cluster to avoid data loss.

To restore a backup,

1. Navigate to the **Backup.** menu
2. Select the backup(s) you wish to restore and click **Restore Latest Backup.**
3. In the **Name** field, select the volume you wish to restore.
4. Click **OK.**

**Result:** The restored volume is available on the **Volume** page.