---
title: Set Backing Image for Longhorn Volumes
weight: 4
---

Longhorn natively supports backing images since v1.1.1.

A QCOW2 or RAW image can be set as the backing/base image of a Longhorn volume, which allows Longhorn to be integreted with a VM like [Harvester](https://github.com/rancher/harvester).

## Create and Use a Backing Image

### Create a backing image via Longhorn UI
There are 3 ways to create a backing image:
  1. Download a file from a URL as a backing image.
  2. Upload a local file as a backing image. This type is almost exclusive for UI.
  3. Export an existing in-cluster volume as a backing image.

### Create a backing image via YAML
You can download a file or export an existing volume as a backing image via YAML.
It's better not to "upload" a file via YAML. Otherwise, you need to manually handle the data upload via HTTP requests.

Here are some examples:
```yaml
apiVersion: longhorn.io/v1beta1
kind: BackingImage
metadata:
  name: bi-download
  namespace: longhorn-system
spec:
  sourceType: download
  sourceParameters:
    url: https://longhorn-backing-image.s3-us-west-1.amazonaws.com/parrot.raw
  checksum: 304f3ed30ca6878e9056ee6f1b02b328239f0d0c2c1272840998212f9734b196371560b3b939037e4f4c2884ce457c2cbc9f0621f4f5d1ca983983c8cdf8cd9a
```
```yaml
apiVersion: longhorn.io/v1beta1
kind: BackingImage
metadata:
  name: bi-export
  namespace: longhorn-system
spec:
  sourceType: export-from-volume
  sourceParameters:
    volume-name: vol-export-src
    export-type: qcow2
```

### Create and use a backing image via StorageClass and PVC
1. In a Longhorn StorageClass.
  1. Setting parameter `backingImageName` means asking Longhorn to use this backing image during volume creation.
  2. If you want to create the backing image as long as it does not exist during the CSI volume creation, parameters `backingImageDataSourceType` and `backingImageDataSourceParameters` should be set as well. Similar to YAML, it's better not to create a backing image via "upload" in StorageClass.
     e.g.:
     ```yaml
     kind: StorageClass
     apiVersion: storage.k8s.io/v1
     metadata:
       name: longhorn-backing-image-example
     provisioner: driver.longhorn.io
     allowVolumeExpansion: true
     reclaimPolicy: Delete
     volumeBindingMode: Immediate
     parameters:
       numberOfReplicas: "3"
       staleReplicaTimeout: "2880"
       backingImage: "bi-download"
       backingImageDataSourceType: "download"
       backingImageDataSourceParameters: '{"url": "https://backing-image-example.s3-region.amazonaws.com/test-backing-image"}'
       backingImageChecksum: "SHA512 checksum of the backing image"
     ```
     If all of these parameters are set and the backing image already exists, Longhorn will validate if the parameters matches the existing one before using it.
2. Create a PVC with the StorageClass. Then the backing image will be created (with the Longhorn volume) if it does not exist.
3. Longhorn starts to prepare the backing images to disks for the replicas when a volume using the backing image is attached to a node.

#### Use an existing backing Image during volume creation
1. Click **Setting > Backing Image** in the Longhorn UI.
2. Click **Create Backing Image** to create a backing image with a unique name and a valid URL.
3. During the volume creation, specify the backing image from the backing image list.
4. Longhorn starts to download the backing image to disks for the replicas when a volume using the backing image is attached to a node.

#### Use an existing backing Image during volume restore
1. Click `Backup` and pick up a backup volume for the restore.
2. As long as the backing image is already set for the backup volume, Longhorn will automatically choose the backing image during the restore.
3. Longhorn allows you to re-specify/override the backing image during the restore.

### Notice:
1. Once the first backing image file is downloaded from remote/uploaded from local/exported from the volume, it will be copied to other disks via backing image manager pods when there are volume replicas in these disks want it.
2. The backing image file in a disk will be shared among all volume replicas in the this disk.
3. Please be careful of the escape character `\` when you input a download URL in a StorageClass.
4. Users need to make sure the backing image existence when they use UI to create or restore a volume with a backing image specified.

## Clean up backing images in disks
- Longhorn automatically cleans up the backing image files in the disks based on [the setting `Backing Image Cleanup Wait Interval`](../../references/settings#backing-image-cleanup-wait-interval). But Longhorn will retain at least one file in a disk for each backing image anyway.
- The unused backing images can be cleaned up manually via the Longhorn UI: Click **Setting > Backing Image > CleanupBackingImage** of one backing image. Then choose disks.

## Failure Handling
- There is one pod with the naming schema `<Backing image name>-<first 8 characters of the disk UUID>` handling the actual file for each backing image in each disk.
- When the node is down, Kubernetes evicts the pods on the node, and the backing image file state of the disks on the node will become `failed`.
- After the node is back, the backing image manager pods will be recreated. Then the pods will try to reuse the existing backing images file on the node or fetch the files from other backing image manager pods.
  All rebuilding/reused replicas on the node won't become `running` until the pod becomes `running` again.
- For a backing image, if files in all disks becomes failed, Longhorn won't do recovery for it unless it is downloaded from a URL.

In brief, Longhorn will automatically recover the backing images after the node is back, users don't need to worry about it.

## Warning
The download URL of the backing image should be public. We will improve this part in the further.

## History
* Available since v1.1.1 [Enable backing image feature in Longhorn](https://github.com/Longhorn/Longhorn/issues/2006)
* Support [upload]((https://github.com/longhorn/longhorn/issues/2404) and [volume exporting](https://github.com/longhorn/longhorn/issues/2403) since v1.2.0.
