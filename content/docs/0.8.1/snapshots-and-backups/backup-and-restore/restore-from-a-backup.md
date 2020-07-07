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

**Result:** The restored volume is available on the **Volume** page.