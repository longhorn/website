---
title: CSI Volume Clone Support
description: Creating a new volume as a duplicate of an existing volume
weight: 3
---

Longhorn supports [CSI volume cloning](https://kubernetes.io/docs/concepts/storage/volume-pvc-datasource/).

## Via Kubernetes Yaml
Suppose that you have the following `source-pvc`:
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: source-pvc
spec:
  storageClassName: longhorn
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
```
You can create a new PVC that has the exact same content as the `source-pvc` by applying the following yaml file:
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: cloned-pvc
spec:
  storageClassName: longhorn
  dataSource:
    name: source-pvc
    kind: PersistentVolumeClaim
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
```

> Note:
> In addition to the requirements listed at [CSI volume cloning](https://kubernetes.io/docs/concepts/storage/volume-pvc-datasource/),
> the `cloned-pvc` must have the same `resources.requests.storage` as the `source-pvc`.


## Via Longhorn UI

To clone volume from existing volume
1. Go to volume page
2. Choose a volume and click **Clone Volume** from operation menu
3. You can edit the cloned volume configurations and click Ok.

To clone volume from volume snapshot.
1. Go to volume page, click volume name to enter volume detail page
2. In **Snapshot and Backups** block, click *Clone Volume* from any snapshot or backup
3. You can edit the cloned volume configurations and click Ok.

{{< figure src="/img/screenshots/snapshots-and-backups/clone-volume-modal.png" >}}
> Notes.
> 1. Size, backing image, data source and data engine are prefilled and disabled since these fields should the same as source volume.
> 2. Longhorn will auto attach the new cloned volume, perform cloning from source volume, and then detach new volume.

To create new volume from existing volume or volume snapshot
1. Go to volume page, click **Create Volume** button
2. In **data source** field, choose the data source from existing volume or volume snapshot
3. Choose the volume name
4. Choose the volume snapshot if data source is **Volume Snapshot**


{{< figure src="/img/screenshots/snapshots-and-backups/create-volume-choose-datasource.png" >}}

## History
- [GitHub Issue](https://github.com/longhorn/longhorn/issues/1815)
- [Longhorn Enhancement Proposal](https://github.com/longhorn/longhorn/pull/2864)

Available since v1.2.0, available from UI since v1.7.0
