---
title: "Restoring Data from an Orphaned Replica Directory"
authors:
- "Sushant Gaurav"
draft: false
date: 2025-11-28
versions:
- All
categories:
- "Data Recovery"
- "Troubleshooting"
---

## Applicable versions

All Longhorn versions.

## Overview

This guide explains how to restore data from a **replica directory** that is no longer being managed by Longhorn. This situation is referred to as **orphaned data** and can occur if the Longhorn system loses track of the replica, or if a volume is accidentally deleted without properly detaching the replica directories.

Although the Longhorn no longer manages this replica, the raw volume data remains on the disk. By following the steps below, you can access and recover your data.

## Before you begin

This process involves running commands on the node where the orphaned replica is located. You will need `SSH` access to that node.

To avoid potential data corruption, you must verify that the replica is not in use by Longhorn or any other active processes. For example, you can use commands such as `lsof` or `fuser` to check whether any processes are accessing files within the replica directory.

## Step-by-step guide

### 1. Identify the orphaned replica directory

Longhorn replica directories are stored under the storage paths configured in the Longhorn `Node` CRs.

The directory name follows the pattern `<volume_name>-<8 bytes random string>`. Use the `ls` command to list the replica directories and find the one you need to restore.

For example:

```sh
# ls /var/lib/longhorn/replicas/
pvc-06b4a8a8-b51d-42c6-a8cc-d8c8d6bc65bc-d890efb2
pvc-71a266e0-5db5-44e5-a2a3-e5471b007cc9-fe160a2c
```

### 2. Get the volume size

Each replica directory contains a `volume.meta` file that stores the volume's size. You need this value for the next step.

```sh
# cat /var/lib/longhorn/replicas/pvc-06b4a8a8-b51d-42c6-a8cc-d8c8d6bc65bc-d890efb2/volume.meta
{"Size":1073741824,"Head":"volume-head-000.img","Dirty":true,"Rebuilding":false,"Parent":"","SectorSize":512,"BackingFileName":""}
```

In this example, the volume size is `1073741824` bytes (1 GiB).

### 3. Export a volume from the single replica directory and access the data

To expose the replica directory as a block device, see the detailed steps in [Exporting a Volume from a Single Replica](https://longhorn.io/docs/v<current-version>/advanced-resources/data-recovery/export-from-replica/).

Then, a block device will appear at:

```
/dev/longhorn/<volume_name>
```

Mount the device **read-only** to access the data:

```sh
mount -o ro /dev/longhorn/<volume_name> /mnt/recovered-data
```

Once mounted, you can copy the data to a new location or a new Longhorn volume.

### 4. Clean up

After you have restored your data, stop the temporary container you created in Step 3.

First, unmount the mount point, then find the container ID:

```sh
# docker ps
CONTAINER ID   IMAGE                                     COMMAND                  CREATED          STATUS          PORTS     NAMES
4b9f29881a7b   longhornio/longhorn-engine:v1.6.2         "launch-simple-longh…"   12 minutes ago   Up 12 minutes             peaceful_carson
```

Then, stop the container using its ID:

```sh
# docker stop <container_id>
```

Stopping the container will automatically remove the block device from `/dev/longhorn/`. You can then safely remove the temporary mount directory.
