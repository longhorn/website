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

## Solution

### For most Linux distribution versions

1. Search for error indicators:
   - Check if the volume is in an error state from the Longhorn UI.
   - Check Longhorn manager pods log for system corruption error messages.
   - If the volume is not in an error state then the file system inside Longhorn volume may be corrupted by an external
     reason.
2. Scale down the workload.
3. Attach the volume to any node from the UI.

> **Warning**
> When a file system check tool fixes errors, it modifies the filesystem metadata and brings the filesystem to a
  consistent state. However, an incorrect fix might lead to unexpected data loss or more serious filesystem corruption.
  To mitigate the potential risk, we highly suggest that users take a snapshot or a backup of the corrupted filesystem
  before attempting any fix. In case of an accident, users can recover the volume.

4. SSH into the node.
5. Find the block device corresponding to the Longhorn volume under `/dev/longhorn/<volume-name>`.
6. Use a filesystem check tool to repair the filesystem. For example:
   - Fix an `ext4` filesystem using [`fsck`](https://man7.org/linux/man-pages/man8/fsck.8.html).
   - Fix an `xfs` filesystem using [`xfs_repair`](https://man7.org/linux/man-pages/man8/xfs_repair.8.html).
7. On the Longhorn UI, detach the volume.
8. Scale up the workload.

### For some older Linux distribution versions and Longhorn volumes with ext4 filesystems

In the CSI flow, the Longhorn CSI plugin creates a file system on a new volume using the `make2fs` utility (command:
`mkfs.ext4`) built into its container. The `e2fsck` utility (command: `fsck.ext4`) available in some older Linux
distributions may not support all features this file system is created with, resulting in the following error:

```
-> fsck.ext4 /dev/longhorn/pvc-c7152ef5-55c7-43ce-a35e-dac69d2be591 
e2fsck 1.42.9 (28-Dec-2013)
/dev/longhorn/pvc-c7152ef5-55c7-43ce-a35e-dac69d2be591 has unsupported feature(s): metadata_csum
e2fsck: Get a newer version of e2fsck!
```

If possible, upgrade your `e2fsprogs` (Ext2/3/4 Filesystem Utilities) to a later version. If upgrading is not possible
(for example, you are running CentOS 7 or RHEL 7), you can access attached Longhorn volumes using the updated `e2fsck`
that is built into the `instance-manager` or `instance-manager-e` container.

1. Search for error indicators:
   - Check if the volume is in an error state from the Longhorn UI.
   - Check Longhorn manager pods log for system corruption error messages.
   - If the volume is not in an error state then the file system inside Longhorn volume may be corrupted by an external
     reason.
2. Scale down the workload.
3. Attach the volume to any node from the UI.

> **Warning**
> When a file system check tool fixes errors, it modifies the filesystem metadata and brings the filesystem to a
  consistent state. However, an incorrect fix might lead to unexpected data loss or more serious filesystem corruption.
  To mitigate the potential risk, we highly suggest that users take a snapshot or a backup of the corrupted filesystem
  before attempting any fix. In case of an accident, users can recover the volume.

4. Open a shell inside the `instance-manager` or `instance-manager-e` pod running on the node that the volume is
   attached to:  
   `kubectl exec -it -n longhorn-system instance-manager-<additional-characters> -- bash`
5. Find the block device corresponding to the Longhorn volume under `/dev/longhorn/<volume-name>`.
6. Use a filesystem check tool to repair the filesystem. For example,
   - Fix an `ext4` filesystem using [`fsck`](https://man7.org/linux/man-pages/man8/fsck.8.html).
   - Fix an `xfs` filesystem using [`xfs_repair`](https://man7.org/linux/man-pages/man8/xfs_repair.8.html).
7. On the Longhorn UI, detach the volume.
8. Scale up the workload.

Example output using Longhorn v1.4.0 (with e2fsprogs v1.46.4) and CentOS 7.9 (with e2fsprogs v1.42.9) :

```
-> kl exec -it instance-manager-e-545c3360290f259fb0fe5638303b8f9a bash

instance-manager-e-545c3360290f259fb0fe5638303b8f9a:/ # fsck.ext4 /dev/longhorn/pvc-c7152ef5-55c7-43ce-a35e-dac69d2be591 
e2fsck 1.46.4 (18-Aug-2021)
/dev/longhorn/pvc-c7152ef5-55c7-43ce-a35e-dac69d2be591: clean, 11/131072 files, 26156/524288 blocks
```
