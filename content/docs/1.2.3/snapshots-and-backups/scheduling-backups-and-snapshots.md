---
title: Recurring Snapshots and Backups
weight: 3
---

From the Longhorn UI, the volume can refer to recurring snapshots and backups as independent jobs or as recurring job groups.

To create a recurring job, you can go to the `Recurring Job` page in Longhorn and `Create Recurring Job` or in the volume detail view in Longhorn.

You can configure,
- Any groups that the job should belong to
- The type of schedule, either `backup` or `snapshot`
- The time that the backup or snapshot will be created, in the form of a [CRON expression](https://en.wikipedia.org/wiki/Cron#CRON_expression)
- The number of backups or snapshots to retain
- The number of jobs to run concurrently
- Any labels that should be applied to the backup or snapshot

Recurring jobs can be set up using the Longhorn UI, `kubectl`, or by using a Longhorn `RecurringJob`.

To add a recurring job to a volume, you will go to the volume detail view in Longhorn. Then you can set `Recurring Jobs Schedule`.

- Create a new recurring job
- Select from existing recurring jobs
- Select from existing recurring job groups

Then Longhorn will automatically create snapshots or backups for the volume at the recurring job scheduled time, as long as the volume is attached to a node.
If you want to set up recurring snapshots and backups even when the volumes are detached, see the section [Allow Recurring Job While Volume Is Detached](#allow-recurring-job-while-volume-is-detached)

Recurring jobs can be added to a volume using the Longhorn UI, `kubectl` or by using a Kubernetes [StorageClass.](https://kubernetes.io/docs/concepts/storage/storage-classes/)

For more information on how snapshots and backups work, refer to the [concepts](../../concepts) section.

> Note: To avoid the problem that recurring jobs may overwrite the old backups/snapshots with identical backups and empty snapshots when the volume doesn't have new data for a long time, Longhorn does the following:
> 1. Recurring backup job only takes a new backup when the volume has new data since the last backup.
> 1. Recurring snapshot job only takes a new snapshot when the volume has new data in the volume head (the live data).

## Set up Recurring Jobs using the Longhorn UI

Recurring snapshots and backups can be configured from the `Recurring Job` page or the volume detail page.

## Set up Recurring Jobs using a Longhorn RecurringJob

Recurring jobs can also be set up by using a Longhorn `RecurringJob`.
```yaml
apiVersion: longhorn.io/v1beta1
kind: RecurringJob
metadata:
  name: snapshot-1
  namespace: longhorn-system
spec:
  cron: "* * * * *"
  task: "snapshot"
  groups:
  - default
  - group1
  retain: 1
  concurrency: 2
  labels:
    label/1: a
    label/2: b
```

The following parameters should be specified for each recurring job selector:

- `name`: Name of the recurring job. Do not use duplicate names. And the length of `name` should be no more than 40 characters.

- `task`: Type of the job. It supports `snapshot` (periodically create snapshot) or `backup` (periodically create snapshot then do backup).

- `cron`: Cron expression. It tells the execution time of the job.

- `retain`: How many snapshots/backups Longhorn will retain for each volume job. It should be no less than 1.

- `concurrency`: The number of jobs to run concurrently. It should be no less than 1.

Optional parameters can be specified:

- `groups`: Any groups that the job should belong to. Having `default` in groups will automatically schedule this recurring job to any volume with no recurring job.

- `labels`: Any labels that should be applied to the backup or snapshot.

## Set up Recurring Jobs to be the Default

Default recurring jobs can be set by tick the checkbox `default` using UI or adding `default` to the recurring job `groups`.

Longhorn will automatically add a volume to the `default` group when the volume has no recurring job.

## Recurring Jobs Assignment using the Longhorn UI

The recurring job can be assigned on the volume detail page. To navigate to the volume detail page, click **Volume** then click the name of the volume.

## Recurring job Assignment using the `kubectl label` command

Label recurring job group with `kubectl -n longhorn-system label volume/<VOLUME-NAME> recurring-job-group.longhorn.io/<RECURRING-JOB-GROUP-NAME>=enabled`
```
kubectl -n longhorn-system label volume/pvc-8b9cd514-4572-4eb2-836a-ed311e804d2f recurring-job-group.longhorn.io/default=enabled
```

Label recurring job with `kubectl -n longhorn-system label volume/<VOLUME-NAME> recurring-job.longhorn.io/<RECURRING-JOB-NAME>=enabled`
```
kubectl -n longhorn-system label volume/pvc-8b9cd514-4572-4eb2-836a-ed311e804d2f recurring-job.longhorn.io/backup1=enabled
```

Remove recurring job labels with `kubectl -n longhorn-system label volume/<VOLUME-NAME> <RECURRING-JOB-LABEL>-`
```
kubectl -n longhorn-system label volume/pvc-8b9cd514-4572-4eb2-836a-ed311e804d2f recurring-job.longhorn.io/backup1-
```

## Recurring Jobs Assignment using a StorageClass

Recurring job assignment can be configured in the `recurringJobSelector` parameters in a StorageClass.

Any future volumes created using this StorageClass will have those recurring jobs automatically assigned.

The `recurringJobSelector` field should follow JSON format:
```yaml
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: longhorn
provisioner: driver.longhorn.io
parameters:
  numberOfReplicas: "3"
  staleReplicaTimeout: "30"
  fromBackup: ""
  recurringJobSelector: '[
    {
      "name":"snap",
      "isGroup":true
    },
    {
      "name":"backup",
      "isGroup":false
    }
  ]'
```

The following parameters should be specified for each recurring job selector:

1. `name`: Name of an existing recurring job or an existing recurring job group.

2. `isGroup`: is the name that belongs to a recurring job or recurring job group, either `true` or `false`.


## Allow Recurring Job While Volume Is Detached

Longhorn provides the setting `allow-recurring-job-while-volume-detached` that allows you to do recurring backup even when a volume is detached.
You can find the setting in Longhorn UI.

When the setting is enabled, Longhorn will automatically attach the volume and take a snapshot/backup when it is time to do a recurring snapshot/backup.

Note that during the time the volume was attached automatically, the volume is not ready for the workload. Workload will have to wait until the recurring job finishes.
