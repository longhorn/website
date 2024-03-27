---
title: Restore Volume Recurring Jobs from a Backup
weight: 5
---

Since v1.4.0, Longhorn supports recurring jobs backup and restore along with the volume backup and restore. When restoring a backup volume, if users enable the `Restore Volume Recurring Jobs` setting, the original recurring jobs of the volume will be restored back accordingly.

For more information on the setting `Restore Volume Recurring Jobs`, refer to the [settings](../../../references/settings/#restore-volume-recurring-jobs) section.

For more information on how volume backup works, refer to the [concepts](../../../concepts/#3-backups-and-secondary-storage) section.

When restoring a volume with recurring jobs, Longhorn will restore them together. If the volume name already exists, the volume and the recurring jobs will not be restored.  If the recurring job name already exists but the spec is different, the restoring recurring job will be created with a randomly generated name to avoid conflict. Otherwise, Longhorn will try to reuse existing recurring jobs instead if they are the same as restoring recurring jobs of a backup volume.

By default, Longhorn will not automatically restore volume recurring jobs, users can enable the automatic restoration by Longhorn UI or kubectl.

## Via Longhorn UI

1. Navigate to the **Setting** menu and click **General**
2. Enable the `Restore Volume Recurring Jobs`
3. Navigate to the **Backup** menu
4. Select the backup(s) you wish to restore and click **Restore Latest Backup.**
5. In the **Name** field, select the volume you wish to restore.
6. Click **OK**

## Via Command Line

```bash
# kubectl -n longhorn-system edit settings.longhorn.io restore-volume-recurring-jobs
```

Then, set the value to `true`.

```text
# kubectl -n longhorn-system get setting restore-volume-recurring-jobs
NAME                            VALUE   AGE
restore-volume-recurring-jobs   false   28m
```

### Example of Volume Specific Setting

```yaml
apiVersion: longhorn.io/v1beta2
kind: Volume
metadata:
  labels:
    longhornvolume: vol-01
  name: vol-01
  namespace: longhorn-system
spec:
  restoreVolumeRecurringJob: ignored
  engineImage: longhornio/longhorn-engine:v1.4.0
  fromBackup: "s3://backupbucket@us-east-1?volume=minio-vol01&backup=backup-eeb2782d5b2f42bb"
  frontend: blockdev
```

Users can override the setting `restore-volume-recurring-jobs` by the volume spec property  `spec.restoreVolumeRecurringJob`.

- **ignored**. This is the default option that instructs Longhorn to inherit from the global setting.
- **enabled**. This option instructs Longhorn to restore volume recurring jobs from the backup target forcibly.
- **disabled**. This option instructs Longhorn no restoring volume recurring jobs should be done.

**Result:** The restored volume recurring jobs are available on the **RecurringJob** page.
