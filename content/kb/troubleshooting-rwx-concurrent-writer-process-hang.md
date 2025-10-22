---
title: "Troubleshooting: Concurrent I/O Stuck On A RWX Volume"
authors:
  - "Raphanus Lo"
draft: false
date: 2025-10-22
versions:
  - v1.1.0 and later
categories:
  - "RWX volume"
---

## Applicable versions

- v1.1.0 and later

## Symptom

When two or more workload processes on the same node concurrently write to the same file on a ReadWriteMany (RWX) volume, after a few minutes some of the writer processes (PID 123315 in this example) enter uninterruptible sleep (D state) indefinitely and stop making progress. The blocked syscall is typically in the `open`/`open_and_get_state` path within the kernel NFSv4 client, and the kernel stack shows NFSv4 state/open–related functions such as `nfs_set_open_stateid_locked`, `update_open_stateid`, `_nfs4_open_and_get_state`, and `nfs4_file_open`. From the host node's perspective, the writers appear as:

```text
root@testing-jiras-pool1-rm5mw-9dx82:~# ps aux | grep echo
root       16505  0.0  0.0   4276  3328 ?        Ss   Sep24   0:00 /bin/bash -c diff /usr/local/bin/longhorn /data/longhorn > /dev/null 2>&1; if [ $? -ne 0 ]; then cp -p /usr/local/bin/longhorn /data/ && echo installed; fi && trap 'rm /data/longhorn* && echo cleaned up' EXIT && sleep infinity
root      123312  0.1  0.0   4508  1536 pts/0    Ss+  Sep24   1:00 /bin/sh -c sleep 10; touch /data/index.html; while true; do echo "$(date) $(hostname)" >> /data/index.html; sleep 1; done;
root      123315  0.0  0.0   4508  1536 pts/0    Ds+  Sep24   0:12 /bin/sh -c sleep 10; touch /data/index.html; while true; do echo "$(date) $(hostname)" >> /data/index.html; sleep 1; done;
root     1934740  0.0  0.0   7076  2048 pts/0    S+   06:58   0:00 grep --color=auto echo
```

Inspecting the kernel stack for the stuck PID (`123315`) confirms it is blocked inside NFSv4 open/state handling:

```text
root@testing-jiras-pool1-rm5mw-9dx82:~# cat /proc/123315/stack
[<0>] nfs_set_open_stateid_locked+0x100/0x380 [nfsv4]
[<0>] update_open_stateid+0xa0/0x2b0 [nfsv4]
[<0>] _nfs4_opendata_to_nfs4_state+0x11b/0x220 [nfsv4]
[<0>] _nfs4_open_and_get_state+0x102/0x3d0 [nfsv4]
[<0>] _nfs4_do_open.isra.0+0x167/0x5b0 [nfsv4]
[<0>] nfs4_do_open+0xcb/0x200 [nfsv4]
[<0>] nfs4_atomic_open+0xfe/0x110 [nfsv4]
[<0>] nfs4_file_open+0x172/0x2d0 [nfsv4]
[<0>] do_dentry_open+0x220/0x570
[<0>] vfs_open+0x33/0x50
[<0>] do_open+0x2ed/0x470
[<0>] path_openat+0x135/0x2d0
[<0>] do_filp_open+0xaf/0x170
[<0>] do_sys_openat2+0xb3/0xe0
[<0>] __x64_sys_open+0x57/0xa0
[<0>] x64_sys_call+0x1ca4/0x25a0
[<0>] do_syscall_64+0x7f/0x180
[<0>] entry_SYSCALL_64_after_hwframe+0x78/0x80
```

The NFS mount in this environment was using **NFSv4.1** and showed the following status. Similar hangs have been observed with NFSv4.2.

