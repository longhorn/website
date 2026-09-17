---
title: Restore from a Backup
weight: 3
---

Longhorn can easily restore backups to a volume.

For more information on how backups work, refer to the [concepts](../../../concepts/#3-backups-and-secondary-storage) section.

When you restore a backup, it creates a volume of the same name by default. If a volume with the same name as the backup already exists, the backup will not be restored.

### Restore via Longhorn UI

1.  Navigate to the **Backup** menu.
2.  Select the backup(s) you wish to restore and click **Restore Latest Backup**.
3.  In the **Name** field, select the volume name you wish to create.
4.  Click **OK**.

You can then create the PV/PVC from the volume after restoring a volume from a backup. Here you can specify the `storageClassName` or leave it empty to use the `storageClassName` inherited from the PVC of the backup volume. The `StorageClass` should already be in the cluster to prevent any further issues.

### Restore via Custom Resource (CLI)

#### 1. Identify the Backup to Restore

List the available backups to find the name of the backup you wish to restore:

```bash
kubectl get backups.longhorn.io -n longhorn-system
```

#### 2. Retrieve Backup Details

You must obtain the exact **Backup URL** and the **Volume Size** (in bytes) from the `status` of the Backup CR:

```bash
# Get the Backup URL
kubectl get backup.longhorn.io <BACKUP-NAME> -n longhorn-system -o jsonpath='{.status.url}'

# Get the Volume Size (in bytes)
kubectl get backup.longhorn.io <BACKUP-NAME> -n longhorn-system -o jsonpath='{.status.volumeSize}'
```

#### 3. Create the Volume Manifest

Apply a `Volume` manifest using the details retrieved above.

> **Important**:  
> The `size` field must be the exact byte count provided by the backup status, wrapped in **double quotes** (e.g., `"1073741824"`). Using Kubernetes quantities like `1Gi` or raw integers without quotes will result in an admission webhook error.

```yaml
apiVersion: longhorn.io/v1beta2
kind: Volume
metadata:
  name: restored-volume-name
  namespace: longhorn-system
spec:
  size: "1073741824" # Must be the exact byte count as a string
  fromBackup: "s3://longhorn-backupstore@us-east-1/?backup=backup-123&volume=pvc-456"
  numberOfReplicas: 3
  frontend: blockdev
  dataEngine: v1
```

#### 4. Monitor Restore Progress

Before attaching the volume to a workload, verify that the restoration is complete. The volume `state` should be `detached` and `restoreRequired` should be `false`.

```bash
kubectl get volume restored-volume-name -n longhorn-system -o jsonpath='{.status.restoreRequired}'
```

#### 5. Manually Bind the PV and PVC

Unlike the UI method, restoring via CR requires you to manually create the `PersistentVolume` (PV) and `PersistentVolumeClaim` (PVC). The `volumeHandle` in the PV **must** match the `metadata.name` of the `Volume` CR.

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: restored-pv
spec:
  capacity:
    storage: 1Gi # Matches the volume size
  volumeMode: Filesystem
  accessModes: [ReadWriteOnce]
  storageClassName: longhorn
  csi:
    driver: driver.longhorn.io
    volumeHandle: restored-volume-name # Matches Volume CR Name
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: restored-pvc
  namespace: default
spec:
  accessModes: [ReadWriteOnce]
  resources:
    requests:
      storage: 1Gi
  volumeName: restored-pv
  storageClassName: longhorn
```

**Result**: The restored volume is bound to a PVC and ready for use by your applications.
