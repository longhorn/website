---
title: Important Notes
weight: 1
---

This page lists important notes for Longhorn v{{< current-version >}}.
Please see [here](https://github.com/longhorn/longhorn/releases/tag/v{{< current-version >}}) for the full release note.

- [Deprecation](#deprecation)
  - [Environment Check Script](#environment-check-script)
- [Breaking Change](#breaking-change)
  - [V2 Backing Image](#v2-backing-image)
- [General](#general)
  - [Kubernetes Version Requirement](#kubernetes-version-requirement)
  - [CRD Upgrade Validation](#crd-upgrade-validation)
  - [Upgrade Check Events](#upgrade-check-events)
  - [Manual Checks Before Upgrade](#manual-checks-before-upgrade)
  - [Install/Upgrade with Helm Controller](#installupgrade-with-helm-controller)
  - [Automatic Expansion of RWX Volumes](#automatic-expansion-of-rwx-volumes)
- [Resilience](#resilience)
  - [Change in Engine Replica Timeout Behavior](#change-in-engine-replica-timeout-behavior)
  - [Talos Linux](#talos-linux)
- [Backup](#backup)
  - [Multiple Backupstores Support](#multiple-backupstores-support)
  - [Backup Data On The Remote Backup Server Might Be Deleted](#backup-data-on-the-remote-backup-server-might-be-deleted)
- [System Backup And Restore](#system-backup-and-restore)
  - [Volume Backup Policy](#volume-backup-policy)
- [V2 Data Engine](#v2-data-engine)
  - [Longhorn System Upgrade](#longhorn-system-upgrade)
  - [Change the Block Size of the Block-Type Disk using AIO Driver to 512 bytes](#change-the-block-size-of-the-block-type-disk-using-aio-driver-to-512-bytes)
  - [Resolved Potential Volume and Backup Data Corruption Issue](#resolved-potential-volume-and-backup-data-corruption-issue)
  - [Support for Configurable CPU Cores](#support-for-configurable-cpu-cores)
  - [Newly Introduced Functionalities since Longhorn v1.8.0](#newly-introduced-functionalities-since-longhorn-v180)
    - [Scheduling](#scheduling)
    - [Data Recovery](#data-recovery)
    - [Backing Image](#backing-image)
    - [Migration](#migration)
    - [Security](#security)

## Deprecation

### Environment Check Script

The functionality of the [environment check script](https://github.com/longhorn/longhorn/blob/master/scripts/environment_check.sh) (`environment_check.sh`) overlaps with that of the Longhorn CLI, which is available starting with v1.7.0. Because of this, the script is deprecated in v1.7.0 and is scheduled for removal in v1.9.0.

## Breaking Change

### V2 Backing Image

Starting with Longhorn v1.8.2, V2 backing images are incompatible with earlier versions due to naming conflicts in the extended attributes (`xattrs`) used by SPDK backing image logical volumes. As a result, V2 backing images must be deleted and recreated during the upgrade process. Since backing images cannot be deleted while volumes using them still exist, you must first back up, delete, and later restore those volumes as the following steps:

- Before upgrading to v1.8.2:
  - Verify that backup targets are functioning properly.
  - Create full backups of all volumes that use a V2 backing image.
  - Detach and delete these volumes after the backups complete.
  - In the **Backing Image** page, save the specifications of all V2 backing images, including the name and the image source.
  - Delete all V2 backing images.
- After upgrading:
  - Recreate the V2 backing images using the same names and image sources.
  - Restore the volumes from your backups.

For more details, see [Issue #10805](https://github.com/longhorn/longhorn/issues/10805) and [Issue #10969](https://github.com/longhorn/longhorn/issues/10969).

## General

### Kubernetes Version Requirement

Due to the upgrade of the CSI external snapshotter to version v8.2.0, ensure that all clusters are running Kubernetes v1.25 or later before upgrading to Longhorn v1.8.0 or any newer version.

### CRD Upgrade Validation

During the upgrade process, the Custom Resource Definition (CRD) may be applied after the new Longhorn manager has started. This sequencing ensures that the controller does not process objects with deprecated data or fields. However, this can result in the Longhorn manager failing during the initial upgrade phase if the CRD has not been applied yet.

If the Longhorn manager crashes during the upgrade, check the logs to determine if the failure is due to the CRD not being applied. In such cases, the logs may contain error messages similar to the following:

```
time="2025-03-27T06:59:55Z" level=fatal msg="Error starting manager: upgrade resources failed: BackingImage in version \"v1beta2\" cannot be handled as a BackingImage: strict decoding error: unknown field \"spec.diskFileSpecMap\", unknown field \"spec.diskSelector\", unknown field \"spec.minNumberOfCopies\", unknown field \"spec.nodeSelector\", unknown field \"spec.secret\", unknown field \"spec.secretNamespace\"" func=main.main.DaemonCmd.func3 file="daemon.go:94"
```

### Upgrade Check Events
Longhorn performs a pre-upgrade check when upgrading with Helm or Rancher App Marketplace.  If a check fails, the upgrade will stop and the reason for the check's failure will be recorded in an event.  For more detail, see [Upgrading Longhorn Manager](../deploy/upgrade/longhorn-manager).

### Manual Checks Before Upgrade
Automated checks are only performed on some upgrade paths, and the pre-upgrade checker may not cover some scenarios.  Manual checks, performed using either kubectl or the UI, are recommended for these schenarios.  You can take mitigating actions or defer the upgrade until issues are addressed.
- Ensure that all V2 Data Engine volumes are detached and the replicas are stopped.  The V2 Data Engine currently does not support live upgrades.
- Avoid upgrading when volumes are in the "Faulted" status.  If all the replicas are deemed unusable, they may be deleted and data may be permanently lost (if no usable backups exist).
- Avoid upgrading if a failed BackingImage exists.  For more information, see [Backing Image](../advanced-resources/backing-image/backing-image).
- It is recommended to create a [Longhorn system backup](../advanced-resources/system-backup-restore/backup-longhorn-system) before performing the upgrade. This ensures that all critical resources, such as volumes and backing images, are backed up and can be restored in case any issues arise.

### Install/Upgrade with Helm Controller
Longhorn also supports installation or upgrade via the HelmChart controller built into RKE2 and K3s.  It allows management in a CRD YAML chart of most of the options that would normally be passed to the `helm` command-line tool. For more details on how it works, see [Install with Helm Controller](../deploy/install/install-with-helm-controller).

### Automatic Expansion of RWX Volumes
In v1.8.0, Longhorn supports fully automatic online expansion of RWX volumes.  There is no need to scale down the workload or apply manual commands.  Full details are in [RWX Volume](../nodes-and-volumes/volumes/expansion/#rwx-volume)

## Resilience

### Change in Engine Replica Timeout Behavior

In versions earlier than v1.8.0, the [Engine Replica Timeout](../references/settings#engine-replica-timeout) setting
was equally applied to all V1 volume replicas. In v1.8.0, a V1 engine marks the last active replica as failed only after
twice the configured number of seconds (timeout value x 2) have passed.

### Talos Linux

Longhorn v1.8.0 and later versions support usage of V2 volumes in Talos Linux clusters. To use V2 volumes, ensure that all nodes meet the V2 Data Engine prerequisites. For more information, see [Talos Linux Support: V2 Data Engine](../advanced-resources/os-distro-specific/talos-linux-support#v2-data-engine).

## Backup

### Multiple Backupstores Support

Starting with v1.8.0, Longhorn supports usage of multiple backupstores. You can configure backup targets to access backupstores on the **Setting/Backup Target** page of the Longhorn UI. v1.8.0 improves on earlier Longhorn versions, which only allow you to use a single backup target for accessing a backupstore. Earlier versions also require you to configure the settings `backup-target`, `backup-target-credential-secret`, and `backupstore-poll-interval` for backup target management.

> **IMPORTANT:**  
> The settings `backup-target`, `backup-target-credential-secret`, and `backupstore-poll-interval` were removed from the global settings because backup targets can be configured on the **Setting/Backup Target** page of the Longhorn UI. Longhorn also creates a default backup target (`default`) during installation and upgrades.

Longhorn creates a default backup target (`default`) during installation and upgrades. The default backup target is used for the following:

- System backups
- Volumes that were created without a specific backup target name

> **Tip:**
> Set the [default backup target](../snapshots-and-backups/backup-and-restore/set-backup-target#default-backup-target) before creating a new one.

For more information, see [Setting a Backup Target](../snapshots-and-backups/backup-and-restore/set-backup-target), [Issue #5411](https://github.com/longhorn/longhorn/issues/5411) and [Issue #10089](https://github.com/longhorn/longhorn/issues/10089).

### Backup Data On The Remote Backup Server Might Be Deleted

Earlier Longhorn versions may unintentionally delete data in the backupstore and backup-related custom resources (such as `BackupVolume`, `BackupBackingImage`, `SystemBackup`, and `Backup`) in the following scenarios:

- An empty response from the NFS server due to server downtime.
- A race condition could delete the remote backup volume and its corresponding backups when the backup target is reset within a short period.

Starting with v1.8.0, Longhorn handles backup-related custom resources in the following manner:

- If there are discrepancies between the backup information in the cluster and in the backupstore, Longhorn deletes only the backup-related custom resources in the cluster.
- The backup-related custom resources in the cluster may be deleted unintentionally while the remote backup data remains safely stored. The deleted resources are resynchronized from the remote backup server during the next polling period (if the backup target is available).

For more information, see [#9530](https://github.com/longhorn/longhorn/issues/9530).

## System Backup And Restore

### Volume Backup Policy

Since Longhorn v1.8.0, the `if-not-present` volume backup policy now ensures the latest backup contains the most recent data. If the latest backup is outdated, Longhorn will create a new backup for the volume.

For more information, see [#6027](https://github.com/longhorn/longhorn/issues/6027).

## V2 Data Engine

### Longhorn System Upgrade

Longhorn currently does not support live upgrading of V2 volumes. Ensure that all V2 volumes are detached before initiating the upgrade process.

### Change the Block Size of the Block-Type Disk using AIO Driver to 512 bytes

The default block size for block-type disks was 4096 bytes prior to v1.8.0. However, a 512-byte block size is more commonly used and aligns with the v1 data engine's configuration. Additionally, the 4096-byte block size is incompatible with backing images generated by the v1 data engine. To address this, the default block size has been changed to 512 bytes.

For existing v2 volumes, users can update their setup by following these steps:

- Back up the current v2 volumes.
- Remove the v2 volumes.
- Delete the block-type disk with a 4096-byte block size from `node.spec.disks`.
- Erase the old data on the block-type disk using tools such as `dd`.
- Re-add the disk to `node.spec.disks` with the updated configuration.
- Restore the v2 volumes.

For more information, see [#10053](https://github.com/longhorn/longhorn/issues/10053).

### Resolved Potential Volume and Backup Data Corruption Issue

A data corruption [issue](https://github.com/longhorn/longhorn/issues/10135) that affects earlier Longhorn releases has been resolved in v1.8.0. The issue involves potential continual changes to the checksum of files in a V2 volume with multiple replicas. This occurs because SPDK allocates clusters without initialization, leading to data inconsistencies across replicas. The varying data read from the volume can result in data corruption and broken backups. 

### Support for Configurable CPU Cores

Longhorn v1.8.0 supports [configurable CPU cores](../v2-data-engine/features/configurable-cpu-cores) for the V2 Data Engine. The global and node-specific configuration options provide greater control and flexibility for optimizing performance and resource allocation.

### Newly Introduced Functionalities since Longhorn v1.8.0

#### Scheduling

- [Data locality](https://github.com/longhorn/longhorn/issues/9371)

#### Data Recovery

- [Disaster Recovery Volumes](https://github.com/longhorn/longhorn/issues/6613)
- [Auto-Salvage Volumes](https://github.com/longhorn/longhorn/issues/8430)
- [Delta replica rebuilding using snapshot checksum](https://github.com/longhorn/longhorn/issues/9488)

#### Backing Image

- Upload
- Download

For more information, see [#6341](https://github.com/longhorn/longhorn/issues/6341).

#### Migration

- [Live Migration](https://github.com/longhorn/longhorn/issues/6361)

#### Security

- [Volume Encryption](https://github.com/longhorn/longhorn/issues/7355)
