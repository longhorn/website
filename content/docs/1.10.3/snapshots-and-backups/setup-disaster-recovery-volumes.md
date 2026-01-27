---
title: Disaster Recovery (DR) Volumes
weight: 4
---

Ensuring data resilience is important when working with containerized applications.
A **Longhorn Disaster Recovery (DR) volume** is a special type of volume designed to maintain a standby copy of data in a secondary Kubernetes cluster. It is created from backups of a primary volume and kept in sync to enable rapid recovery if the primary cluster becomes unavailable.

The DR volume stores a geographically separated replica of the data. The backup frequency determines how current the DR volume is and, consequently, the potential amount of data loss in the event of a site failure.

## How It Works

The functionality of DR volumes relies on asynchronous replication through a shared backup store.

- **Shared Backup Target**

    Your primary and secondary Kubernetes clusters must be configured to use the exact same external backup target (e.g., an S3-compatible object store or an NFS share).

- **Incremental Backup and Restore**

    A DR volume is created from an existing backup. It continuously polls the backup target for newer backups from the source volume and restores them incrementally. The `Last Backup` field in the UI shows the most recent backup that has been restored.

    To keep the DR volume updated, configure recurring jobs on the source volume to perform regular incremental backups. These recurring backups provide the DR volume with new backups to restore, helping ensure minimal data loss in the event of a disaster.

- **Standby State**

    The DR volume remains in a passive standby state. It is not mounted or accessible by any workloads, which prevents data inconsistencies. The UI indicates the volume’s status with an icon:

    - Gray Icon: The volume is busy restoring data and cannot be activated.
    - Blue Icon: The volume is fully synchronized and ready for activation.

- **Activation**

    In a disaster, you manually activate the DR volume. This process converts it into a standard, writable Longhorn volume that can be attached to your applications in the recovery cluster.

## Creating a DR Volume

You can create a DR volume using either the Longhorn UI or `kubectl`.

> **Prerequisites**: Set up two Kubernetes clusters. These will be called cluster A and cluster B. Install Longhorn on both clusters, and set the same backup target on both clusters. For help setting the backup target, refer to [this page.](../backup-and-restore/set-backup-target)

### Using Longhorn UI

1. In your primary cluster, ensure the source volume has at least one backup.
2. In the Longhorn UI of your secondary (recovery) cluster, navigate to the Backup page.
3. Select the desired backup from the list and choose Create Disaster Recovery Volume. It is recommended to use the same name as the original volume.
4. Longhorn will create the volume, which will appear on the Volume page with a Standby status.

### Using `kubectl` Command

1. **Get the Backup URL**: First, copy the full URL of the source backup from the Backup page in the Longhorn UI. The format of this URL will depend on your configured backup target (e.g., S3, NFS).

2. **Create a YAML Manifest**: Create a file (e.g., dr-volume.yaml) with the following content. Be sure to replace the placeholder URL and adjust the name, size, accessMode, etc. to match your source volume. In this file, the `standby: true` field defines the volume as a DR standby volume.

    ```yaml
    apiVersion: longhorn.io/v1beta2
    kind: Volume
    metadata:
      name: example-dr-volume
      namespace: longhorn-system
    spec:
      size: "2147483648"
      accessMode: rwo
      numberOfReplicas: 3
      fromBackup: "nfs://longhorn-nfs-server.example.com:/opt/backupstore?backup=backup-b69a1249e97f4a27&volume=pvc-33509786-92d7-427c-9b5a-b6d61d56b063"
      # This flag is essential to create a standby volume
      Standby: true
    ```

3. **Apply the Manifest**: Apply the manifest to your **secondary cluster** to create the volume.

## Activating a DR Volume

When a failover is necessary, you must activate the DR volume to make it writable.  
Longhorn supports activation under the following conditions:

- The volume is healthy, indicating that all replicas are in a healthy state.
- The volume is degraded (some replicas have failed), but only if the global setting [`Allow Volume Creation with Degraded Availability`](../../references/settings/#allow-volume-creation-with-degraded-availability) is enabled.

> **Note**: When the setting `Allow Volume Creation with Degraded Availability` is disabled, attempting to activate a degraded DR volume will cause the volume to become stuck in the `Attached` state.  
> After enabling the setting, the DR volume will be activated and converted into a normal volume, remaining in the `Detached` state.

### Using Longhorn UI

1. Go to the `Volumes` page in the Longhorn UI of your secondary cluster.
2. Select the DR volume you want to activate.
3. Click the `Activate Disaster Recovery Volume` button in the **Operation** dropdown menu.
4. The volume will transition to the `Detached` state, and you can attach it with your workloads.

### Using `kubectl` Command

1. Run the following command to activate the DR volume and update the frontend:

    ```bash
    kubectl patch volume example-dr-volume1 -n longhorn-system --type='json' -p='[
      {"op": "replace", "path": "/spec/Standby", "value": false},
      {"op": "replace", "path": "/spec/frontend", "value": "blockdev"}
    ]'
    ```

2. The volume will transition to the `Detached` state, and you can attach it with your workloads.

## Limitations

Since the primary purpose of a DR volume is to restore data from backups, the following actions are not supported until the volume is activated:

- Creating, deleting, or reverting snapshots
- Creating backups
- Creating persistent volumes (PVs)
- Creating persistent volume claims (PVCs)
