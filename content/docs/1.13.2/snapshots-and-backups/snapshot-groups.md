---
title: Create a Snapshot Group
weight: 2
---

A snapshot group takes snapshots of a set of volumes with a single request. Longhorn creates one snapshot per member volume and tracks them together in a `SnapshotGroup` resource, so at restore time it is clear which snapshots belong together.

You can manage snapshot groups from the Longhorn UI or with kubectl regardless of whether [CSI VolumeGroupSnapshot support](../csi-snapshot-support/csi-volume-group-snapshot) is enabled. Groups created through CSI appear on the **Snapshot Groups** page as well.

> **Important: Consistency boundary** 
> Longhorn snapshots each member volume independently, so a group snapshot is crash-consistent per volume and only loosely aligned in time across volumes. For application-level consistency, quiesce or pause the application while the group snapshot is taken.

## Create a Snapshot Group

You can create a snapshot group from the Longhorn UI or with kubectl. A new group starts in the `InProgress` state and becomes `Ready` when every member snapshot is taken, or `Failed` when the deadline passes first. Member snapshots already taken by a failed group remain valid per-volume snapshots until the group is deleted.

**Rules and Constraints:**
* **Eligibility:** Member volumes must be eligible for a snapshot when the group is created. Standby (DR), restoring, and faulted volumes are rejected. Detached volumes are eligible and are automatically attached. 
* **Limits:** A snapshot group is capped at a maximum of 64 member volumes.

### From the Longhorn UI

Open the create dialog from either of two places:

- **Snapshot Groups** page: In the top navigation bar, click **Snapshot Groups**, and then click **Create Snapshot Group**.
- **Volume** page: Select one or more volumes and click **Create Snapshot Group** in the bulk actions, or use the same action of a single volume. The selected volumes are pre-filled in the dialog.

In the dialog, set:

- **Name:** The group name (at most 54 characters).
- **Volumes** or **Label selector:** (Choose exactly one) The member volumes, provided either as an explicit list or as label rules matched against volume labels. With a label selector, a live preview shows the matching volumes and the reason when a volume cannot be a member.
- **Labels (optional):** Applied to every member snapshot as Longhorn snapshot labels.
- **Deadline seconds:** The time allowed for taking all member snapshots before the group fails. The default is 300, and the valid range is 10 to 3600.

Click **OK** to create the group.

### With kubectl

Create a `SnapshotGroup` custom resource in the `longhorn-system` namespace. Select the member volumes with exactly one of `volumes` or `volumeSelector`:

```yaml
apiVersion: longhorn.io/v1beta2
kind: SnapshotGroup
metadata:
  name: group-a
  namespace: longhorn-system
spec:
  volumes:
    - test-vol-1
    - test-vol-2
  # Alternatively, select the member volumes by their labels:
  # volumeSelector:
  #   matchLabels:
  #     app-group: demo
  deadlineSeconds: 300
```

## Inspect a Snapshot Group

The **Snapshot Groups** page lists every group with its status, member count (ready members over total), and creation time. Click a group to open its detail page, which shows the member table: each member's volume, snapshot name, readiness, creation time, and error, plus the failure reason if the group failed.

A snapshot group cannot be edited after creation: a group is a point-in-time request. The **Recreate** action opens the create dialog pre-filled from the group's settings and creates a new group; the original group is not changed.

## Degraded Snapshot Groups

After a group becomes `Ready`, deleting or losing one of its member snapshots marks the group `Degraded` (the set is no longer complete). Longhorn does not take a replacement snapshot, because it would not match the group's original point in time. The surviving member snapshots can still be restored individually.

On the volume detail page, the snapshot list shows the group a member snapshot belongs to. Deleting a member snapshot asks whether to delete only that snapshot, which degrades its group, or to delete the entire group.

## Delete a Snapshot Group

On the **Snapshot Groups** page, use the **Delete** action of a group, or select multiple groups and delete them in bulk. Deleting a group deletes its member snapshots along with it.

## History

- [GitHub Issue #13349](https://github.com/longhorn/longhorn/issues/13349)

Available since v1.13.0.
