---
title: Synchronize Backup Volumes Manually
weight: 6
---

After creating a backup, Longhorn creates a backup volume that corresponds to the original volume (on which the backup is based). A backup volume is an object in the backupstore that contains multiple backups of the same volume.

Earlier Longhorn versions poll and update all backup volumes at a [fixed interval](../../../references/settings#backupstore-poll-interval). Longhorn v1.6.2 provides a way for you to manually synchronize backup volumes with the backup target.

> **Important:** You must set up a [backup target](../set-backup-target) and verify that a backup volume was created before attempting to synchronize. Longhorn returns an error when no backup target and backup volume exist.

- Synchronize all backup volumes:
  1. On the Longhorn UI, go to **Backup**.
  1. Click **Sync All Backup Volumes**.

- Synchronize a single backup volume:
  1. On the Longhorn UI, go to **Backup**.
  1. Select a backup volume.
  1. Click **Sync Backup Volume**.

To check if synchronization was successful, click the name of the backup volume on the **Backup** screen.
