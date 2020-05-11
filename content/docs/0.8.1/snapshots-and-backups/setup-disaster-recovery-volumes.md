---
title: Creating and Activating Disaster Recovery Volumes
description: Help and potential gotchas associated with specific cloud providers.
weight: 4
---

A **disaster recovery (DR) volume** is a special volume that is mainly intended to store data in a backup cluster in case the whole main cluster goes down.

To increase the resiliency of Longhorn volumes, DR volumes are created in a secondary Kubernetes cluster, and they are incrementally updated from the latest backup of a Longhorn volume from a primary Kubernetes cluster.

For a longer explanation of how DR volumes work, see the [concepts section.](../../concepts/#disaster-recovery-volumes)

> **Note:** The `Backup Target` in Settings cannot be updated if any DR volumes exist.

## Creating DR Volumes

> **Prerequisites:** The steps to create a DR volume assume that you have done the following:
>
>    1. You have set up two Kubernetes clusters. These will be called Cluster A and Cluster B.
>    2. Longhorn is installed on both clusters.
>    3. The same [backup target has been configured](../backup-and-restore/set-backup-target) for Longhorn on both clusters.
>    4. You have [created a volume](../../volumes-and-nodes/create-volumes) on Cluster A. This will be called Volume X.
>    5. You have [created a backup](../backup-and-restore/create-a-backup) of this volume. This backup will be used to a create a DR volume on Cluster B.

To create a DR volume from Volume X, follow these steps:

1. In the Longhorn UI for Cluster B, click the **Backup** tab.
2. Select the table row for Volume X, then click **Create Disaster Recovery Volume.** It's highly recommended to use the backup volume name as the DR volume name.
3. Longhorn will automatically attach the DR volume Y to a random node.

**Result:** The DR volume is created. Longhorn will start polling for the last backup of Volume X, and incrementally restore it to the DR volume.

## Activating DR Volumes

Because the main purpose of a DR volume is to restore data from backup, this type of volume doesn't support the following actions before it is activated:

- Creating, deleting, and reverting snapshots
- Creating backups
- Creating persistent volumes
- Creating persistent volume claims

To activate the DR volume,

1. Go to the Longhorn UI in your backup cluster where the DR volume is located. Click the **Volume** tab.
2. Go to the DR volume. In the **Operations** column, click the three-line dropdown menu, and click **Activate Disaster Recovery Volume.**
3. For the type of volume, select blockdev if you want to use it directly with Longhorn CSI driver and Kubernetes. Choose the iSCSI option if you want to manually configure Kubernetes to use iSCSI to access the Longhorn volume.
4. Click **OK.**

**Result:** Longhorn will make sure the DR volume is updated to reflect the most recent backup of its original backup volume, then activate the volume.

For DR volumes, `Last Backup` indicates the most recent backup of its original backup volume.

If the icon representing the DR volume is gray, it means the volume is restoring the Last Backup and users cannot activate this volume right now; if the icon is blue, it means the volume has restored the Last Backup.

After a DR volume is activated, it becomes the same as a normal Longhorn volume, and it cannot be deactivated.