```text
root@testing-jiras-pool1-rm5mw-9dx82:~# nfsstat --mount
/var/lib/kubelet/plugins/kubernetes.io/csi/driver.longhorn.io/e42532d3c9e30f730ab0ce51f5edf6670b432b7d45ca2c3a4471e55f7761daee/globalmount from 10.43.58.194:/pvc-d09ebc96-88c0-44c1-9e0e-ce9f76f83f4e
 Flags: rw,relatime,vers=4.1,rsize=1048576,wsize=1048576,namlen=255,softerr,softreval,noresvport,proto=tcp,timeo=600,retrans=5,sec=sys,clientaddr=10.136.183.157,local_lock=none,addr=10.43.58.194

/var/lib/kubelet/pods/3f1020f3-65f8-42a9-87f4-cce97878c593/volumes/kubernetes.io~csi/pvc-d09ebc96-88c0-44c1-9e0e-ce9f76f83f4e/mount from 10.43.58.194:/pvc-d09ebc96-88c0-44c1-9e0e-ce9f76f83f4e
 Flags: rw,relatime,vers=4.1,rsize=1048576,wsize=1048576,namlen=255,softerr,softreval,noresvport,proto=tcp,timeo=600,retrans=5,sec=sys,clientaddr=10.136.183.157,local_lock=none,addr=10.43.58.194

/var/lib/kubelet/pods/0710e6fe-c0df-437b-87cd-315d30d00d0c/volumes/kubernetes.io~csi/pvc-d09ebc96-88c0-44c1-9e0e-ce9f76f83f4e/mount from 10.43.58.194:/pvc-d09ebc96-88c0-44c1-9e0e-ce9f76f83f4e
 Flags: rw,relatime,vers=4.1,rsize=1048576,wsize=1048576,namlen=255,softerr,softreval,noresvport,proto=tcp,timeo=600,retrans=5,sec=sys,clientaddr=10.136.183.157,local_lock=none,addr=10.43.58.194
```

Symptoms summary (mount may report `vers=4.1` or `vers=4.2`):

- `ps aux` shows one writer process marked with `D` (uninterruptible sleep).
- `cat /proc/<pid>/stack` shows NFSv4 client functions involved in open/state handling.
- Other writing processes can still update the file in the volume without becoming stuck. The stuck process may resume after the other healthy writer process stops.

### How to identify the issue (diagnosis steps)

1. **Confirm the Stuck Process**: On the node, periodically check the process state with `ps aux | grep <writer-command-or-binary>` to confirm if any process stuck in stuck in the `D` state for an extended period.
2. **Check NFS Mount Options**: Use `nfsstat --mount` and `mount | grep nfs` to determine if the mount uses v4.1/v4.2, and check relevant flags like `soft`/`hard`, `timeo`, and `retrans`.
3. **Correlate Behavior**: If killing the other writer process unblocks the stuck process, this strongly indicates a concurrency-related state interaction issue.

## Root cause

The hang is likely caused by an interaction between NFSv4 state/locking mechanisms and concurrent open/write operations targeting the same file. NFSv4 introduces server-managed state (stateids, delegations, open/lock state). The kernel client code manages transitions between client-side and server-side state. Under certain workloads, the NFS client or server can stall waiting for the other side's state transition, causing the system call to block indefinitely in the kernel (uninterruptible sleep).

In summary: This is likely a bug or race condition in the NFSv4 state handling (client or server side) triggered by concurrent file access patterns. The issue has been seen with both NFSv4.1 and NFSv4.2. In environments where this hang occurs, downgrading the client mount to NFSv4.0 (e.g., by setting `nfsvers=4.0`) has served as a successful workaround.

## Mitigation

Explicitly configure the client mount to use NFS version 4.0 for the `vers` setting. NFS v4.0 support is available starting with Longhorn v1.11.0. You can enforce the NFS protocol version by customizing the `nfsOption` in your StorageClass, ensuring that `vers` (within `nfsOptions`) is explicitly set to `"4.0"`.

```yaml
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: longhorn-rwx-nfs4.0
provisioner: driver.longhorn.io
allowVolumeExpansion: true
reclaimPolicy: Delete
volumeBindingMode: Immediate
parameters:
  numberOfReplicas: "1"
  staleReplicaTimeout: "2880"
  fromBackup: ""
  fsType: "ext4"
  nfsOptions: "vers=4.0,noresvport,softerr,timeo=600,retrans=5"
```

## References

- [Upstream discussion/example](https://github.com/nfs-ganesha/nfs-ganesha/issues/1327).
- [Longhorn issue where the problem was observed](https://github.com/longhorn/longhorn/issues/11907).
