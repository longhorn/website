---
title: Delete Longhorn Volumes
weight: 1
---
Once you are done utilizing a Longhorn volume for storage, there are a number of ways to delete the volume, depending on how you used the volume.

## Deleting Volumes Through Kubernetes
> **Note:** This method only works if the volume was provisioned by a StorageClass and the PersistentVolume for the Longhorn volume has its Reclaim Policy set to Delete.

You can delete a volume through Kubernetes by deleting the PersistentVolumeClaim that uses the provisioned Longhorn volume. This will cause Kubernetes to clean up the PersistentVolume and then delete the volume in Longhorn.

## Deleting Volumes Through Longhorn
All Longhorn volumes, regardless of how they were created, can be deleted through the Longhorn UI.

To delete a single volume, go to the Volume page in the UI. Under the Operation dropdown, select Delete. You will be prompted with a confirmation before deleting the volume.

To delete multiple volumes at the same time, you can check multiple volumes on the Volume page and select Delete at the top.

> **Note:** If Longhorn detects that a volume is tied to a PersistentVolume or PersistentVolumeClaim, then these resources will also be deleted once you delete the volume. You will be warned in the UI about this before proceeding with deletion. Longhorn will also warn you when deleting an attached volume, since it may be in use.
