---
title: Restore a Backup via CSI
weight: 3
---

Longhorn can easily restore backups to a volume.
For more information on how backups work, refer to the [concepts](../../../concepts/#3-backups-and-secondary-storage) section.

To programmatically restore backups you can use the generic kubernetes csi snapshot mechanism.
To learn more about the CSI snapshot mechanism, click [here](https://kubernetes.io/docs/concepts/storage/volume-snapshots/).


> **Prerequisite:** CSI snapshot support needs to be enabled on your cluster.
> If your kubernetes distribution does not provide the kubernetes snapshot controller
> as well as the snapshot related custom resource definitions, you need to manually deploy them.
> For more information, see [Enable CSI Snapshot Support](../enable-csi-snapshot-support).


#### Restore a backup, via a `VolumeSnapshot` object
create a `PersistentVolumeClaim` object where the `dataSource` field points to an existing `VolumeSnapshot` object.

The csi-provisioner will pick this up and instruct the longhorn csi driver to provision
a new volume with the data from the associated backup.

Example `PersistentVolumeClaim` the `dataSource` field needs to point to an existing `VolumeSnapshot` object.
You can use the same mechanism to restore longhorn backups that have not been created via the csi mechanism, see below for an example.
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-restore-snapshot-pvc
spec:
  storageClassName: longhorn
  dataSource:
    name: test-snapshot-pvc
    kind: VolumeSnapshot
    apiGroup: snapshot.storage.k8s.io
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 2Gi
```


#### Restore a backup, that has no associated `VolumeSnapshot`
To restore longhorn backups that have not been created via the CSI mechanism,
you manually have to create a `VolumeSnapshot` and `VolumeSnapshotContent` object.

Create a `VolumeSnapshotContent` object with the `snapshotHandle` field set to `bs://backup-volume/backup-name`
The backup-volume and backup-name values can be retrieved from the **Backup** page in the Longhorn UI.
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

Create the associated `VolumeSnapshot` object with the `name` field set to `test-snapshot-existing-backup`
where the `source` field refers to a `VolumeSnapshotContent` object via the `volumeSnapshotContentName` field.
This differs from the creation of a backup in which case the `source`
field refers to a `PerstistantVolumeClaim` via the `persistentVolumeClaimName` field.
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

For an example see [Restore a backup, via a `VolumeSnapshot` object](#restore-a-backup-via-a-volumesnapshot-object) above.
