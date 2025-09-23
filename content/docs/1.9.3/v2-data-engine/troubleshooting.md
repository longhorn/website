---
title: Troubleshooting
weight: 4
aliases:
- /spdk/troubleshooting.md
---

- [Installation](#installation)
  - ["Package 'linux-modules-extra-x.x.x-x-generic' Has No Installation Candidate" Error During Installation on Debian Machines](#package-linux-modules-extra-xxx-x-generic-has-no-installation-candidate-error-during-installation-on-debian-machines)
- [Disk](#disk)
  - ["Invalid argument" Error in Disk Status After Adding a Block-Type Disk](#invalid-argument-error-in-disk-status-after-adding-a-block-type-disk)

---

## Installation

### "Package 'linux-modules-extra-x.x.x-x-generic' Has No Installation Candidate" Error During Installation on Debian Machines

For Debian machines, if you encounter errors similar to the below when installing Linux kernel extra modules, you need to find an available version in the pkg collection websites like [this](https://pkgs.org/search/?q=linux-modules-extra) rather than directly relying on `uname -r` instead:
```log
apt install -y linux-modules-extra-`uname -r`
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
Package linux-modules-extra-5.15.0-67-generic is not available, but is referred to by another package.
This may mean that the package is missing, has been obsoleted, or
is only available from another source

E: Package 'linux-modules-extra-5.15.0-67-generic' has no installation candidate
```

For example, for Ubuntu 22.04, one valid version is `linux-modules-extra-5.15.0-76-generic`:
```shell
apt update -y
apt install -y linux-modules-extra-5.15.0-76-generic
```

## Disk

### "Invalid argument" Error in Disk Status After Adding a Block-Type Disk

After adding a block-type disk, the disk status displays error messages:
```
Disk disk-1(/dev/nvme1n1) on node dereksu-ubuntu-pool1-bf77ed93-2d2p9 is not ready: 
failed to generate disk config: error: rpc error: code = Internal desc = rpc error: code = Internal 
desc = failed to add block device: failed to create AIO bdev: error sending message, id 10441, 
method bdev_aio_create, params {disk-1 /host/dev/nvme1n1 4096}: {"code": -22,"message": "Invalid argument"}
```

Next, inspect the log message of the instance-manager pod on the same node. If the log reveals the following:
```
[2023-06-29 08:51:53.762597] bdev_aio.c: 762:create_aio_bdev: *WARNING*: Specified block size 4096 does not match auto-detected block size 512
[2023-06-29 08:51:53.762640] bdev_aio.c: 788:create_aio_bdev: *ERROR*: Disk size 100000000000 is not a multiple of block size 4096
```
These messages indicate that the size of your disk is not a multiple of the block size 4096 and is not supported by Longhorn system.

To resolve this issue, you can follow the steps
1. Remove the newly added block-type disk from the node.
2. Partition the block-type disk using the `fdisk` utility and ensure that the partition size is a multiple of the block size 4096.
3. Add the partitioned disk to the Longhorn node.

