---
title: Set Backing Image for Longhorn Volumes
weight: 4
---

Longhorn natively supports backing images since v1.1.1.


A QCOW2 or RAW image can be set as the backing/base image of a Longhorn volume, which allows Longhorn to be integrated with a VM like [Harvester](https://github.com/rancher/harvester).

## Create and Use a Backing Image

### Via Longhorn UI

#### Create a Volume with a Backing Image

1. Click **Setting > Backing Image** in the Longhorn UI.
2. Click **Create Backing Image** to create a backing image with a unique name and a valid URL.
3. During the volume creation, specify the backing image from the backing image list.
4. Longhorn starts to download the backing image to disks for the replicas when a volume using the backing image is attached to a node.

#### Restore a Volume with a Backing Image

1. Click `Backup` and pick up a backup volume for the restore.
2. As long as the backing image is already set for the backup volume, Longhorn will automatically choose the backing image during the restore.
3. Longhorn allows you to re-specify/override the backing image during the restore.

### Via StorageClass and PVC

1. Set the fields `backingImage` and `backingImageURL` in a Longhorn StorageClass.
2. Create a PVC with the StorageClass. Then the backing image will be created (with the Longhorn volume) if it does not exist.
3. Longhorn starts to download the backing images to disks for the replicas when a volume using the backing image is attached to a node.

A StorageClass example:

```
apiVersion: v1
kind: ConfigMap
metadata:
  name: longhorn-storageclass
  namespace: longhorn-system
data:
  storageclass.yaml: |
    kind: StorageClass
    apiVersion: storage.k8s.io/v1
    metadata:
      name: longhorn
    provisioner: driver.longhorn.io
    allowVolumeExpansion: true
    reclaimPolicy: Delete
    volumeBindingMode: Immediate
    parameters:
      numberOfReplicas: "3"
      staleReplicaTimeout: "2880"
      fromBackup: ""
      backingImage: "bi-test"
      backingImageURL: "https://backing-image-example.s3-region.amazonaws.com/test-backing-image"
```

### Notice:

1. The backing image file in a disk will be shared among the replicas when these replicas in the same disk are using the same backing image.
2. Please be careful of the escape character `\` when you input a URL in a StorageClass.
3. Users need to make sure the backing image existence when they use UI to create or restore a volume with a backing image specified.

## Clean up backing images in disks
- Longhorn automatically cleans up the backing images in the disk based on [the setting `Backing Image Cleanup Wait Interval`](../../references/settings#backing-image-cleanup-wait-interval).
- The unused backing images can be cleaned up manually via the Longhorn UI: Click **Setting > Backing Image > CleanupBackingImage** of one backing image. Then choose disks.

## Node Failure Handling
- There is one pod with the naming schema `<Backing image name>-<first 8 characters of the disk UUID>` handling the actual file for each backing image in each disk.
  Hence, whether a replica in a disk has access to a backing image totally depends on if the related pod is available or not.
- When the node is down, Kubernetes evicts the pods on the node, and the backing image download state of the disks on the node will become `failed`.
- After the node is back, Longhorn will try to clean up, then recreate the pod for the backing image on the node.
  All rebuilding/reused replicas on the node won't become `running` until the pod becomes `running` again.

In brief, Longhorn will automatically recover the backing images after the node is back, users don't need to worry about it.

## Warning
The URL of the backing image should be public. We will improve this part in the further.

## History
* Available since v1.1.1 [Enable backing image feature in Longhorn](https://github.com/Longhorn/Longhorn/issues/2006)
