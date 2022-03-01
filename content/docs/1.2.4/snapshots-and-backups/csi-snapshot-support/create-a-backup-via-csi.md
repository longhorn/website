---
title: Create a Backup via CSI
weight: 2
---

Backups in Longhorn are objects in an off-cluster backupstore, and the endpoint to access the backupstore is the backup target. For more information, see [this section.](../../../concepts/#31-how-backups-work)

To programmatically create backups, you can use the generic Kubernetes CSI snapshot mechanism. To learn more about the CSI snapshot mechanism, click [here](https://kubernetes.io/docs/concepts/storage/volume-snapshots/).

> **Prerequisite:** CSI snapshot support needs to be enabled on your cluster.
> If your kubernetes distribution does not provide the kubernetes snapshot controller
> as well as the snapshot related custom resource definitions, you need to manually deploy them.
> For more information, see [Enable CSI Snapshot Support](../enable-csi-snapshot-support).


## Create a Backup via the CSI Mechanism

To create a backup using the CSI mechanism, create a Kubernetes `VolumeSnapshot` object via `kubectl`. An example is [here.](#example-volumesnapshot)

**Result:**
A backup is created. The `VolumeSnapshot` object creation leads to the creation of a `VolumeSnapshotContent` Kubernetes object.

The `VolumeSnapshotContent` refers to a Longhorn backup in its `VolumeSnapshotContent.snapshotHandle` field with the name `bs://backup-volume/backup-name`.

### How the CSI Mechanism Works

When the VolumeSnapshot object is created with kubectl, the `VolumeSnapshot.uuid` field is used to identify a Longhorn snapshot and the associated `VolumeSnapshotContent` object.

This creates a new Longhorn snapshot named `snapshot-uuid`.

Then a backup of that snapshot is initiated, and the CSI request returns.

Afterwards a `VolumeSnapshotContent` object named `snapcontent-uuid` is created.

The CSI snapshotter sidecar periodically queries the Longhorn CSI plugin to evaluate the backup status.

Once the backup is completed, the `VolumeSnapshotContent.readyToUse` flag is set to **true**.

### Viewing the Backup

To see the backup, click **Backup** in the top navigation bar and navigate to the backup-volume mentioned in the `VolumeSnapshotContent.snapshotHandle`.

For information on how to restore a volume via a `VolumeSnapshot` object,
refer to [this page.](../restore-a-backup-via-csi)

### Example VolumeSnapshot

An example `VolumeSnapshot` object is below. The `source` needs to point to the PVC of the Longhorn volume for which a backup should be created.

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

If you want the associated backup for a volume to be retained when the `VolumeSnapshot` is deleted, create a new `VolumeSnapshotClass` with `Retain` set as the `deletionPolicy`.

For more information about snapshot classes, see the kubernetes documentation for [VolumeSnapshotClasses](https://kubernetes.io/docs/concepts/storage/volume-snapshot-classes/).
