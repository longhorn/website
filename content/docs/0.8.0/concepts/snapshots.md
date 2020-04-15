---
title: Snapshots
weight: 14
---

A **snapshot** in Longhorn is the state of a volume at a given time that is stored in the same location as the volume data on the host's physical disk. Snapshots are created instantly in Longhorn.

Users can revert to any previous snapshot using the Longhorn UI. Since Longhorn is a distributed block storage system, make sure that the Longhorn volume is umounted from the host when reverting to any previous snapshot. Otherwise, Longhorn will confuse the node filesystem and cause filesystem corruption.

## Note about the block level snapshot

Longhorn is a `crash-consistent` block storage solution.

It's normal for the OS to keep content in the cache before writing into the block layer. However, it also means if the all the replicas are down, then Longhorn may not contain the immediate change before the shutdown, since the content was kept in the OS level cache and hadn't transfered to Longhorn system yet. It's similar to if your desktop was down due to a power outage, after resuming the power, you may find some weird files in the hard drive.

To force the data being written to the block layer at any given moment, the user can run `sync` command on the node manually, or umount the disk. OS would write the content from the cache to the block layer in either situation.

## Volume size

Longhorn is a thin-provisioned storage system. That means a Longhorn volume will only take the space it needs at the moment. For example, if you allocated a 20GB volume but only use 1GB of it, the actual data size on your disk would be 1GB. You can see the actual data size in the volume details in the UI.

Longhorn volume itself cannot shrink in size if you've removed content from your volume. For example, if you create a volume of 20GB, used 10GB, then removed the content of 9GB, the actual size on the disk would still be 10GB instead of 1GB. It's because currently Longhorn operates on the block level, not filesystem level, so it doesn't know if user has removed the content or not. That information is mostly kept in the filesystem level.

### Space taken by the snapshots

Some users may found that a Longhorn volume's actual size is bigger than it's nominal size. That's because in Longhorn, snapshot stored the history data of the volume, which will also take some spaces, depends on how much data was in the snapshot. The snapshot feature enables user to revert back to a certain point in history, create a backup to secondary storage. The snapshot feature is also a part Longhorn on rebuilding process. Everytime when Longhorn detects a replica is down, it will take a (system) snapshot automatically and start rebuilding on another node.

To reduce the space taken by snapshots, user can schedule a recurring snapshot or backup with a retain number, which will 
automatically create a new snapshot/backup on schedule, then clean up for any excessive snapshots/backups.

User can also delete unwanted snapshot manually through UI. Any system generated snapshots will be automatically marked for deletion if the deletion of any snapshot was triggered.

#### The latest snapshot

In Longhorn, the latest snapshot cannot be deleted. It because whenever a snapshot is deleted, Longhorn will coalesce it content with the next snapshot, makes sure the next and later snapshot will still have the correct content. But Longhorn cannot do that for the latest snapshot since there is no next snapshot to it. The next "snapshot" of the latest snapshot is the live volume(`volume-head`), which is being read/written by the user at the moment, so the coalescing process cannot happen. Instead, the latest snapshot will be marked as `removed`, and it will be cleaned up next time when possible.

If the users want to clean up the latest snapshot, they can create a new snapshot, then remove the previous "latest" snapshot. 