---
title: Scheduling Snaphosts and Backups
weight: 44
---

Longhorn supports recurring snapshot and backup for volumes. User only need to set when he/she wish to take the snapshot and/or backup, and how many snapshots/backups needs to be retains, then Longhorn will automatically create snapshot/backup for the user at that time, as long as the volume is attached to a node.

Users can setup recurring snapshot/backup via Longhorn UI, or Kubernetes StorageClass.

## Set up recurring jobs using Longhorn UI

User can find the setting for the recurring snapshot and backup in the `Volume Detail` page.

## Set up recurring jobs using StorageClass

Users can set field `recurringJobs` in StorageClass as parameters. Any future volumes created using this StorageClass will have those recurring jobs automatically set up.

Field `recurringJobs` should follow JSON format. e.g.

```
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: longhorn
provisioner: driver.longhorn.io
parameters:
  numberOfReplicas: "3"
  staleReplicaTimeout: "30"
  fromBackup: ""
  recurringJobs: '[{"name":"snap", "task":"snapshot", "cron":"*/1 * * * *", "retain":1},
                   {"name":"backup", "task":"backup", "cron":"*/2 * * * *", "retain":1}]'

```

Explanation:

1. `name`: Name of one job. Do not use duplicate name in one `recurringJobs`. And the length of `name` should be no more than 8 characters.

2. `task`: Type of one job. It supports `snapshot` (periodically create snapshot) or `backup` (periodically create snapshot then do backup) only.

3. `cron`: Cron expression. It tells execution time of one job.

4. `retain`: How many snapshots/backups Longhorn will retain for one job. It should be no less than 1.
