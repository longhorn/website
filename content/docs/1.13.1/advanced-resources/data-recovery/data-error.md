---
title: Identifying and Recovering from Data Errors
weight: 1
---

If you've encountered an error message like the following:

    'fsck' found errors on device /dev/longhorn/pvc-6288f5ea-5eea-4524-a84f-afa14b85780d but could not correct them.

Then you have a data corruption situation. This section describes how to address the issue.

## Bad Underlying Disk

To determine if the error is caused because one of the underlying disks went bad, follow [these steps](../corrupted-replica) to identify corrupted replicas.

If most of the replicas on the disk went bad, that means the disk is unreliable now and should be replaced.

If only one replica on the disk went bad, it can be a situation known as `bit rot`. In this case, removing the replica is good enough.

## Recover from a Snapshot

If all the replicas are identical, then the volume needs to be recovered using snapshots.

The reason for this is probably that the bad bit was written from the workload the volume attached to.

To revert to a previous snapshot:

1. In maintenance mode, attach the volume to any node.
2. Revert to a snapshot. You should start with the latest one.
3. Detach the volume from maintenance mode to any node.
4. Re-attach the volume to a node you have access to.
5. Mount the volume from `/dev/longhorn/<volume_name>` and check the volume content.
6. If the volume content is still incorrect, repeat from step 1.
7. Once you find a usable snapshot, make a new snapshot from there and start using the volume as normal.

## Recover from Backup

If all of the methods above failed, use a backup to [recover the volume.](../../../snapshots-and-backups/backup-and-restore/restore-from-a-backup)