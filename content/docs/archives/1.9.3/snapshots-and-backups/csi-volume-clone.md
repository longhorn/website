---
title: Volume Clone Support
description: Creating a new volume as a duplicate of an existing volume
weight: 3
---

Longhorn supports [CSI volume cloning](https://kubernetes.io/docs/concepts/storage/volume-pvc-datasource/).


## Volume Cloning

### Clone a Volume Using YAML
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


### Clone Volume Using the Longhorn UI

#### Clone a volume
1. Go to the **Volume** page.
2. Select a volume, and then click **Clone Volume** in the **Operation** menu.
3. (Optional) Configure the settings of the new volume.
4. Click **OK**.

#### Clone a Volume Using a Snapshot
1. Go to the **Volume** page.
2. Click the name of the volume that you want to clone.
3. In the **Snapshot and Backups** section of the details page, identify the snapshot that you want to use and then click **Clone Volume**.
4. (Optional) Configure the settings of the new volume.
5. Click **OK**.

{{< figure src="/img/screenshots/snapshots-and-backups/clone-volume-modal.png" >}}

#### Clone Multiple Volumes (Bulk Cloning)
1. Go to the **Volume** page.
2. Select the volume you want to clone.
3. Click **Clone Volume** button on top of the table.
4. (Optional) Configure the settings of the new volumes
5. Click **OK**


**Note**:
> - The Longhorn UI pre-fills certain fields and prevents you from modifying the values to ensure that those match the settings of the source volume.
> - Longhorn automatically attaches the new volume, clones the source volume, and then detaches the new volume.


## Volume Creation
1. Go to the **Volume** page.
2. Click **Create Volume**.
3. Select the data source (**Volume** or **Volume Snapshot**) that you want to use.
4. If you select **Volume Snapshot**, choose a snapshot.
5. Specify the volume name.
6. Click **OK**.

{{< figure src="/img/screenshots/snapshots-and-backups/create-volume-choose-datasource.png" >}}

## History
- [GitHub Issue](https://github.com/longhorn/longhorn/issues/1815)
- [Longhorn Enhancement Proposal](https://github.com/longhorn/longhorn/pull/2864)

Available since v1.2.0
