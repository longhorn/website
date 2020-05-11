---
title: Scheduling Recurring Snapshots and Backups
weight: 3
---

From the Longhorn UI, recurring snapshots and backups can be scheduled.

Recurring snapshots can be configured using the Longhorn UI, or by using a Kubernetes [StorageClass.](https://kubernetes.io/docs/concepts/storage/storage-classes/)

For more information on how snapshots and backups work, refer to the [concepts](../../concepts) section.

## Set up Recurring Jobs using the Longhorn UI

> **Prerequisite:** A [backup target](../backup-and-restore/set-backup-target) must be set up before backups can be created.

Recurring snapshots and backups can be configured from the volume detail page. 

1. In the Longhorn UI, click the **Volume** tab.
2. Click the name of the volume that should have recurring snapshots or backups.
3. Scroll down to the **Recurring Snapshot and Backup Schedule** section and click **New.** In the table row that appears, set the following information:

    - The type of schedule, either backup or snapshot
    - The interval that the backup or snapshot will be created, in the form of a [CRON expression](https://en.wikipedia.org/wiki/Cron#CRON_expression)
    - The number of backups or snapshots to retain
    - Any labels that should be applied to the backup or snapshot

For help writing the expression, click the time under the **Schedule** column and click **Generate CRON** in the window that appears.

After the job is scheduled, Longhorn will automatically create snapshots or backups for the user at that time, as long as the volume is attached to a node.

## Set up Recurring Jobs using a StorageClass

Scheduled backups and snapshots can be configured in the `recurringJobs` parameters in a StorageClass.

Any future volumes created using this StorageClass will have those recurring jobs automatically set up.

The `recurringJobs` field should follow JSON format:

    kind: StorageClass
    apiVersion: storage.k8s.io/v1
    metadata:
      name: longhorn
    provisioner: driver.longhorn.io
    parameters:
      numberOfReplicas: "3"
      staleReplicaTimeout: "30"
      fromBackup: ""
      recurringJobs: '[
        { 
          "name":"snap", 
          "task":"snapshot", 
          "cron":"*/1 * * * *", 
          "retain":1
        },
        {
          "name":"backup", 
          "task":"backup", 
          "cron":"*/2 * * * *", 
          "retain":1
        }
      ]'



The following parameters should be specified for each recurring job:

- `name`: Name of one job. Do not use duplicate name in one `recurringJobs`. And the length of `name` should be no more than 8 characters.
- `task`: Type of one job. It supports `snapshot` (periodically create snapshot) or `backup` (periodically create snapshot then do backup) only.
- `cron`: Cron expression. It tells execution time of one job.
- `retain`: How many snapshots/backups Longhorn will retain for one job. It should be no less than 1.
