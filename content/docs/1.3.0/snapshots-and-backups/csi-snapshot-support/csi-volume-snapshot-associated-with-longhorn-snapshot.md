---
title: CSI VolumeSnapshot Associated with Longhorn Snapshot
weight: 2
---

Snapshot in Longhorn is an object that represents content of a Longhorn volume at a particular moment. It is stored inside the cluster.

To programmatically create Longhorn snapshots, you can use the generic Kubernetes CSI VolumeSnapshot mechanism. To learn more about the CSI VolumeSnapshot mechanism, click [here](https://kubernetes.io/docs/concepts/storage/volume-snapshots/).

> **Prerequisite:** CSI snapshot support needs to be enabled on your cluster.
> If your kubernetes distribution does not provide the kubernetes snapshot controller
> as well as the snapshot related custom resource definitions, you need to manually deploy them.
> For more information, see [Enable CSI Snapshot Support](../enable-csi-snapshot-support).

## Create A CSI VolumeSnapshot Associated With Longhorn Snapshot

To create a CSI VolumeSnapshot associated with a Longhorn snapshot, you first need to create a `VolumeSnapshotClass` object
with the parameter `type` set to `ss` as follow:
```yaml
kind: VolumeSnapshotClass
apiVersion: snapshot.storage.k8s.io/v1beta1
metadata:
  name: longhorn-snapshot-vsc
driver: driver.longhorn.io
deletionPolicy: Delete
parameters:
  type: ss
```
For more information about `VolumeSnapshotClass`, see the kubernetes documentation for [VolumeSnapshotClasses](https://kubernetes.io/docs/concepts/storage/volume-snapshot-classes/).

After that, create a Kubernetes `VolumeSnapshot` object with `volumeSnapshotClassName` points to the name of the `VolumeSnapshotClass` (`longhorn-snapshot-vsc`) and
the `source` points to the PVC of the Longhorn volume for which a Longhorn snapshot should be created.
```yaml
apiVersion: snapshot.storage.k8s.io/v1beta1
kind: VolumeSnapshot
metadata:
  name: test-csi-volume-snapshot-longhorn-snapshot
spec:
  volumeSnapshotClassName: longhorn-snapshot-vsc
  source:
    persistentVolumeClaimName: test-vol
```

**Result:**
A Longhorn snapshot is created. The `VolumeSnapshot` object creation leads to the creation of a `VolumeSnapshotContent` Kubernetes object.
The `VolumeSnapshotContent` refers to a Longhorn snapshot in its `VolumeSnapshotContent.snapshotHandle` field with the name `ss://volume-name/snapshot-name`.

### Viewing the Longhorn Snapshot

To see the snapshot, click **Volume** in the top navigation bar and click the volume mentioned in the `VolumeSnapshotContent.snapshotHandle`. Scroll down to see the list of all volume snapshots.


### How the CSI Mechanism Works in this Scenario

When the VolumeSnapshot object is created with kubectl, the `VolumeSnapshot.uuid` field is used to identify a Longhorn snapshot and the associated `VolumeSnapshotContent` object.

This creates a new Longhorn snapshot named `snapshot-uuid` and the CSI request returns.

Afterwards a `VolumeSnapshotContent` object named `snapcontent-uuid` is created with the `VolumeSnapshotContent.readyToUse` flag is set to **true**.


## Restore PVC from CSI VolumeSnapshot Associated With Longhorn Snapshot
Create a `PersistentVolumeClaim` object where the `dataSource` field points to an existing `VolumeSnapshot` object that is associated with Longhorn snapshot.

The csi-provisioner will pick this up and instruct the Longhorn CSI driver to provision a new volume with the data from the associated Longhorn snapshot.

An example `PersistentVolumeClaim` is below. The `dataSource` field needs to point to an existing `VolumeSnapshot` object.

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-restore-pvc
spec:
  storageClassName: longhorn
  dataSource:
    name: test-csi-volume-snapshot-longhorn-snapshot
    kind: VolumeSnapshot
    apiGroup: snapshot.storage.k8s.io
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
```
Note that the `spec.resources.requests.storage` value must be the same as the size of `VolumeSnapshot` object.


## Current Limitation
* Longhorn volume must be in the attached state to create/restore snapshot using CSI VolumeSnapshot mechanism.
