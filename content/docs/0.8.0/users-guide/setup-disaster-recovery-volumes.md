---
title: Setup Disaster Recovery Volumes
description: Help and potential gotchas associated with specific cloud providers.
weight: 49
---

A **disaster recovery volume** is a volume that stores data in a backup cluster in case the whole main cluster goes down. Disaster recovery volumes are used to increase the resiliency of Longhorn volumes.

## Creating DRVs {#creating}

1. In the cluster A, make sure the original volume X has backup created or recurring backup scheduling.
2. Set backup target in cluster B to be same as cluster A's.
3. In backup page of cluster B, choose the backup volume X then create disaster recovery volume Y. It's highly recommended
to use backup volume name as disaster volume name.
4. Attach the disaster recovery volume Y to any node. Then Longhorn will automatically polling for the last backup of the
volume X, and incrementally restore it to the volume Y.
5. If volume X is down, users can activate volume Y immediately. Once activated, volume Y will become a
normal Longhorn volume.
    5.1. Please note that deactivating a normal volume is not allowed.

## Activating DRVs {#activating}

1. A disaster recovery volume doesn't support creating/deleting/reverting snapshot, creating backup, creating
PV/PVC. Users cannot update `Backup Target` in Settings if any disaster recovery volumes exist.

2. When users try to activate a disaster recovery volume, Longhorn will check the last backup of the original volume. If
it hasn't been restored, the restoration will be started, and the activate action will fail. Users need to wait for
the restoration to complete before retrying.

3. For disaster recovery volume, `Last Backup` indicates the most recent backup of its original backup volume. If the icon
representing disaster volume is gray, it means the volume is restoring `Last Backup` and users cannot activate this
volume right now; if the icon is blue, it means the volume has restored the `Last Backup`.

## RPO and RTO
Typically incremental restoration is triggered by the periodic backup store update. Users can set backup store update
interval in `Setting - General - Backupstore Poll Interval`. Notice that this interval can potentially impact
Recovery Time Objective(RTO). If it is too long, there may be a large amount of data for the disaster recovery volume to
restore, which will take a long time. As for Recovery Point Objective(RPO), it is determined by recurring backup
scheduling of the backup volume. You can check [here](../backup-and-restore/scheduling-backups-and-snapshots) to see how to set recurring backup in Longhorn.

e.g.:

If recurring backup scheduling for normal volume A is creating backup every hour, then RPO is 1 hour.

Assuming the volume creates backup every hour, and incrementally restoring data of one backup takes 5 minutes.

If `Backupstore Poll Interval` is 30 minutes, then there will be at most one backup worth of data since last restoration.
The time for restoring one backup is 5 minute, so RTO is 5 minutes.

If `Backupstore Poll Interval` is 12 hours, then there will be at most 12 backups worth of data since last restoration.
The time for restoring the backups is 5 * 12 = 60 minutes, so RTO is 60 minutes.
