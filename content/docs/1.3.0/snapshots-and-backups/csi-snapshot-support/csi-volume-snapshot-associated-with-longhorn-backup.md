---
title: CSI VolumeSnapshot Associated with Longhorn Backup
weight: 3
---

Backups in Longhorn are objects in an off-cluster backupstore, and the endpoint to access the backupstore is the backup target. For more information, see [this section.](../../../concepts/#31-how-backups-work)

To programmatically create backups, you can use the generic Kubernetes CSI VolumeSnapshot mechanism. To learn more about the CSI VolumeSnapshot mechanism, click [here](https://kubernetes.io/docs/concepts/storage/volume-snapshots/).

> **Prerequisite:** CSI snapshot support needs to be enabled on your cluster.
> If your kubernetes distribution does not provide the kubernetes snapshot controller
> as well as the snapshot related custom resource definitions, you need to manually deploy them.
> For more information, see [Enable CSI Snapshot Support](../enable-csi-snapshot-support).

## Create A CSI VolumeSnapshot Associated With Longhorn Backup

To create a CSI VolumeSnapshot associated with a Longhorn backup, you first need to create a `VolumeSnapshotClass` object
with the parameter `type` set to `bs` as follow:
```yaml
kind: VolumeSnapshotClass
apiVersion: snapshot.storage.k8s.io/v1beta1
metadata:
  name: longhorn-backup-vsc
driver: driver.longhorn.io
deletionPolicy: Delete
parameters:
  type: bs
```
For more information about `VolumeSnapshotClass`, see the kubernetes documentation for [VolumeSnapshotClasses](https://kubernetes.io/docs/concepts/storage/volume-snapshot-classes/).

After that, create a Kubernetes `VolumeSnapshot` object with `volumeSnapshotClassName` points to the name of the `VolumeSnapshotClass` (`longhorn-backup-vsc`) and
the `source` points to the PVC of the Longhorn volume for which a backup should be created.
```yaml
apiVersion: snapshot.storage.k8s.io/v1beta1
kind: VolumeSnapshot
metadata:
  name: test-csi-volume-snapshot-longhorn-backup
spec:
  volumeSnapshotClassName: longhorn-backup-vsc
  source:
    persistentVolumeClaimName: test-vol
```

**Result:**
A backup is created. The `VolumeSnapshot` object creation leads to the creation of a `VolumeSnapshotContent` Kubernetes object.
The `VolumeSnapshotContent` refers to a Longhorn backup in its `VolumeSnapshotContent.snapshotHandle` field with the name `bs://backup-volume/backup-name`.

### Viewing the Backup

To see the backup, click **Backup** in the top navigation bar and navigate to the backup-volume mentioned in the `VolumeSnapshotContent.snapshotHandle`.

For information on how to restore a volume via a `VolumeSnapshot` object, refer to the below sections.

### How the CSI Mechanism Works in this Scenario

When the VolumeSnapshot object is created with kubectl, the `VolumeSnapshot.uuid` field is used to identify a Longhorn snapshot and the associated `VolumeSnapshotContent` object.

This creates a new Longhorn snapshot named `snapshot-uuid`.

Then a backup of that snapshot is initiated, and the CSI request returns.

Afterwards a `VolumeSnapshotContent` object named `snapcontent-uuid` is created.

The CSI snapshotter sidecar periodically queries the Longhorn CSI plugin to evaluate the backup status.

Once the backup is completed, the `VolumeSnapshotContent.readyToUse` flag is set to **true**.


## Restore PVC from CSI VolumeSnapshot Associated With Longhorn Backup
Create a `PersistentVolumeClaim` object where the `dataSource` field points to an existing `VolumeSnapshot` object that is associated with Longhorn backup.

The csi-provisioner will pick this up and instruct the Longhorn CSI driver to provision a new volume with the data from the associated backup.

An example `PersistentVolumeClaim` is below. The `dataSource` field needs to point to an existing `VolumeSnapshot` object.

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-restore-pvc
spec:
  storageClassName: longhorn
  dataSource:
    name: test-csi-volume-snapshot-longhorn-backup
    kind: VolumeSnapshot
    apiGroup: snapshot.storage.k8s.io
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
```
Note that the `spec.resources.requests.storage` value must be the same as the size of `VolumeSnapshot` object.


#### Restore a Longhorn Backup that Has No Associated `VolumeSnapshot`
You can use the CSI mechanism to restore Longhorn backups that have not been created via the CSI mechanism.
To restore Longhorn backups that have not been created via the CSI mechanism, you have to first manually create a `VolumeSnapshot` and `VolumeSnapshotContent` object for the backup.

Create a `VolumeSnapshotContent` object with the `snapshotHandle` field set to `bs://backup-volume/backup-name`.

The `backup-volume` and `backup-name` values can be retrieved from the **Backup** page in the Longhorn UI.

```yaml
apiVersion: snapshot.storage.k8s.io/v1beta1
kind: VolumeSnapshotContent
metadata:
  name: test-existing-backup
spec:
  volumeSnapshotClassName: longhorn
  driver: driver.longhorn.io
  deletionPolicy: Delete
  source:
    # NOTE: change this to point to an existing backup on the backupstore
    snapshotHandle: bs://test-vol/backup-625159fb469e492e
  volumeSnapshotRef:
    name: test-snapshot-existing-backup
    namespace: default
```

Create the associated `VolumeSnapshot` object with the `name` field set to `test-snapshot-existing-backup`, where the `source` field refers to a `VolumeSnapshotContent` object via the `volumeSnapshotContentName` field.

This differs from the creation of a backup, in which case the `source` field refers to a `PerstistentVolumeClaim` via the `persistentVolumeClaimName` field.

Only one type of reference can be set for a `VolumeSnapshot` object.

```yaml
apiVersion: snapshot.storage.k8s.io/v1beta1
kind: VolumeSnapshot
metadata:
  name: test-snapshot-existing-backup
spec:
  volumeSnapshotClassName: longhorn
  source:
    volumeSnapshotContentName: test-existing-backup
```

Now you can create a `PerstistantVolumeClaim` object that refers to the newly created `VolumeSnapshot` object.
For an example see [Restore PVC from CSI VolumeSnapshot Associated With Longhorn Backup](#restore-pvc-from-csi-volumesnapshot-associated-with-longhorn-backup) above.

## Current Limitation

* Longhorn volume must be in the attached state to create/restore snapshot using CSI VolumeSnapshot mechanism.
