---
title: Volume Clone Support
description: Creating a new volume as a duplicate of an existing volume
weight: 3
---

Longhorn supports [CSI volume cloning](https://kubernetes.io/docs/concepts/storage/volume-pvc-datasource/).

## Volume Cloning

### Clone a Volume Using YAML

#### V1 Data Engine

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

> **Note**: Along with the requirements listed at [CSI volume cloning](https://kubernetes.io/docs/concepts/storage/volume-pvc-datasource/), the `cloned-pvc` must have the same `resources.requests.storage` as the `source-pvc`.

#### V2 Data Engine

Assume you have a `StorageClass` named `longhorn-v2` with `dataEngine: "v2"`, and a PVC named `source-pvc-v2` provisioned from it. You can clone it using one of two modes:

**1. Clone using `full-copy` mode**

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

**2. Clone using `linked-clone` mode**

The `full-copy` mode creates a new PVC that is fully independent of the source PVC, but it requires time and resources to copy the data. If you need to quickly create a temporary PVC with the same content as the source without copying the data (for example, for backup solutions like **Velero** or **Kasten**), you can use the `linked-clone` mode. This mode creates a new PVC that shares the same data blocks as the source PVC.

First, create a StorageClass with `cloneMode` set to `linked-clone`:

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

Next, create a new PVC that uses the above `StorageClass` and references the source PVC in the `dataSource` field:

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
> 1. The `linked-clone` mode is only supported by the v2 data engine.
> 2. A PVC created using `linked-clone` shares data blocks with the source and has the following limitations:
>    - It can have only one replica.
>    - It cannot be snapshotted or backed up.
>    - It cannot be used as the source for another clone operation.
>    - A source PVC can only have one `linked-clone` PVC at a time.
>    - `linked-clone` PVCs are designed to be short-lived. It is highly recommended to delete them when no longer needed. For more examples of linked-clone, see the blog - [Backup Applications with Longhorn V2 Volumes using Velero](https://longhorn.io/blog/20250902-k8s-backup-solutions-and-longhorn/).

### Clone CSI Snapshot

To clone a CSI snapshot, refer to the documentation on [Creating a Volume from a Snapshot](../snapshots-and-backups/csi-snapshot-support/csi-volume-snapshot-associated-with-longhorn-snapshot).

### Clone Volume Using the Longhorn UI

#### Clone a volume

1. Go to the **Volumes** page.
2. Select a volume, and then click **Clone Volume** in the **Operation** menu.
3. (Optional) Configure the settings of the new volume.
4. Click **OK**.

#### Clone a Volume Using a Snapshot

1. Go to the **Volumes** page.
2. Click the name of the volume that you want to clone.
3. In the **Snapshot and Backups** section of the details page, identify the snapshot that you want to use and then click **Clone Volume**.
4. (Optional) Configure the settings of the new volume.
5. Click **OK**.

{{< figure src="/img/screenshots/snapshots-and-backups/clone-volume-modal.png" >}}

#### Clone Multiple Volumes (Bulk Cloning)

1. Go to the **Volumes** page.
2. Select the volume you want to clone.
3. Click **Clone Volume** button on top of the table.
4. (Optional) Configure the settings of the new volumes
5. Click **OK**

**Note**:

> - The Longhorn UI pre-fills certain fields and prevents you from modifying the values to ensure that those match the settings of the source volume.
> - Longhorn automatically attaches the new volume, clones the source volume, and then detaches the new volume.
> - With efficient cloning enabled, a newly cloned and detached volume is degraded and has only one replica, with its clone status set to `copy-completed-awaiting-healthy`. To bring the volume to a healthy state, transition the clone status to `completed` and rebuild the remaining replica by either enabling offline replica rebuilding or attaching the volume to trigger replica rebuilding. See [Issue #12341](https://github.com/longhorn/longhorn/issues/12341) and [Issue #12328](https://github.com/longhorn/longhorn/issues/12328).

## Volume Creation

1. Go to the **Volumes** page.
2. Click **Create Volume**.
3. Select the data source (**Volume** or **Volume Snapshot**) that you want to use.
4. If you select **Volume Snapshot**, choose a snapshot.
5. Specify the volume name.
6. Click **OK**.

{{< figure src="/img/screenshots/snapshots-and-backups/create-volume-choose-datasource.png" >}}

## History

- [V1 GitHub Issue](https://github.com/longhorn/longhorn/issues/1815)
- [V1 Longhorn Enhancement Proposal](https://github.com/longhorn/longhorn/pull/2864)
- [V2 GitHub Issue](https://github.com/longhorn/longhorn/issues/7794)
- [V2 Longhorn Enhancement Proposal](https://github.com/longhorn/longhorn/pull/10873)

Available since v1.2.0 (V1 Data Engine) and v1.10.0 (V2 Data Engine).
