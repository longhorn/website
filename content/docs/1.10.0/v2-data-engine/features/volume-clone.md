---
title: V2 Volume Clone Support
description: Creating a new volume as a duplicate of an existing volume
weight: 3
---


## Clone Using YAML
### Clone CSI snapshot
Please refer to the documentation [Create Volume from Snapshot](../../../snapshots-and-backups/csi-snapshot-support/csi-volume-snapshot-associated-with-longhorn-snapshot).

### Clone Volume with v2 data engine
Suppose that you have the following StorageClass:
```yaml
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: longhorn-v2
provisioner: driver.longhorn.io
allowVolumeExpansion: true
reclaimPolicy: Delete
volumeBindingMode: Immediate
parameters:
  dataEngine: "v2"
  numberOfReplicas: "1"
  staleReplicaTimeout: "2880"
```
and a PersistentVolumeClaim named `source-pvc-v2` provisioned from this StorageClass:
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: source-pvc-v2
spec:
  storageClassName: longhorn-v2
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
```

#### Clone using `full-copy` mode
You can create a new PVC that has the exact same content as the `source-pvc-v2` by applying the following yaml file.
Longhorn will copy the data from the source PVC into the new PVC.
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: cloned-pvc-v2
spec:
  storageClassName: longhorn-v2
  dataSource:
    name: source-pvc-v2
    kind: PersistentVolumeClaim
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
```

#### Clone using `linked-clone` mode
The `full-copy` mode will make the new PVC fully independent of the source PVC.
However, it requires data to be copied from the source PVC to the new PVC which will consume time and resources.

Sometimes, you may want to quickly create a new PVC that has the same content as the source PVC without copying data.
For example, backup solution like Velero or Kasten want to quickly create a temporary PVC from the original PVC to read
the data and upload it to S3 bucket.
In this case, you can use the `linked-clone` mode to create a new PVC that shares the data blocks with the source PVC by following the steps below.

1. Create a StorageClass with `cloneMode` set to `linked-clone`.:
```yaml
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: longhorn-v2-linked-clone
provisioner: driver.longhorn.io
reclaimPolicy: Delete
volumeBindingMode: Immediate
parameters:
  dataEngine: "v2"
  cloneMode: "linked-clone"
  numberOfReplicas: "1"
  staleReplicaTimeout: "2880"
```
2. Create a new PVC that uses the above StorageClass and has the `dataSource` field set to the source PVC:
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: cloned-pvc-v2-linked-clone
spec:
  storageClassName: longhorn-v2-linked-clone
  dataSource:
    name: source-pvc-v2
    kind: PersistentVolumeClaim
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
```

> Notes:
> 1. In addition to the requirements listed at [CSI volume cloning](https://kubernetes.io/docs/concepts/storage/volume-pvc-datasource/),
     > the `cloned-pvc` must have the same `resources.requests.storage` as the `source-pvc`.
> 2. The `linked-clone` mode is only supported by the v2 data engine.
> 3. The PVC created using the `linked-clone` mode shares the data blocks with the source PVC. Therefore, it has the following limitations:
     >    - It can only have 1 replica
>    - It cannot be snapshotted or backed up
>    - It cannot be used as the source for another clone operation
>    - A source PVC can only have 1 `linked-clone` PVC at a time
>    - `linked-clone` PVC is supposed to be short-lived. It is recommended to delete the `linked-clone` PVC as soon as it is no longer needed.

For more examples about `linked-clone`, please refer to the blog [Backup Applications with Longhorn V2 Volumes using Velero](https://longhorn.io/blog/20250902-k8s-backup-solutions-and-longhorn/)

### Clone Volume Using the Longhorn UI

You can also clone a v2 data engine volume using the Longhorn UI by one of the following methods:
1. Go to the `Volumes` page ->  click `Create Volume` -> select the data source (`Volume` or `Volume Snapshot`) that you want to use
2. Go to the `Volumes` page -> select a volume -> click `Clone Volume` in the `Operation` menu
3. Go to the `Volumes` page -> select a volume -> click the volume name -> in the `Snapshot and Backups` section of the details page, identify the snapshot that you want to use and then click `Clone Volume`
4. Go to the `Volumes` page -> select volume(s) -> click `Clone Volume` button on top of the table (Bulk Cloning)

## History

- [GitHub Issue](https://github.com/longhorn/longhorn/issues/7794)
- [Longhorn Enhancement Proposal](https://github.com/longhorn/longhorn/pull/10873)

Available since v1.10.0
