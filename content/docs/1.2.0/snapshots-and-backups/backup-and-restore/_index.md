---
title: Backup and Restore
weight: 2
---

> Before v1.2.0, Longhorn uses a blocking way for communication with the remote backup target, so there will be some potential voluntary or involuntary factors (ex: network latency) impacting the functions relying on remote backup target like listing backups or even causing further cascading problems after the backup target operation.

> Start from v1.2.0, Longhorn uses an asynchronous way to pull backup volumes and backups from the remote backup target (S3/NFS) then persistently saved via cluster custom resources. This can resolve the problems above mentioned by asynchronously querying the list of backup volumes and backups from the remote backup target for final consistent available results. It's also scalable for the costly resources created by the original blocking query operations.

- [Setting a Backup Target](./set-backup-target)
- [Create a Backup](./create-a-backup)
- [Restore from a Backup](./restore-from-a-backup)
- [Restoring Volumes for Kubernetes StatefulSets](./restore-statefulset)
