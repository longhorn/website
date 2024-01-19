---
title: Backing Image Backup
weight: 2
---

As of v1.6.0, Longhorn supports backing up of backing images.

## Prerequisites

You must first [set up a backup target](../../../snapshots-and-backups/backup-and-restore/set-backup-target). If you skip this crucial step, the missing backup target will prevent Longhorn from creating a backup of the backing image.

## Create and Restore a Backup of a Backing Image

Because backing images are globally unique within the Longhorn system, the corresponding backups are also globally unique and are identified using the same name.

You can create backups of backing images using YAML. 

Example of backing image:
```yaml
apiVersion: longhorn.io/v1beta2
kind: BackingImage
metadata:
  name: parrot
  namespace: longhorn-system
spec:
  sourceType: download
  sourceParameters:
    url: https://longhorn-backing-image.s3-us-west-1.amazonaws.com/parrot.raw
  checksum: 304f3ed30ca6878e9056ee6f1b02b328239f0d0c2c1272840998212f9734b196371560b3b939037e4f4c2884ce457c2cbc9f0621f4f5d1ca983983c8cdf8cd9a
```

Example of YAML code used to create a backup of the sample backing image:
```yaml
apiVersion: longhorn.io/v1beta2
kind: BackupBackingImage
metadata:
  name: parrot
  namespace: longhorn-system
spec:
  userCreated: true
  labels:
    usecase: test
    type: raw
```

> **IMPORTANT:**
> - `name`: Use the same name for the backing image and its backup. If the names are not identical, Longhorn will not be able to find the backing image.
> - `userCreated`: Set the value to `true` to indicate that you created the backup custom resource, which enabled the creation of the backup in the backupstore. The value `false` indicates that the backup custom resource was synced from the backupstore.
> - `labels`: You can add labels to the backing image backup.

## Restore a Backing Image from a Backup
You can restore a backing image in another cluster after creating a backup in the backupstore.

Example of YAML code used to restore a backing image:
```yaml
apiVersion: longhorn.io/v1beta2
kind: BackingImage
metadata:
    name: parrot-restore
    namespace: longhorn-system
spec:
    sourceType: restore
    sourceParameters:
        # change to your backup URL
        # backup-url: nfs://longhorn-test-nfs-svc.default:/opt/backupstore?backingImage=parrot
        backup-url: s3://backupbucket@us-east-1/?backingImage=parrot
        concurrent-limit: "2"
    checksum: 304f3ed30ca6878e9056ee6f1b02b328239f0d0c2c1272840998212f9734b196371560b3b939037e4f4c2884ce457c2cbc9f0621f4f5d1ca983983c8cdf8cd9a
```

> **IMPORTANT:**
> - `sourceType`: Set the value to `restore`.
> - `sourceParameters`: Configure the following parameters:
>   - `backup-url`: URL of the backing image resource in the backupstore. You can find this information in the status of the backup custom resource `.Status.URL`.
>   - `concurrent-limit`: Maximum number of worker threads that can concurrently run for each restore operation. When unspecified, Longhorn uses the default value.
> - `checksum`: You can specify the expected SHA-512 checksum of the backing image file, which Longhorn uses to validate the restored file. When unspecified, Longhorn uses the checksum of the restored file as the truth.

## Volume with a Backing Image

When you create a backup of a volume, Longhorn automatically creates a backup of its backing image.

You can restore a volume with a backing image. If the image already exists in the cluster, Longhorn uses the image directly. If the image exists in the backupstore but not in the cluster, Longhorn automatically restores the backing image.