---
title: Volume Conditions
weight: 7
---

## Volume Conditions 

Volume conditions describe the current status of a volume and potential issues that may occur.
- `Scheduled`: All replicas were scheduled successfully. 
    If Longhorn was unable to schedule any of the replicas, the condition is set to `false` and error messages are displayed. The condition is set to `true` when the setting [Allow Volume Creation With Degraded Availability](../../../references/settings#allow-volume-creation-with-degraded-availability) is enabled and at least one replica is scheduled.
- `TooManySnapshots`: This specific volume has more than 100 snapshots.
    Longhorn allows you to create a maximum of 250 snapshots for each volume. For more information about configuring the maximum snapshot count, see [Snapshot Space Management](../../../snapshots-and-backups/snapshot-space-management).
- `Restore`: Longhorn is restoring the volume from a backup.
- `WaitForBackingImage`: The replicas have not started because the backing images must first be synced with their disks.

## Engine Conditions

Engine conditions describe the current status of an engine and potential issues that may occur.
`FilesystemReadOnly`: The state of the current volume mount point has changed to read-only. 
This change may prevent workloads from writing data to the volume. For troubleshooting information, see [Volume Recovery](../../../high-availability/recover-volume).


## Replica Conditions

Replica conditions describe the current status of a replica and potential issues that may occur.
- `RebuildFailed`: The replica failed to rebuild.
- `WaitForBackingImage`: The replicas have not started because the backing images must first be synced with their disks.