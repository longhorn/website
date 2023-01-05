---
title: Trim Filesystem
weight: 4
---

Since v1.4.0, Longhorn supports trimming filesystem inside Longhorn volumes. Trimming will reclaim space wasted by the removed files of the filesystem.

> **Note:**
> - Trying to trim a removed files from a valid snapshot will do nothing but the filesystem will discard this kind of in-memory trimmable file info. Later on if you mark the snapshot as removed and want to retry the trim, you may need to unmount and remount the filesystem so that the filesystem can recollect the trimmable file info.
>
> - If you allow automatically removing snapshots during filesystem trim, please be careful of using mount option `discard`, which will trigger the snapshot removal frequently then interrupt some operations like backup creation.

## Prerequisites

- The Longhorn version must be v1.4.0 or higher.
- There is a trimmable filesystem like EXT4 or XFS inside the Longhorn volume.
- The volume is attached and mounted on a mount point before trimming.
- If a volume is attached before Longhorn v1.4.0, it should be upgraded and reattached after Longhorn upgrade. This requirement applies to the corresponding option update as well.

## Trim the filesystem in a Longhorn volume

There are two ways to do trim for a Longhorn volume: with the Longhorn UI and directly via cmd.

#### Via Longhorn UI

You can directly click volume operation `Trim Filesystem` for attached volumes.

Then Longhorn will **try its best** to figure out the mount point and execute `fstrim <the mount point>`.  If something is wrong or the filesystem does not exist, the UI will return an error.

#### Via cmd

Users need to figure out the mount point of the volume then manually execute `fstrim <the mount point>`.

## Automatically Remove Snapshots During Filesystem Trim

By design each valid snapshot of a Longhorn volume is immutable. Hence Longhorn filesystem trim feature can be applied to **the volume head and the followed continuous removed or system snapshots only**.

#### The Global Setting "Remove Snapshots During Filesystem Trim"

To help reclaim as much space as possible automatically, Longhorn introduces [setting _Remove Snapshots During Filesystem Trim_](../../references/settings/#remove-snapshots-during-filesystem-trim). This allows Longhorn filesystem trim feature to automatically mark the latest snapshot and its ancestors as removed and stops at the snapshot containing multiple children. As a result, Longhorn can reclaim space for as more snapshots as possible.

#### The Volume Spec Field "UnmapMarkSnapChainAsRemoved"

Of course there is a per-volume field `volume.Spec.UnmapMarkSnapChainAsRemoved` would overwrite the global setting mentioned above.

There are 3 options for this volume field: `ignored`, `enabled`, and `disabled`. `ignored` means following the global setting, which is the default value.

You can directly set this field in the StoragaClasses so that the customized value can be applied to all volumes created by the StorageClasses.

## Known Issues & Limitations

### RWX volumes
- Currently, Longhorn **UI** only supports filesystem trimming for RWO volume. It will be enhanced for RWX volume at https://github.com/longhorn/longhorn/issues/5143.

- If you want to trim a RWX volume manually, you can:
    1. Figure out and enter into the share manager pod of the RWX volume, which actually contains the NFS server. The share manager pod is typically named as `share-manager-<volume name>`.
    ```shell
    kubectl -n longhorn-system exec -it <the share manager pod> -- bash
    ```
    2. Figure out the work directory of the NFS server. The work directory is typically like `/export/<volume name>`:
    ```shell
    mount | grep /dev/longhorn/<volume name>
    /dev/longhorn/<volume name> on /export/<volume name> type ext4 (rw,relatime)
    ```
    3. Trim the work directory
    ```shell
    fstrim /export/<volume name>
    ```

### Encrypted volumes
- By default, TRIM commands are not enabled by the device-mapper. You can check [this doc](https://wiki.archlinux.org/title/Dm-crypt/Specialties#Discard/TRIM_support_for_solid_state_drives_(SSD)) for details.

- If you still want to trim an encrypted Longhorn volume, you can:
    1. Enter into the node host the volume is attached to.
    2. Enable flag `discards` for the encrypted volume. The passphrase is recorded in the corresponding secert:
    ```shell
    cryptsetup --allow-discards --persistent refresh <Longhorn volume name>
    ```
    3. Directly use Longhorn UI to trim the volume or execute `fstrim` for **the mount point** of `/dev/mapper/<volume name>` manually.
