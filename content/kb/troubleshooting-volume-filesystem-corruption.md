---
title: "Troubleshooting: Pod stuck in creating state when Longhorn volumes filesystem is corrupted"
author: Chin-Ya Huang and Derek Su
draft: false
date: 2021-08-19
categories:
  - "volume"
---

## Applicable versions
All Longhorn versions.

## Symptoms

The pod using a longhorn volume with an `ext4` filesystem stays in container `Creating` with errors in the log.
```
  Warning  FailedMount             30s (x7 over 63s)  kubelet                  MountVolume.SetUp failed for volume "pvc-bb8582d5-eaa4-479a-b4bf-328d1ef1785d" : rpc error: code = Internal desc = 'fsck' found errors on device /dev/longhorn/pvc-bb8582d5-eaa4-479a-b4bf-328d1ef1785d but could not correct them: fsck from util-linux 2.31.1
ext2fs_check_if_mount: Can't check if filesystem is mounted due to missing mtab file while determining whether /dev/longhorn/pvc-bb8582d5-eaa4-479a-b4bf-328d1ef1785d is mounted.
/dev/longhorn/pvc-bb8582d5-eaa4-479a-b4bf-328d1ef1785d contains a file system with errors, check forced.
/dev/longhorn/pvc-bb8582d5-eaa4-479a-b4bf-328d1ef1785d: Inodes that were part of a corrupted orphan linked list found.  

/dev/longhorn/pvc-bb8582d5-eaa4-479a-b4bf-328d1ef1785d: UNEXPECTED INCONSISTENCY; RUN fsck MANUALLY.
  (i.e., without -a or -p options)
```

## Reason

Longhorn cannot remount the volume when the Longhorn volume has a corrupted filesystem. The workload then fails to restart as a result of this.

Longhorn cannot fix this automatically. You will need to resolve this manually when this happens.

#### Solution
1. Look for indications:
  - Check if the volume is in an error state from the  Longhorn UI.
  - Check Longhorn manager pods log for system corruption error messages.
  > If the volume is not in an error state then the file system inside Longhorn volume may be corrupted by an external reason.
2. Scale down the workload.
3. Attach the volume to any node from the UI.

> **Warning**
>  When a file system check tool fixes errors, it modifies the filesystem metadata and brings the filesystem to a consistent state. However, an incorrect fix might lead to unexpected data loss or more serious filesystem corruption. To mitigate the potential risk, we highly suggest that users take a snapshot or a backup of the corrupted filesystem before attempting any fix. In case of an accident, users can recover the volume.

4. SSH into the node.
5. Find the block device corresponding to the Longhorn volume under `/dev/longhorn/<volume-name>`.
6. Use a filesystem check tool to repair the filesystem, for example,
   - Fix an `ext4` filesystem using [`fsck`](https://man7.org/linux/man-pages/man8/fsck.8.html).
   - Fix an `xfs` filesystem using [`xfs_repair`](https://man7.org/linux/man-pages/man8/xfs_repair.8.html).
7. Detach the volume from the UI.
8. Scale up the workload.

