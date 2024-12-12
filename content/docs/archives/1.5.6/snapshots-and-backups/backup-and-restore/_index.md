---
title: Backup and Restore
weight: 2
---

> Before v1.2.0, Longhorn used a "blocking way" for communication with the remote backup target. Consequently, there are some involuntary factors impacting the functions relying on remote backup target. For example, network latency, listing backups, or causing further cascading problems after the backup target operation.

> Since v1.2.0, Longhorn started using an asynchronous backup operations to resolve the aforementioned issues in the previous version.
> - To do this, create the backup cluster custom resources first, then perform the following snapshot and backup operations to the remote backup target.
> - Once the backup creation is completed, asynchronously pull the state of backup volumes and backups from the remote backup target. Then, update the status of the corresponding cluster custom resources.
>
> This enhancement is scalable for the backup query to assist with resolving the costly resources caused by the blocking way. This was because all backups are saved as custom resources instead of querying from the remote target directly.
>
> Note: After the Longhorn upgrade, if a volume has not been upgraded to the latest Longhorn engine (>=v1.2.0). When creating a backup, it will have the intermediate transition state of the name of the created backup (due to the different backup name handling in the latest longhorn version >= v1.2.0). Longhorn will then ensure the backup is synced with the remote backup target and the backup will be updated to the final correct state with the remote backup target is the single source of truth. To upgrade the Longhorn engine, refer to [Manually Upgrade Longhorn Engine](../../deploy/upgrade/upgrade-engine) or [Automatically Upgrade Longhorn Engine](../../deploy/upgrade/auto-upgrade-engine).

- [Setting a Backup Target](./set-backup-target)
- [Create a Backup](./create-a-backup)
- [Restore from a Backup](./restore-from-a-backup)
- [Restoring Volumes for Kubernetes StatefulSets](./restore-statefulset)
