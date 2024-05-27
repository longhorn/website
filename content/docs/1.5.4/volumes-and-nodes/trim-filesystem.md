---
title: Trim Filesystem
weight: 4
---

Since v1.4.0, Longhorn supports trimming filesystem inside Longhorn volumes. Trimming will reclaim space wasted by the removed files of the filesystem.

> **Note:**
> - Trimming removed files in snapshots has no effect on the filesystem because valid snapshots are immutable. However,
    the filesystem remembers whenever it has trimmed blocks associated with a snapshot. Because of this, you may need to
    unmount and remount the filesystem before reattempting to trim a snapshot that has been marked as removed.
>
> - If you allow automatic snapshot removal during filesystem trim, use the mount option `discard` with caution.
    `discard` frequently triggers snapshot removal and interrupts operations such as backup creation.

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

You can set up a [RecurringJob](../../snapshots-and-backups/scheduling-backups-and-snapshots/#set-up-recurring-jobs) to periodically trim the filesystem.

## Automatically Remove Snapshots During Filesystem Trim

By design, valid snapshots of Longhorn volumes are immutable so you can only use the filesystem trim feature with the
following:

- Volume head
- Preceding continuous chain of snapshots created by the system or marked as removed

If most of the actual space consumed by a volume is associated with valid snapshots, the trim operation is not very
effective.

### Global Setting: "Remove Snapshots During Filesystem Trim"

If you want Longhorn to automatically reclaim the maximum amount of space, you can enable the setting
[_Remove Snapshots During Filesystem Trim_](../../references/settings/#remove-snapshots-during-filesystem-trim).
When this global setting is enabled, the latest snapshot and the preceding continuous chain of snapshots are
automatically marked as removed, allowing Longhorn to reclaim space for as many snapshots as possible. However, the
setting can cause removal (and eventual purging) of snapshots that you intentionally created.

### The Volume Spec Field "UnmapMarkSnapChainRemoved"

There is a per-volume field `volume.Spec.UnmapMarkSnapChainRemoved` that overwrites the global setting mentioned above.

The options for this volume-specific setting are "disabled", "enabled", and "ignored". When the value is "ignored", the
global setting takes effect.

You can configure this setting in a StorageClass so that the value is applied to all volumes created using that
StorageClass.

## Known Issues & Limitations

### Rebuilding Volumes

By design, Longhorn unmaps blocks in the volume head and in the preceding continuous chain of snapshots marked as
removed. Some of these snapshots may be moved from one replica to another during volume rebuilding, so Longhorn is
unable to trim the filesystem of affected volumes when rebuilding is in progress.

Because rebuilding may take a long time, Longhorn simply does not unmap blocks during a rebuild instead of returning an
I/O error to the filesystem. This behavior benefits VM workloads in particular, which respond poorly when repeated
attempts to complete a trim return errors. See [Issue #7103](https://github.com/longhorn/longhorn/issues/7103) for more
information.

A trim operation that is started during rebuilding has no effect. Future trim operations on the same mounted volume may
also have no effect because the filesystem remembers which blocks it has trimmed. You may need to unmount and remount
the filesystem before attempting to start the trim operation again.

### Expanding Volumes

Longhorn is unable to trim the filesystem during volume expansion. Because expansion is fast, Longhorn returns an I/O
error whenever the issue is encountered. The filesystem recognizes that blocks were not trimmed and can try again
without a remount.

### Encrypted Volumes

- By default, TRIM commands are not enabled by the device-mapper. You can check [this doc](https://wiki.archlinux.org/title/Dm-crypt/Specialties#Discard/TRIM_support_for_solid_state_drives_(SSD)) for details.

- If you still want to trim an encrypted Longhorn volume, you can:
    1. Enter into the node host the volume is attached to.
    2. Enable flag `discards` for the encrypted volume. The passphrase is recorded in the corresponding secret:
    ```shell
    cryptsetup --allow-discards --persistent refresh <Longhorn volume name>
    ```
    3. Directly use Longhorn UI to trim the volume or execute `fstrim` for **the mount point** of `/dev/mapper/<volume name>` manually.
