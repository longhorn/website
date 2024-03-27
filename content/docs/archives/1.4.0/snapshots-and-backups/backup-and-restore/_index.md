---
title: Backup and Restore
weight: 2
---

> Before v1.2.0, Longhorn uses a blocking way for communication with the remote backup target, so there will be some potential voluntary or involuntary factors (ex: network latency) impacting the functions relying on remote backup target like listing backups or even causing further cascading problems after the backup target operation.

> Since v1.2.0, Longhorn starts using an asynchronous way to do backup operations to resolve the abovementioned issues in the previous versions.
> - Create backup cluster custom resources first, and then perform the following snapshot and backup operations to the remote backup target.
> - Once the backup creation is completed, asynchronously pull the state of backup volumes and backups from the remote backup target, then update the status of the corresponding cluster custom resources.
>
> Besides, this enhancement is scalable for the backup query to solve the costly resources (even query timeout) caused by the original blocking way because all backups are saved as custom resources instead of querying from the remote target directly.
>
> Please note that: after the Longhorn upgrade, if a volume hasn’t been upgraded to the latest longhorn engine (>=v1.2.0). When creating a backup, it will have the intermediate transition state of the name of the created backup (due to the different backup name handling in the latest longhorn version >= v1.2.0). However, in the end, Longhorn will ensure the backup is synced with the remote backup target and the backup will be updated to the final correct state as the remote backup target is the single source of truth. To upgrade the Longhorn engine, please refer to [Manually Upgrade Longhorn Engine](../../deploy/upgrade/upgrade-engine) or [Automatically Upgrade Longhorn Engine](../../deploy/upgrade/auto-upgrade-engine).

- [Setting a Backup Target](./set-backup-target)
- [Create a Backup](./create-a-backup)
- [Restore from a Backup](./restore-from-a-backup)
- [Restoring Volumes for Kubernetes StatefulSets](./restore-statefulset)
