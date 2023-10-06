---
title: "Troubleshooting: fstrim doesn't work on old kernel"
author: Phan Le
draft: false
date: 2023-10-06
catelogies:
  - "trim"
---

## Applicable versions

* Longhorn version >= `v1.4.0`
* Node kernel version <= `v4.12`

## Symptoms

When running filesystem trim (either by Longhorn UI or manually by `fstrim` command on the host), it hits the error similar to:

```
unable to trim filesystem for volume pvc-e381424a-4866-447a-a75c-3096036f7846: cannot find volume pvc-e381424a-4866-447a-a75c-3096036f7846 mount info on host: failed to execute: nsenter [--mount=/host/proc/20357/ns/mnt --net=/host/proc/20357/ns/net fstrim /var/lib/kubelet/plugins/kubernetes.io/csi/driver.longhorn.io/d2df1133f3440486ddec39370380eeed7a3c71499981d63fc80e43c7ca9f4c9e/globalmount], output , stderr fstrim: /var/lib/kubelet/plugins/kubernetes.io/csi/driver.longhorn.io/d2df1133f3440486ddec39370380eeed7a3c71499981d63fc80e43c7ca9f4c9e/globalmount: FITRIM ioctl failed: Input/output error\n: exit status 255
```
or
```
unable to trim filesystem for volume pvc-e381424a-4866-447a-a75c-3096036f7846: cannot find volume pvc-e381424a-4866-447a-a75c-3096036f7846 mount info on host: failed to execute: nsenter [--mount=/host/proc/20357/ns/mnt --net=/host/proc/20357/ns/net fstrim /var/lib/kubelet/plugins/kubernetes.io/csi/driver.longhorn.io/d2df1133f3440486ddec39370380eeed7a3c71499981d63fc80e43c7ca9f4c9e/globalmount], output , stderr fstrim: /var/lib/kubelet/plugins/kubernetes.io/csi/driver.longhorn.io/d2df1133f3440486ddec39370380eeed7a3c71499981d63fc80e43c7ca9f4c9e/globalmount: the discard operation is not supported : exit status 1
```

## Details

This is caused by a problem in old kernel SCSI driver which sets the wrong provisioning mode for the SCSI device that advertised
both UNMAP and WRITE SAME capability as detailed in this kernel patch https://github.com/torvalds/linux/commit/bcd069bb250acf6088b60d189ab3ec3ae8dd11a5

### Troubleshooting steps

#### Case 1: Volume is using old engine image or running in the old instance manager pod
1. Double-check the engine image of the volume is >= `v1.4.0` in the volume detail page in Longhorn UI. Only engine
image >= `v1.4.0` supports filesystem trim feature.
1. If the volume's engine's image was recently live upgraded from a version < `v1.4.0` to >= `v1.4.0`, make sure that the
volume is detached/reattached first to activate the trim feature in Longhorn volume. You can do this by manually scale
down and up the workload deployment that is using the volume. See more details at https://longhorn.io/docs/1.4.0/volumes-and-nodes/trim-filesystem/#prerequisites
1. After the above steps, try to run filesystem trim again to see if the problem still exists. If the problem still exists,
move on to the next case below.

#### Case 2: Old node kernel version
1. Find the node that the volume is currently attached to and ssh into that node
1. Find the major and minor of a Longhorn block device by `ls -l /dev/longhorn/<volume-name>`. For example:
    ```bash
    [root@phan-v147-cloudera-pool1-f1dec634-cm59v ~]# ls -l /dev/longhorn/testvol
    brw-rw----. 1 root root 8, 0 Oct  6 20:24 /dev/longhorn/testvol
    ```
    In this case the major:minor versions is `8:0`
1. Find the corresponding SCSI device's address by `lsscsi -d`. For example,
    ```bash
    [root@phan-v147-cloudera-pool1-f1dec634-cm59v ~]# lsscsi -d
    [3:0:0:0]    storage IET      Controller       0001  -
    [3:0:0:1]    disk    IET      VIRTUAL-DISK     0001  /dev/sda [8:0]
    ```
    In this case, the corresponding corresponding SCSI device's address is `[3:0:0:1]` because it also has major:minor versions as `8:0`
1. Find the provisioning mode of SCSI device by `find /sys/ -name provisioning_mode -exec grep -H . {} + | sort`. For example:
    ```bash
    [root@phan-v147-cloudera-pool1-f1dec634-cm59v ~]# find /sys/ -name provisioning_mode -exec grep -H . {} + | sort
    /sys/devices/platform/host3/session1/target3:0:0/3:0:0:1/scsi_disk/3:0:0:1/provisioning_mode:writesame_16
    ```
    In this case, looks at the device with the address `3:0:0:1`, it has provisioning mode as `writesame_16` (in some cases,
    it can be `disable`) but not the correct value `unmap`
1. Check the kernel version by `uname -r`. If the kernel version is < `v4.12`, you have hit this issue

### Solution

Upgrade the kernel to a recommended version as in the best practice page https://longhorn.io/docs/1.5.1/best-practices/#operating-system.
At the time when writing this article, the recommended kernel version is >= `v5.8`

## Related information

- Related Longhorn issue: https://github.com/longhorn/longhorn/issues/6854
