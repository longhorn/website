---
title: Backing Image
weight: 1
---

Longhorn natively supports backing images since v1.1.1.

A QCOW2 or RAW image can be set as the backing/base image of a Longhorn volume, which allows Longhorn to be integrated with a VM like [Harvester](https://github.com/rancher/harvester).

> **Important**:  
> The image size must be **a multiple of 512 bytes**. Longhorn uses direct I/O, which requires alignment of file sizes with the underlying storage block size.

## Create V1 Data Engine Backing Image

### Parameters during creation

#### The data source of a backing image
You can prepare a V1 Data Engine backing image using any of the supported data sources.
1. Download a backing image file (using a URL).
2. Upload a file from your local machine. This option is available to Longhorn UI users.
3. Export an existing in-cluster volume as a backing image.
4. Restore a backing image from the backupstore, For more information, see [Backing Image Backup](../backing-image-backup).
5. Clone a backing image.

#### Volume exporting

A backing image serves as the initial snapshot in the snapshot chain of a Longhorn volume. When you export a volume with an associated backing image, Longhorn merges that image with the delta changes, resulting in a new consolidated backing image.

#### The checksum of a backing image
- The checksum of a backing image is **the SHA512 checksum** of the whole backing image **file** rather than that of the actual content.
  What's the difference? When Longhorn calculates the checksum of a qcow2 file, it will read the file as a raw file instead of using the qcow library to read the correct content. In other words, users always get the correct checksum by executing `shasum -a 512 <the file path>` regardless of the file format.
- It's recommended to provide the expected checksum during backing image creation.
  Otherwise, Longhorn will consider the checksum of the first file as the correct one. Once there is something wrong with the first file preparation, which then leads to an incorrect checksum as the expected value, this backing image is probably unavailable.

#### Scheduling
- Longhorn first prepares and stores the backing image file on a random node and disk, and then duplicates the file to the disks that are storing the replicas.
- For improved space efficiency, you can add `nodeSelector` and `diskSelector` to force storing of backing image files on a specific set of nodes and disks.
- The replicas cannot be scheduled on nodes or disks where the backing image cannot be scheduled.

#### Number of copies
- You can add `minNumberOfCopies` to ensure that multiple backing image files exist in the cluster.
- You can adjust the `minNumberOfCopies` in the global setting to apply the default value to the BackingImage.

### The way of creating a backing image

#### Create a backing image via Longhorn UI
On **Setting > Backing Image** page, users can create backing images with any kinds of data source.

#### Create a V1 Backing Image Using YAML
You can download a file or export an existing volume as a backing image via YAML.
It's better not to "upload" a file via YAML. Otherwise, you need to manually handle the data upload via HTTP requests.

Here are some examples:
```yaml
apiVersion: longhorn.io/v1beta2
kind: BackingImage
metadata:
  name: bi-download
  namespace: longhorn-system
spec:
  dataEngine: v1
  minNumberOfCopies: 2
  nodeSelector:
    - "node1"
  diskSelector:
    - "disk1"
  sourceType: download
  sourceParameters:
    url: https://longhorn-backing-image.s3-us-west-1.amazonaws.com/parrot.raw
  checksum: 304f3ed30ca6878e9056ee6f1b02b328239f0d0c2c1272840998212f9734b196371560b3b939037e4f4c2884ce457c2cbc9f0621f4f5d1ca983983c8cdf8cd9a
```
```yaml
apiVersion: longhorn.io/v1beta2
kind: BackingImage
metadata:
  name: bi-export
  namespace: longhorn-system
spec:
  dataEngine: v1
  minNumberOfCopies: 2
  nodeSelector:
    - "node1"
  diskSelector:
    - "disk1"
  sourceType: export-from-volume
  sourceParameters:
    volume-name: vol-export-src
    export-type: qcow2
```

#### Create and use a backing image via StorageClass and PVC
1. In a Longhorn StorageClass.
2. Setting parameter `backingImageName` means asking Longhorn to use this backing image during volume creation.
3. If you want to create the backing image as long as it does not exist during the CSI volume creation, parameters `backingImageDataSourceType` and `backingImageDataSourceParameters` should be set as well. Similar to YAML, it's better not to create a backing image via "upload" in StorageClass. Note that if all of these parameters are set and the backing image already exists, Longhorn will validate if the parameters matches the existing one before using it.
    - For `download`:
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
        backingImageMinNumberOfCopies: "2"
        backingImageNodeSelector: "node1"
        backingImageDiskSelector: "disk1"
        dataEngine: "v1"
      ```
    - For `export-from-volume`:
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
        backingImage: "bi-export-from-volume"
        backingImageDataSourceType: "export-from-volume"
        backingImageDataSourceParameters: '{"volume-name": "vol-export-src", "export-type": "qcow2"}'
        backingImageMinNumberOfCopies: "2"
        backingImageNodeSelector: "node1"
        backingImageDiskSelector: "disk1"
        dataEngine: "v1"
      ```

4. Create a PVC with the StorageClass. Then the backing image will be created (with the Longhorn volume) if it does not exist.
5. Longhorn starts to prepare the backing images to disks for the replicas when a volume using the backing image is attached to a node.

#### Notice:
- Please be careful of the escape character `\` when you input a download URL in a StorageClass.
- A backing image that is created using a StorageClass has the same data engine as the volume.

## Utilize a backing image in a volume

Users can [directly create then immediately use a backing image via StorageClass](./#create-and-use-a-backing-image-via-storageclass-and-pvc),
or utilize an existing backing image as mentioned below.

#### Use an existing backing
##### Use an existing backing Image during volume creation
1. Click **Setting > Backing Image** in the Longhorn UI.
2. Click **Create Backing Image** to create a backing image with a unique name and a valid URL.
3. Select a backing image from the list. The volume and the backing image must use the same data engine.
4. Longhorn starts to download the backing image to disks for the replicas when a volume using the backing image is attached to a node.

##### Use an existing backing Image during volume restore
1. Click `Backup` and pick up a backup volume for the restore.
2. As long as the backing image is already set for the backup volume, Longhorn will automatically choose the backing image during the restore.
3. Longhorn allows you to re-specify/override the backing image during the restore.

#### Download the backing image file to the local machine
Since v1.3.0, users can download existing backing image files to the local via UI.

#### Notice:
- Users need to make sure the backing image existence when they use UI to create or restore a volume with a backing image specified.
- Before downloading an existing backing image file to the local, users need to guarantee there is a ready file for it.
- Downloading of V2 Data Engine backing images is currently not supported.

## Create a V2 Data Engine Backing Image

Starting v1.8.0, you can create a backing image that is supported by the V2 Data Engine by configuring `Data Engine` in the YAML (through the UI or a StorageClass).

### Parameters During Creation

All parameters are the same as that of the V1 Data Engine backing image, except for `Data Engine`.

#### Backing Image Data Sources

You can prepare a V2 Data Engine backing image using any of the supported data sources.
- Download a backing image file (using a URL).
- Upload a file from your local machine. This option is available to Longhorn UI users.
- Export an existing in-cluster V1 Data Engine volume as a backing image.
- Restore a backing image from the backupstore. For more information, see [Backing Image Backup](../backing-image-backup).
- Clone a V1 backing image.

#### Notice

- The following operations are currently not supported:
  - Exporting from a V2 Data Engine volume
  - Cloning a V2 backing image
  - Backing up a V2 backing image
- Unlike the V1 Data Engine, which is file-based, the V2 Data Engine requires Longhorn to store the backing image data in an SPDK logical volume. As a result, for qcow2 images, Longhorn must first convert the qcow2 image to a raw format before storing the data to the V2 Data Engine backing image, enabling it to read the correct data.

## Clean up backing images

#### Clean up backing images in disks
- Longhorn automatically cleans up the unused backing image files in the disks based on [the setting `Backing Image Cleanup Wait Interval`](../../../references/settings#backing-image-cleanup-wait-interval). But Longhorn will retain at least one file in a disk for each backing image anyway.
- You can manually remove backing images from disks using the Longhorn UI. Go to **Setting** > **Backing Image**, and then click the name of a specific backing image. In the window that opens, select one or more disks and then click **Clean Up**.
- Once there is one replica in a disk using a backing image, no matter what the replica's current state is, the backing image file in this disk cannot be cleaned up.

#### Delete backing images
- The backing image can be deleted only when there is no volume using it.

## Backing image recovery
- If there is still a ready backing image file in one disk, Longhorn will automatically clean up the failed backing image files then re-launch these files from the ready one.
- If somehow all files of a backing image become failed, and the first file is :
  - downloaded from a URL, Longhorn will restart the downloading.
  - exported from an existing volume, Longhorn will (attach the volume if necessary then) restart the export.
  - uploaded from user local env, there is no way to recover it. Users need to delete this backing image then re-create a new one by re-uploading the file.
- When a node is down or the backing image manager pod on the node is unavailable, all backing image files on the node will become `unknown`. Later on if the node is back and the pod is running, Longhorn will detect then reuse the existing files automatically.

## Backing image eviction
- You can manually evict all backing image files from a node or disk by setting `Scheduling` to `Disabled` and `Eviction Requested` to `True` on the Longhorn UI.
- If only one backing image file exists in the cluster, Longhorn first duplicates the file to another disk and then deletes the file.
- If the backing image file cannot be duplicated to other disks, Longhorn does not delete the file. You can update the settings to resolve the issue.

## Backing image Workflow
1. To manage all backing image files in a disk, Longhorn will create one backing image manager pod for each disk. Once the disk has no backing image file requirement, the backing image manager will be removed automatically.
2. Once a backing image file is prepared by the backing image manager for a disk, the file will be shared among all volume replicas in this disk.
3. When a backing image is created, Longhorn will launch a backing image data source pod to prepare the first file. The file data is from the data source users specified (download from remote/upload from local/export from the volume). After the preparation done, the backing image manager pod in the same disk will take over the file then Longhorn will stop the backing image data source pod.
4. Once a new backing image is used by a volume, the backing image manager pods in the disks that the volume replicas reside on will be asked to sync the file from the backing image manager pods that already contain the file.
5. As mentioned in the section [#clean-up-backing-images-in-disks](#clean-up-backing-images-in-disks), the file will be cleaned up automatically if all replicas in one disk do not use one backing image file.

## Concurrent limit of backing image syncing
- `Concurrent Backing Image Replenish Per Node Limit` in the global settings controls how many backing images copies on a node can be replenished simultaneously.
- When set to 0, Longhorn won't replenish the copy automatically event it is less than the `minNumberOfCopies`

## Warning
- The download URL of the backing image should be public. We will improve this part in the future.
- If there is high memory usage of one backing image manager pod after [file download](#download-the-backing-image-file-to-the-local-machine), this is caused by the system cache/buffer. The memory usage will decrease automatically hence you don't need to worry about it. See [the GitHub ticket](https://github.com/longhorn/longhorn/issues/4055) for more details.

## History
* Available since v1.1.1 [Enable backing image feature in Longhorn](https://github.com/Longhorn/Longhorn/issues/2006)
* Support [upload](https://github.com/longhorn/longhorn/issues/2404) and [volume exporting](https://github.com/longhorn/longhorn/issues/2403) since v1.2.0.
* Support [download to local](https://github.com/longhorn/longhorn/issues/2404) and [volume exporting](https://github.com/longhorn/longhorn/issues/3155) since v1.3.0.
