---
  title: Create a Snapshot
  weight: 1
---

A [snapshot](../../concepts/#24-snapshots) is the state of a Kubernetes Volume at any given moment in time.

## Snapshot Management with UI

To create a snapshot of an existing cluster, follow these steps:

1. In the top navigation bar of the Longhorn UI, click **Volume.**
2. Click the name of the volume of which you want a snapshot. This leads to the volume detail page.
3. Click the **Take Snapshot** button

Once the snapshot is created you will see it in the list of snapshots for the volume before the Volume Head.

## Snapshot Management with CLI

The following sections will guide you through creating, listing, inspecting, and deleting Longhorn snapshots using kubectl and Kubernetes Custom Resources (CRs). 

> **Note**: To run the commands in the Snapshot Management section, you need to have the volume. For more information on how to create a volume, see [Create a Volume](../nodes-and-volumes/volumes/create-volumes.md).

### 1. Creating a Snapshot

In the Longhorn UI, a snapshot is created with a single click. Using `kubectl`, you create a snapshot by applying a `VolumeSnapshot` CR. You will need to know the name of the `PersistentVolumeClaim` (PVC) you want to snapshot.

**Step 1** - Create the Snapshot Manifest:

Create a file named `longhorn-snapshot.yaml` with the following content. This manifest creates a snapshot (Here, it is taking snapshot for the `longhorn-test-pvc` which was created previously).

```yaml
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshot
metadata:
  name: test-pvc-snapshot
spec:
  volumeSnapshotClassName: longhorn
  source:
    persistentVolumeClaimName: longhorn-test-pvc
```

**Step 2** - Apply the Manifest:

Run the following command to create the snapshot:

```bash
kubectl apply -f longhorn-snapshot.yaml
```

**Output**:

```bash
volumesnapshot.snapshot.storage.k8s.io/test-pvc-snapshot created
```

### 2. Listing All Snapshots for a Volume

To see the snapshots that have been created, you can list the `volumesnapshots` CRs in your cluster.

Run the following command to list all snapshots:

```bash
kubectl get volumesnapshot
```

**Output**:

```bash
NAME                READYTOUSE   SOURCEPVC           SOURCESNAPSHOTCONTENT   RESTORESIZE   SNAPSHOTCLASS   SNAPSHOTCONTENT   CREATIONTIME   AGE
test-pvc-snapshot                longhorn-test-pvc                                         longhorn                                         31s
```

### 3. Restoring a Volume from a Snapshot

Restoring a volume from a snapshot involves creating a new PVC with the snapshot as its data source. You must first delete the old PVC before you can restore the volume.

**Step 1** - Delete the Original PVC:

If the original PVC still exists, you must delete it first.

```bash
kubectl delete pvc longhorn-test-pvc
```

**Output**:

```bash
persistentvolumeclaim "longhorn-test-pvc" deleted
```

**Step 2** - Create a PVC from the Snapshot:

Create a new manifest file, `longhorn-pvc-restore.yaml`, to create a new PVC that uses the snapshot as its source.

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: restored-pvc
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: longhorn
  dataSource:
    name: test-pvc-snapshot
    kind: VolumeSnapshot
    apiGroup: snapshot.storage.k8s.io
  resources:
    requests:
      storage: 5Gi
```

**Step 3** - Apply the Manifest:

Run the following command to create the new PVC:

```bash
kubectl apply -f longhorn-pvc-restore.yaml
```

**Output**:

```bash
persistentvolumeclaim/restored-pvc created
```

You can then check the status of the new PVC with `kubectl get pvc`.

### 4. Deleting a Snapshot

To delete a snapshot, you simply need to delete the `VolumeSnapshot` CR.

Run the following command to delete the snapshot:

```bash
kubectl delete volumesnapshot test-pvc-snapshot
```

**Output**:

```bash
volumesnapshot.snapshot.storage.k8s.io "test-pvc-snapshot" deleted
```
