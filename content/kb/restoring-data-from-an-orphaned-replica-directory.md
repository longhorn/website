---
title: "Restoring Data from an Orphaned Replica Directory"
authors:
- "Sushant Gaurav"
draft: false
date: 2025-09-02
versions:
- All
categories:
- "Data Recovery"
- "Troubleshooting"
---

## Applicable versions

Longhorn v1.10.x versions.

## Overview

This guide explains how to restore data from a **replica directory** that is no longer being managed by Longhorn. This situation is referred to as **orphaned data** and can occur if the Longhorn system loses track of the replica, or if a volume is accidentally deleted without properly detaching the replica directories.

Although the Longhorn UI no longer manages this replica, the raw volume data remains on the disk. By following the steps below, you can access and recover your data.

## Before you begin

This process involves running commands on the node where the orphaned replica is located. You will need `SSH` access to that node.

Additionally, to avoid potential data corruption, you must verify that the replica is **not in use** by any active processes. Use the `lsof` command to check for any open files within the directory.

For example:

```sh
# lsof /var/lib/longhorn/replicas/pvc-06b4a8a8-b51d-42c6-a8cc-d8c8d6bc65bc-d890efb2/
```

If the command returns a result, do not proceed. If the command returns an empty result, the directory is safe to work with.

## Step-by-step guide

### 1. Identify the orphaned replica directory

Replica directories are stored on the node's disks under the path defined by the `Default Data Path` setting (by default, `/var/lib/longhorn/`).

The directory name follows the pattern `<volume_name>-<8 bytes UUID>`. Use the `ls` command to list the replicas and find the one you need to restore.

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

### 3. Create a temporary volume container

Use the `docker run` command to create a temporary Longhorn container. This container "export" the orphaned replica directory as a block device on the host node.

Replace `<data_path>`, `<volume_name>`, and `<volume_size>` with your specific values.

```sh
docker run -v /dev:/host/dev -v /proc:/host/proc -v <data_path>:/volume --privileged longhornio/longhorn-engine:<longhorn_engine_version> launch-simple-longhorn <volume_name> <volume_size>
```

For example, using the values from the previous steps:

```sh
docker run -v /dev:/host/dev -v /proc:/host/proc -v /var/lib/longhorn/replicas/pvc-06b4a8a8-b51d-42c6-a8cc-d8c8d6bc65bc-d890efb2:/volume --privileged longhornio/longhorn-engine:v1.6.2 launch-simple-longhorn pvc-06b4a8a8-b51d-42c6-a8cc-d8c8d6bc65bc 1073741824
```

After running this command, a block device will be created at `/dev/longhorn/<volume_name>`, such as `/dev/longhorn/pvc-06b4a8a8-b51d-42c6-a8cc-d8c8d6bc65bc`.

### 4. Access and restore your data

You can now mount the new block device to access your files. It is recommended to mount the volume as **read-only** to prevent any accidental changes to the data.

```sh
# mount -o ro /dev/longhorn/pvc-06b4a8a8-b51d-42c6-a8cc-d8c8d6bc65bc /mnt/recovered-data
```

Once mounted, you can copy the data to a new location or a new Longhorn volume.

### 5. Clean up

After you have restored your data, stop the temporary container you created in Step 3.

First, find the container ID:

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
