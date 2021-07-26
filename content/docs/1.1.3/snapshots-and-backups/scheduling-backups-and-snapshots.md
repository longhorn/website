---
title: Recurring Snapshots and Backups
weight: 3
---

From the Longhorn UI, recurring snapshots and backups can be scheduled.

To set up a schedule, you will go to the volume detail view in Longhorn. Then you will set:

- The type of schedule, either backup or snapshot
- The time that the backup or snapshot will be created, in the form of a [CRON expression](https://en.wikipedia.org/wiki/Cron#CRON_expression)
- The number of backups or snapshots to retain
- Any labels that should be applied to the backup or snapshot

Then Longhorn will automatically create snapshots or backups for the user at that time, as long as the volume is attached to a node.
If you want to set up recurring snapshots and backups even when the volumes are detached, see the section [Allow Recurring Job While Volume Is Detached](#allow-recurring-job-while-volume-is-detached)

Recurring snapshots can be configured using the Longhorn UI, or by using a Kubernetes [StorageClass.](https://kubernetes.io/docs/concepts/storage/storage-classes/)

For more information on how snapshots and backups work, refer to the [concepts](../../concepts) section.

> Note: To avoid the problem that recurring jobs may overwrite the old backups/snapshots with identical backups and empty snapshots when the volume doesn't new data for a long time, Longhorn does the following:
> 1. Recurring backup job only takes a new backup when the volume has new data since the last backup.
> 1. Recurring snapshot job only takes a new snapshot when the volume has new data in the volume head (the live data).

## Set up Recurring Jobs using the Longhorn UI

Recurring snapshots and backups can be configured from the volume detail page. To navigate to this page, click **Volume,** then click the name of the volume.

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

1. `name`: Name of one job. Do not use duplicate name in one `recurringJobs`. And the length of `name` should be no more than 8 characters.

2. `task`: Type of one job. It supports `snapshot` (periodically create snapshot) or `backup` (periodically create snapshot then do backup) only.

3. `cron`: Cron expression. It tells execution time of one job.

4. `retain`: How many snapshots/backups Longhorn will retain for one job. It should be no less than 1.

## Allow Recurring Job While Volume Is Detached

Longhorn provides the setting `allow-recurring-job-while-volume-detached` that allows you to do recurring backup even when a volume is detached.
You can find the setting in Longhorn UI.

When the setting is enabled, Longhorn will automatically attach the volume and take snapshot/backup when it is the time to do recurring snapshot/backup.

Note that during the time the volume was attached automatically, the volume is not ready for the workload. Workload will have to wait until the recurring job finishes.
