---
title: "Troubleshooting: Unable to access an NFS backup target"
author: James Lu
draft: false
date: 2022-05-27
categories:
  - "backup"
---

## Applicable versions

All Longhorn versions.

## Prerequisite

Longhorn supports only NFS versions 4.0, 4.1, and 4.2. Users should ensure that both their backup server and client support one of the supported versions.

### How to determine which NFS version is used

* Server side:

Check which versions of NFS are currently enabled.

```bash
  # cat /proc/fs/nfsd/versions
```

* Client side:

What versions the NFS mount is configured to support:

```bash
  # nfsstat -m
```

## Symptom 1

The Backup page pops up with a "No such file or directory" error, for example,

```text
, error exit status 32: vers=4.2: Failed to execute: mount [-t nfs4 -o nfsvers=4.2 -o actimeo=1 192.168.121.170:/opt/nfs-server /var/lib/longhorn-backupstore-mounts/192_168_121_170/opt/nfs-server], output mount.nfs4: mounting 192.168.121.170:/opt/nfs-server failed, reason given by server: No such file or directory
, error exit status 32: Cannot mount using NFSv4
```

### Possible Reason 1

The backup target is not correct or exported directory does not exist on NFS server.

### Solution

Correct the backup target or create the directory on NFS server.

### Possible Reason 2

If the configuration file `/etc/exports` is as the below example:

```text
/opt/nfs-server 192.168.121.0/24(rw,sync,no_subtree_check,crossmnt,fsid=0)
```

For NFSv4, the `fsid=0` or `fsid=root` option means the exported directory is the root of all exported filesystems. The example here is `/opt/nfs-server`.

If users try to use the absolute path of the exported directory to list backups, that mounting error will happen.

### Solution

1. Mount with the absolute path of the exported directory (ex: `/opt/nfs-server`) on the client side **without** the option `fsid=0` or `fsid=root` on the server side.

2. Mount with the path "/" on the client side still **with** the option `fsid=0` or `fsid=root` on the server side.

## Symptom 2

The Backup page pops up with a permission denied error, for example,

```text
error running create backup command: failed to create backup to nfs://192.168.121.170:/opt/nfs-server for volume test-for-backup: rpc error: code = Unknown desc = mkdir /var/lib/backupstore/192_168_121_170/opt/nfs-server/backup/longhorn/backupstore: permission denied" , error exit status 1
```

### Reason

The exported directory is not accessible by non-root users due to the `root_squash` option being used.

### Solution

1. Use the option `no_root_squash` instead of `root_squash` in the exported directory

2. Execute `chmod o+w [exported directory path]` or change the owner of the directory to `nobody`.

## Related information

* Related Longhorn issues:

  - <https://github.com/longhorn/longhorn/issues/3576>
  - <https://github.com/longhorn/longhorn/discussions/3805>

* Linux Man page: exports, nfs.
