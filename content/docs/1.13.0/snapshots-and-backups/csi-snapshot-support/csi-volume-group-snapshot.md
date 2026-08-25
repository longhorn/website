---
title: CSI VolumeGroupSnapshot Associated with Longhorn Snapshot Group
weight: 5
---

A `VolumeGroupSnapshot` takes snapshots of a set of Longhorn volumes as one group with a single request. Longhorn tracks each group in a `SnapshotGroup` custom resource in the `longhorn-system` namespace and creates one Longhorn snapshot per member volume. Kubernetes then returns one `VolumeSnapshot` per member PVC, all bound to the same group, so at restore time it is clear which snapshots belong together.

> **Important: Consistency boundary**
> Longhorn snapshots each member volume independently, so a group snapshot is crash-consistent per volume and only loosely aligned in time across volumes. For application-level consistency, quiesce or pause the application while the group snapshot is taken. See [Issue #2128](https://github.com/longhorn/longhorn/issues/2128) for the planned application-consistent snapshot work that builds on this feature.

## Prerequisites

CSI Volume Group Snapshot support must be enabled on your cluster and in Longhorn. See [Enable CSI Volume Group Snapshot Support](../enable-csi-volume-group-snapshot-support).

## Create a CSI VolumeGroupSnapshot Associated with a Longhorn Snapshot Group

First, label the PVCs that should be snapshotted together:

```shell
kubectl label pvc test-vol-1 test-vol-2 app-group=demo
```

Create a `VolumeGroupSnapshotClass` with the parameter `type` set to `snap`:

```yaml
apiVersion: groupsnapshot.storage.k8s.io/v1
kind: VolumeGroupSnapshotClass
metadata:
  name: longhorn-group-snap-vgsc
driver: driver.longhorn.io
deletionPolicy: Delete
parameters:
  type: snap
```

Then create a `VolumeGroupSnapshot` in the application namespace with a selector matching the PVC labels:

```yaml
apiVersion: groupsnapshot.storage.k8s.io/v1
kind: VolumeGroupSnapshot
metadata:
  name: test-group-snapshot
spec:
  volumeGroupSnapshotClassName: longhorn-group-snap-vgsc
  source:
    selector:
      matchLabels:
        app-group: demo
```

**Result:**
Longhorn creates one `SnapshotGroup` custom resource and one snapshot per member volume. Once the group is ready, the snapshot-controller creates one `VolumeSnapshot` per member PVC, each bound to the group. The `VolumeGroupSnapshotContent` records the group as `snap://group-name` in its `volumeGroupSnapshotHandle` field; each member `VolumeSnapshotContent` uses the existing `snap://volume-name/snapshot-name` format.

You can observe the group's progress with kubectl:

```shell
kubectl -n longhorn-system get snapshotgroups
NAME                                                 PHASE   READYTOUSE   CREATIONTIME           AGE
groupsnapshot-59e29b09-2661-4faf-9862-1571f8e68e94   Ready   true         2026-08-25T02:11:05Z   1m
```

The group starts in `InProgress` and becomes `Ready` when every member snapshot is taken, or `Failed` if the completion deadline (300 seconds by default) passes first. A failed CSI-created group is cleaned up automatically, and the snapshot-controller retries with a fresh group.

## Create a CSI VolumeGroupSnapshot Associated with Longhorn Backups

A `VolumeGroupSnapshotClass` with the parameter `type` set to `bak` requests a group backup instead: the same group snapshot is taken first, then each member snapshot is uploaded to the backup target.

```yaml
apiVersion: groupsnapshot.storage.k8s.io/v1
kind: VolumeGroupSnapshotClass
metadata:
  name: longhorn-group-bak-vgsc
driver: driver.longhorn.io
deletionPolicy: Delete
parameters:
  type: bak
```

The group reports ready only when every member backup completes. The group handle uses the `bak://group-name` format, and each member uses the existing `bak://volume-name/backup-name` format.

The group label is stored in each member backup's metadata on the backup target, so a restore from another cluster can find the whole set of backups belonging to one group.

The optional `backupMode` parameter sets the backup mode for the member backups: `incremental` (default) or `full`. For more information about `backupMode`, see [Create A Backup](../../backup-and-restore/create-a-backup).

> **Note:** The `type` parameter must be `snap` or `bak`. All other class parameters (except the reserved `backupMode`) are applied to every member snapshot as Longhorn snapshot labels.

## Restore a Member PVC

Each member `VolumeSnapshot` is a normal `VolumeSnapshot`. Restore it on its own by creating a PVC whose `dataSource` points to it, exactly as for a per-volume snapshot. For details, see [CSI VolumeSnapshot Associated with Longhorn Snapshot](../csi-volume-snapshot-associated-with-longhorn-snapshot#restore-pvc-from-csi-volumesnapshot-associated-with-longhorn-snapshot) and [CSI VolumeSnapshot Associated with Longhorn Backup](../csi-volume-snapshot-associated-with-longhorn-backup).

## Delete a CSI VolumeGroupSnapshot

Delete the `VolumeGroupSnapshot` object. With a `Delete` deletion policy, this deletes the `VolumeGroupSnapshotContent`, the Longhorn `SnapshotGroup`, and all of its member snapshots (for a `bak` group, the member backups as well). Kubernetes does not allow deleting the member `VolumeSnapshot` objects individually while they belong to a group.

## Limitations

- A group is capped at 64 member volumes.
- The group name is at most 54 characters, because member snapshots are named `<group-name>-<8-character-suffix>` and the result must fit the 63-character name limit.
- `deadlineSeconds` sets the time allowed for taking all member snapshots; the default is 300 and the valid range is 10 to 3600. It does not limit the backup uploads of a `bak` group.
- A snapshot group cannot be edited after creation: a group is a point-in-time request.
- Member volumes must be eligible for a snapshot at creation time: standby (DR), restoring, and faulted volumes are rejected. Detached volumes are eligible and are automatically attached.
- After a group becomes `Ready`, deleting one of its member snapshots marks the group `Degraded`. Longhorn does not take a replacement snapshot, because it would not match the group's point in time.

## History

- [GitHub Issue #13349](https://github.com/longhorn/longhorn/issues/13349)

Available since v1.13.0.
