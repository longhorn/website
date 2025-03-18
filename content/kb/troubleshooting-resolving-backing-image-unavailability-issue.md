---
title: "Troubleshooting: Resolving Backing Image Unavailability Issue"
authors:
- "Jack Lin"
draft: false
date: 2025-03-14
versions:
- "all"
categories:
- "longhorn manager"
---

## Applicable versions

All Longhorn versions.


## Symptoms

Volumes using a backing image cannot be attached. Replicas using the same backing image cannot start.

## Root Cause

The issues occur when no available copy of the backing image exists in the cluster. You can verify the cause by checking the backing image Custom Resource (CR). This CR contains the following fields:

- `spec.disks` (in versions earlier than v1.7.0) or `spec.diskFileSpecMap` (in v1.7.0 and later versions): Indicate the disks that should contain a copy of the backing image file.
- `status.diskFileStatusMap`: Shows the state of the backing image file on each disk.

You can also check the disk status in the Longhorn node CR using the following command:
```sh
kubectl get nodes.longhorn.io -n longhorn-system -oyaml
```

Each disk in the cluster has a Backing Image Manager CR and a corresponding pod that monitors and manages all backing image files on that disk. The backing image files are managed as follows:

| Scenario | Action |
| --- | --- |
| A copy of the backing image file is missing or corrupted (because of a checksum mismatch or other factors). The status in `diskFileStatusMap` is `Failed`. | Longhorn attempts to recover by syncing the file from a healthy copy on another disk. |
| All copies of the backing image file are missing or corrupted. | Longhorn is unable to recover the file data because no copies can be used for recovery. |
| The disk or node that stores a backing image is unavailable. | Longhorn is unable to determine the status of the backing image file until the disk or node is back online. If the disk or node never becomes available again, the status of the file remains unknown indefinitely. | 

## Workaround
You must download the file again if no healthy copy of the backing image file exists. Data loss is unlikely because the volume is not deleted.

**Important**: This workaround takes effect only when the source type of the backing image is `download`.

1. Edit the backing image CR.
   ```sh
   kubectl edit lhbi/${BACKINGIMAGENAME} -n longhorn-system
   ```
   Remove all `disks` or `diskFileSpecMap` entries by replacing the value with an empty map (`{}`).
2. Delete the backing image data source CR.
   ```sh
   kubectl delete lhbids -n longhorn-system
   ```
   Longhorn downloads the backing image file to a disk. The file is marked ready and healthy, and is subsequently synced to other disks as necessary.
3. Attach the volumes that use the downloaded backing image.

## Prevent Backing Image Loss

### Versions Earlier than v1.7.0

Longhorn versions earlier than v1.7.0 do not have an automatic eviction mechanism for backing images whenever a node is cordoned and drained for upgrades.

1. Retrieve the UUIDs of the available disks.
  ```sh
  kubectl get nodes.longhorn.io -n longhorn-system -oyaml
  ```
2. Add the disk UUIDs of another node to the `disks` field in the backing image CR.
  ```sh
  kubectl edit lhbi/${BACKINGIMAGENAME} -n longhorn-system
  ```
3. Once copies of the backing image file are available in other disks, remove the file from the node that is being drained. To do this, delete the disk UUIDs of the node in the `disks` field of the backing image CR.
  ```sh
  kubectl edit lhbi/${BACKINGIMAGENAME} -n longhorn-system
  ```
4. Remove the node.
5. If the backing image is actively used by replicas, evict the replicas to another disk or node. Doing this syncs the backing image file to the new location.

### v1.7.0 and Later Versions
Starting from Longhorn v1.7.0, backing image files are automatically evicted to other disks and nodes when the `Eviction Requested` flag is set for a disk or node. Additionally, each backing image has a minimal availability setting, ensuring that Longhorn maintains the backing image file across different disks and nodes to keep it always available in the cluster.

## Related information
- Related Longhorn issue for backing image improvement: https://github.com/longhorn/longhorn/issues/2856