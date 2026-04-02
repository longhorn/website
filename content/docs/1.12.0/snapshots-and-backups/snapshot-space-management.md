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

This value also serves as the threshold for the `TooManySnapshots` condition when it is greater than 0. See [TooManySnapshots Condition](#toomanysnapshots-condition).

**SnapshotMaxSize**: Maximum aggregate size of snapshots for a specific volume.

You can specify "0" or any value larger than `Volume.Spec.Size` multiplied by 2. You must double the value of `Volume.Spec.Size` because Longhorn requires at least two snapshots to function properly.

The default value is "0", which effectively disables the setting.

When you expand the volume size, Longhorn automatically increases the value of this setting to `Volume.Spec.Size` multiplied by 2 (if the current value is smaller).

When `SnapshotMaxSize` is set to a non-zero value, Longhorn also uses it as the threshold for the `TooManySnapshots` condition. See [TooManySnapshots Condition](#toomanysnapshots-condition).

## TooManySnapshots Condition

Longhorn sets the `TooManySnapshots` volume condition when snapshot usage approaches or exceeds the configured limits. The condition is evaluated against two independent thresholds.

Removed snapshots, backing images, and the volume head are excluded from both calculations.

### Count-Based Threshold

The condition is set when the number of snapshots strictly exceeds the effective count threshold.

The effective threshold is determined in the following order:

1. `SnapshotMaxCount` (volume-specific setting), if the value is greater than 0.
2. The global `snapshot-max-count` setting, if the volume-specific setting is 0.

### Size-Based Threshold

The condition is set when the total size of all snapshots is at or over the `SnapshotMaxSize` value.

This threshold is only active when `SnapshotMaxSize` is set to a non-zero value. When `SnapshotMaxSize` is "0" (the default), size is not evaluated.

### Combined Warnings

Both thresholds are evaluated independently on each reconciliation. When both are exceeded simultaneously, the condition message includes a description for each reason, separated by a semicolon.
