---
title: Trim Filesystem
weight: 7
---

Since v1.4.0, Longhorn supports trimming filesystem inside Longhorn volumes. Trimming will reclaim space wasted by the removed files of the filesystem.

> **Note:**
> - Since each valid snapshot is immutable, trimming removed files from a valid snapshot will do nothing. However, the
    filesystem will remember that it has already trimmed the associated blocks. Later on, if you mark the snapshot as
    removed and want to retry the trim, you may need to unmount and remount the filesystem first.
>
> - If you allow automatically removing snapshots during filesystem trim, please be careful of using the mount option
    `discard`, which will trigger the snapshot removal frequently and interrupt some operations like backup creation.

## Prerequisites

- The Longhorn version must be v1.4.0 or higher.
- There is a trimmable filesystem like EXT4 or XFS inside the Longhorn volume.
- The volume is attached and mounted on a mount point before trimming.

## Trim the filesystem in a Longhorn volume

You can trim a Longhorn volume using either the Longhorn UI or the `fstrim` command.

### Via Longhorn UI

You can directly click volume operation `Trim Filesystem` for attached volumes.

Then Longhorn will **try its best** to figure out the mount point and execute `fstrim <the mount point>`.  If something is wrong or the filesystem does not exist, the UI will return an error.

### Via shell command

When using `fstrim`, you must identify the mount point of the volume and then run the command `fstrim <the mount point>`.

- RWO volume: The mount point is either a pod of the workload or the node to which the volume was manually attached.
- RWX volume: The mount point is the share manager pod of the volume. The share manager pod contains the NFS server and is typically named `share-manager-<volume name>`.

To trim an RWX volume, perform the following steps:

1. Identify and then open a shell inside the share manager pod of the volume.
    ```
    kubectl -n longhorn-system exec -it <the share manager pod> -- bash
    ```
1. Identify the work directory of the NFS server (for example, `/export/<volume name>`).
    ```
    mount | grep <volume name>
    /dev/longhorn/<volume name> on /export/<volume name> type ext4 (rw,relatime)
    ```
1. Trim the work directory.
    ```
    fstrim /export/<volume name>
    ```

#### Periodically trim the filesystem

You can set up a [RecurringJob](../../../snapshots-and-backups/scheduling-backups-and-snapshots/#set-up-recurring-jobs) to periodically trim the filesystem.

## Automatically Remove Snapshots During Filesystem Trim

By design each valid snapshot of a Longhorn volume is immutable. Hence, the Longhorn filesystem trim feature can be
applied to **the volume head and the preceding continuously removed or system snapshots only**. If most of the actual
space consumed by a volume is associated with valid snapshots, the trim operation will not be very effective.

### The Global Setting "Remove Snapshots During Filesystem Trim"

To help reclaim as much space as possible automatically, Longhorn includes the setting
[_Remove Snapshots During Filesystem Trim_](../../../references/settings/#remove-snapshots-during-filesystem-trim).
This allows the trim feature to automatically mark the latest snapshot and all preceding snapshots
(until there is a fork in the snapshot chain) as removed. As a result, Longhorn can reclaim space for as many snapshots
as possible. However, this setting also causes intentionally created snapshots to be marked as removed (and eventually
purged), so it should be used with caution.

#### The Volume Spec Field "UnmapMarkSnapChainRemoved"

Of course there is a per-volume field `volume.Spec.UnmapMarkSnapChainRemoved` would overwrite the global setting mentioned above.

There are 3 options for this volume field: `ignored`, `enabled`, and `disabled`. `ignored` means followi the global
setting, which is the default value.

You can directly set this field in a StoragaClass so that the customized value can be applied to all volumes created by
the StorageClass.

## Known Issues & Limitations

### Rebuilding volumes

The trim operation cannot be executed successfully against a volume that is actively rebuilding. By design, it unmaps
blocks in the volume head and all the continuously removed snapshots preceding it. However, some of these snapshots may
be actively transferring from one replica to another while rebuilding is ongoing.

Instead of returning an I/O error to the filesystem, Longhorn silently refuses to unmap blocks during a rebuild. The
rebuild may take a long time, and VM workloads in particular respond poorly when repeated attempts to complete a trim
return errors. See https://github.com/longhorn/longhorn/issues/7103 for details.

If a trim operation is started during a rebuild, it will have no effect. Similar to issuing a trim against a valid
snapshot, the filesystem will remember that it has already trimmed the associated blocks. Later on, if you want to
attempt the trim again (to recover space), you may need to unmount and remount the filesystem first.

### Expanding volumes

The trim operation cannot be executed successfully against a volume that is actively expanding. Unlike for rebuilding
volumes, Longhorn returns an I/O error to the filesystem when this occurs. Expansion is generally fast. It is better
to inform the filesystem that the trim failed so that it can be tried again soon (without remounting).

### Encrypted volumes

- By default, TRIM commands are not enabled by the device-mapper. You can check [this doc](https://wiki.archlinux.org/title/Dm-crypt/Specialties#Discard/TRIM_support_for_solid_state_drives_(SSD)) for details.

- If you still want to trim an encrypted Longhorn volume, you can:
    1. Enter into the node host the volume is attached to.
    2. Enable flag `discards` for the encrypted volume. The passphrase is recorded in the corresponding secert:
    ```shell
    cryptsetup --allow-discards --persistent refresh <Longhorn volume name>
    ```
    3. Directly use Longhorn UI to trim the volume or execute `fstrim` for **the mount point** of `/dev/mapper/<volume name>` manually.
