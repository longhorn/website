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
When the backing image is unavailable in a Longhorn cluster, the following issues occur:
- The volume using the backing image cannot be attached.
- The replica using the backing image cannot start.

## Root Cause
The root cause of this issue is that there is no available copy of the backing image in the cluster. This can be verified by checking the backing image Custom Resource (CR) in Kubernetes. The backing image CR contains:
- `disks` (before v1.7.0) or `diskFileSpecMap` (after v1.7.0) in the spec, indicating which disks should store the backing image file.
- `diskFileStatusMap` in the status, showing the state of the backing image file on each disk.

You can check the disk status in the Longhorn node CR using:
```sh
kubectl get nodes.longhorn.io -n longhorn-system -oyaml
```
Each disk in the cluster has a Backing Image Manager CR and a corresponding pod that monitors and manages all backing image files on that disk.

If a backing image file is missing or corrupted (e.g., checksum mismatch), its status in `diskFileStatusMap` will be marked as failed. Longhorn attempts to recover by syncing the file from a healthy copy on another disk. However, if all copies are missing or corrupted, Longhorn will have no available file to recover from, making the backing image unavailable. Additionally, if the disk or node storing a backing image is unavailable, its file status will be unknown until the disk or node is back online. If the disk or node never comes back, the file remains in an unknown state forever.

## Workaround
If no healthy backing image file exists, the only way to restore it is to trigger a re-download. Follow these steps:
1. Detach all the volumes using the backing image. There is no risk of data loss since the volume does not need to be deleted.
2. Edit the backing image CR:
   ```sh
   kubectl edit lhbi/${BACKINGIMAGENAME} -n longhorn-system
   ```
   Remove all `disks` or `diskFileSpecMap` entries by replacing the value with an empty map (`{}`).
3. Delete the backing image data source CR:
   ```sh
   kubectl delete lhbids -n longhorn-system
   ```
   Longhorn will then re-download the backing image file to a disk, making it ready and healthy again. The file will subsequently be synced to other disks as needed.
4. You can try attach the volumes using the backing images again.

## How to Prevent Backing Image Loss
### Before v1.7.0
Before Longhorn v1.7.0, there was no automatic eviction mechanism for backing images when cordoning and draining a node for upgrades. To prevent loss:
- Retrieve the available disks and their UUIDs:
  ```sh
  kubectl get nodes.longhorn.io -n longhorn-system -oyaml
  ```
- Manually add the disk UUIDs of another node to the `disks` field in the backing image CR:
  ```sh
  kubectl edit lhbi/${BACKINGIMAGENAME} -n longhorn-system
  ```
- When the backing image file is ready in other disks, then you can clean up backing iamge file from the draining node by manually deleting the disk UUIDs of the node in the `disks` field in the backing image CR before removing the node:
  ```sh
  kubectl edit lhbi/${BACKINGIMAGENAME} -n longhorn-system
  ```

- If the backing image is actively used by replicas, evicting the replicas to another disk or node will also sync the backing image file to the new location.

### After v1.7.0
Starting from Longhorn v1.7.0, backing image files are automatically evicted to other disks and nodes when the `Eviction Requested` flag is set for a disk or node. Additionally, each backing image has a minimal availability setting, ensuring that Longhorn maintains the backing image file across different disks and nodes to keep it always available in the cluster.

