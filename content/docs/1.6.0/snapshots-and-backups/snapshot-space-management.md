---
title: Snapshot Space Management
weight: 1
---

Starting with v1.6.0, Longhorn allows you to configure the maximum snapshot count and the maximum aggregate snapshot size for each volume. Both settings do not take into account removed snapshots, backing images, and volume head snapshots. When either of these limits is reached, you must delete snapshots before creating new ones.

In earlier versions, the maximum snapshot count is not configurable (the value is 250) and there is no way to limit snapshot space usage.

## Settings

### Global Settings

**snapshot-max-count**: Maximum number of snapshots that you can create for each volume.

You must specify a value between "2" and "250". Longhorn requires at least two snapshots to function properly, particularly during volume rebuilding. One snapshot is created when the existing snapshots are merged, while the other snapshot is created during the rebuilding process.
The default value is "250".

When you create a volume without changing the default value of `.Spec.SnapshotMaxCount`, Longhorn applies the value of the `snapshot-max-count` setting. Changing the value of `snapshot-max-count` does not affect existing volumes.

### Volume-Specific Settings

**SnapshotMaxCount**: Maximum number of snapshots that you can create for a specific volume.

You can specify "0" or any value between "2" and "250". The default value is "0".

When you create a volume without changing the default value of this setting, Longhorn applies the value of the `snapshot-max-count` setting.

**SnapshotMaxSize**: Maximum aggregate size of snapshots for a specific volume.

You can specify "0" or any value larger than `Volume.Spec.Size` multiplied by 2. You must double the value of `Volume.Spec.Size` because Longhorn requires at least two snapshots to function properly.

The default value is "0", which effectively disables the setting.

When you expand the volume size, Longhorn automatically increases the value of this setting to `Volume.Spec.Size` multiplied by 2 (if the current value is smaller).
