---
title: Create a Backup via CSI
weight: 2
---

Backups in Longhorn are snapshots that are moved off-cluster into a backupstore.
A backup of a snapshot is copied to the backupstore, and the endpoint to access the backupstore is the backup target.

To programmatically create backups you can use the generic kubernetes csi snapshot mechanism.
To learn more about the CSI snapshot mechanism, click [here](https://kubernetes.io/docs/concepts/storage/volume-snapshots/).

> **Prerequisite:** CSI snapshot support needs to be enabled on your cluster.
> If your kubernetes distribution does not provide the kubernetes snapshot controller
> as well as the snapshot related custom resource definitions, you need to manually deploy them.
> For more information, see [Enable CSI Snapshot Support](../enable-csi-snapshot-support).


#### Create a backup, via the csi mechanism

1. Create a kubernetes `VolumeSnapshot` object via `kubectl` (example object below)
2. The `VolumeSnapshot.uuid` will be used to identify a **longhorn snapshot** and the associated `VolumeSnapshotContent` object.
3. This will create a new longhorn snapshot named `snapshot-uuid`
4. Then a backup of that snapshot will be initiated, and the csi request returns
5. Afterwards a `VolumeSnapshotContent` named `snapcontent-uuid` will be created
6. The CSI snapshotter side car will periodically query the longhorn csi plugin to evaluate the backup status
7. Once the backup is completed, the `VolumeSnapshotContent.readyToUse` flag will be set to **true**

**Result:**
A backup is created and the `VolumeSnapshotContent.snapshotHandle`
refers to the backup via `bs://backup-volume/backup-name`.

To see it, click **Backup** in the top navigation bar and navigate to the backup-volume mentioned in the `VolumeSnapshotContent.snapshotHandle`.

For information on how to restore a volume via a `VolumeSnapshot` object,
refer to [this page.](../restore-a-backup-via-csi)


Example `VolumeSnapshot` object below, the source needs to point to the PVC of the Longhorn volume for which a backup should be created.
The `volumeSnapshotClassName` field points to a `VolumeSnapshotClass`.
We create a default class named `longhorn`, which uses `Delete` as its `deletionPolicy`.
```yaml
apiVersion: snapshot.storage.k8s.io/v1beta1
kind: VolumeSnapshot
metadata:
  name: test-snapshot-pvc
spec:
  volumeSnapshotClassName: longhorn
  source:
    persistentVolumeClaimName: test-vol
```

If you want the associated backup for a volume to be retained when the `VolumeSnapshot` is deleted,
create a new `VolumeSnapshotClass` with `Retain` set as the `deletionPolicy`.
For more information about snapshot classes, see the kubernetes documentation for [VolumeSnapshotClasses](https://kubernetes.io/docs/concepts/storage/volume-snapshot-classes/).
