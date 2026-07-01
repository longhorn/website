---
title: V2 Volume Clone Support
description: Creating a new volume as a duplicate of an existing volume
weight: 3
---


## Clone Using YAML

### Clone CSI snapshot
To clone a CSI snapshot, refer to the documentation on [Creating a Volume from a Snapshot](../../../snapshots-and-backups/csi-snapshot-support/csi-volume-snapshot-associated-with-longhorn-snapshot).

### Clone Volume with v2 data engine
Assume you have a `StorageClass` named `longhorn-v2`:
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
And you have a PersistentVolumeClaim (PVC) named `source-pvc-v2` provisioned from it:
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
You can create a new PVC with the exact same content as `source-pvc-v2` by applying the YAML below. Longhorn will copy the data from the source PVC to the new PVC.
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

The `full-copy` mode creates a new PVC that is fully independent of the source PVC. However, it requires time and resources to copy the data.
Sometimes, you need to quickly create a temporary PVC with the same content as the source, without copying the data. For example, backup solutions like **Velero** or **Kasten** can use this feature to quickly create a temporary PVC to read data and upload it to an S3 bucket.
In this scenario, you can use the `linked-clone` mode. This mode creates a new PVC that shares the same data blocks as the source PVC. Follow the steps below:

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
2. Create a new PVC that uses the above `StorageClass` and references the source PVC in the `dataSource` field:
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

> **Note**:
> 1. In addition to the requirements for [CSI Volume Cloning](https://kubernetes.io/docs/concepts/storage/volume-pvc-datasource/), the cloned PVC's (`cloned-pvc`) `resources.requests.storage` must match the source PVC's (`source-pvc`) storage size.
> 2. The `linked-clone` mode is only supported by the v2 data engine.
> 3. A PVC created using `linked-clone` shares data blocks with the source and has the following limitations:
>    - It can have only one replica.
>    - It cannot be snapshotted or backed up.
>    - It cannot be used as the source for another clone operation.
>    - A source PVC can only have one `linked-clone` PVC at a time.
>    - `linked-clone` PVCs are designed to be short-lived.  It is highly recommended to delete them when no longer needed.

For more examples of linked-clone, see the blog post, [Backup Applications with Longhorn V2 Volumes using Velero](https://longhorn.io/blog/20250902-k8s-backup-solutions-and-longhorn/).
### Clone Volume Using the Longhorn UI

You can also clone a v2 data engine volume using the Longhorn UI by one of the following methods:

1. On the **Volumes** page, click **Create Volume** and select the data source (`Volume` or `Volume Snapshot`).
2. From the **Volumes** page, select a volume and click **Clone Volume** in the **Operation** menu.
3. On the **Volumes** page, select a volume, click its name, and in the **Snapshot and Backups** section of the details page, identify the snapshot to use and then click **Clone Volume**.
4. For bulk cloning, on the **Volumes** page, select one or more volumes and click the **Clone Volume** button at the top of the table.

## History

- [GitHub Issue](https://github.com/longhorn/longhorn/issues/7794)
- [Longhorn Enhancement Proposal](https://github.com/longhorn/longhorn/pull/10873)

Available since v1.10.0
