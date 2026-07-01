---
title: Configure The Block Size Of Backup
weight: 2
---

## Backup Blocks In Longhorn

A Longhorn backup is composed of data fragments derived from a snapshot, where each fragment is called a block. Blocks are the fundamental units used for processing, transmission, and storage in the backup target. All blocks within a single backup have the same physical size.

Prior to Longhorn v1.10.0, the backup block size was fixed at **2 MiB**. Starting in Longhorn v1.10.0, users can configure the backup block size during **volume creation**. This value is immutable once the volume is created. The block size used for backups is displayed on the volume detail page in the Longhorn UI, and all backups for a volume will use the size defined at creation.

### Impact of Backup Block Size

Longhorn supports two available backup block size, 2 MiB and 16 MiB. The selected block size affects the efficiency of backup creation and storage:

1. Larger block sizes reduce the total number of blocks, improving transmission efficiency and reducing the number of API requests to the backup target.
2. However, larger block sizes can increase the physical storage footprint due to zero-padding and require more memory during backup creation.

## Global Default Backup Block Size

A global setting allows users to define the default backup block size for new volumes. If a backup block size is not explicitly set during volume creation, Longhorn will apply the default value. To change the default backup block size:

- Using Longhorn UI:
    ```
    Settings > General > Default Backup Block Size
    ```
- Using `kubectl`:
    ```bash
    kubectl -n longhorn-system edit settings.longhorn.io default-backup-block-size
    ```

## Create a Volume And Specify The Backup Block Size

To specify a custom backup block size during volume creation:

1. Navigate to the **Volume** menu.
2. Click **Create Volume**.
3. In the volume creation dialog, inside `Advanced Configurations`, select the desired **Backup Block Size**.

## Specify The Backup Block Size In The Storage Class

For volumes provisioned through a Persistent Volume Claim (PVC), you can set the `backupBlockSize` in the `parameters` section of the `StorageClass`.

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

When restoring a volume from a backup, the restored volume can be configured with a different backup block size than the original.

**Caution**: Longhorn versions prior to v1.10 lack forward compatibility and cannot restore backups created by v1.10 or later. Restoring a backup with a non-default backup block size (anything other than 2 MiB) on Longhorn v1.9.x or older will result in a volume being created with file system corruption.


