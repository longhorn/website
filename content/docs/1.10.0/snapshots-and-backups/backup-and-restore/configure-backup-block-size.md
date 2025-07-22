---
title: Configure The Block Size Of Backup
weight: 2
---

## Backup Blocks In Longhorn

A Longhorn backup is a collection of data fragments derived from a snapshot, with each fragment referred to as a block. Blocks are the fundamental units for data processing, transmission, and storage in the backup target. For a given backup, all blocks have a uniform physical size. Prior to Longhorn v1.10.0, the backup block size was fixed at 2 MiB. Starting with Longhorn v1.10.0, users can specify the backup block size when creating a volume. The backup block size is immutable for a created volume. The backup block size information is available on the Longhorn volume detail page, and all backups created from a volume will use the block size specified during the volume's creation.

The backup block size impacts the efficiency of backup creation and storage. Generally, larger block sizes reduce the number of blocks, improving backup transmission efficiency and lowering the API request overhead with the backup target. However, larger block sizes require more zero-padding within block files, increasing the overall physical storage footprint of the backup, and requiring more memory during backup creation.

## Global Default Backup Block Size

A global setting allows users to configure the default backup block size when creating a volume. If the backup block size is not specified during volume creation, the system will apply the value defined in `Settings > General > Default Backup Block Size` for that volume.

## Create a Volume And Specify The Backup Block Size

To create a backup with specific backup block size,

1. Navigate to the **Volume** menu.
2. Click **Create Volume.**
3. Select the desired backup block size in the volume creation dialog.

## Specify The Backup Block Size In The Storage Class

For volumes created using a Persistent Volume Claim (PVC), the backup block size can be specified in the `parameters` field of the StorageClass.

Example:

```yaml
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: longhorn-example
provisioner: driver.longhorn.io
parameters:
  backupBlockSize: 16Mi
...
```

## Restoring Volume From a Backup

When restoring a volume from backup, the new volume can be configured with a different backup block size.

**Caution**: This functionality lacks backward compatibility. Attempting to restore a backup that uses a non-default backup block size (anything other than 2MiB) on Longhorn v1.9.x or older systems will result in volume creation with file system corruption.
