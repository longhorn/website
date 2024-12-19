---
title: Important Notes
weight: 1
---

This page lists important notes for Longhorn v{{< current-version >}}.
Please see [here](https://github.com/longhorn/longhorn/releases/tag/v{{< current-version >}}) for the full release note.

- [Deprecation](#deprecation)
  - [Environment Check Script](#environment-check-script)
- [General](#general)
  - [Minimum Kubernetes Supported](#minimum-kubernetes-supported)
  - [Upgrade Check Events](#upgrade-check-events)
  - [Install/Upgrade with Helm Controller](#installupgrade-with-helm-controller)
  - [Automatic Expansion of RWX Volumes](#automatic-expansion-of-rwx-volumes)
- [Resilience](#resilience)
  - [Change in Engine Replica Timeout Behavior](#change-in-engine-replica-timeout-behavior)
  - [Talos Linux](#talos-linux)
- [Backup](#backup)
  - [Backup Data On The Remote Backup Server Might Be Deleted](#backup-data-on-the-remote-backup-server-might-be-deleted)
- [System Backup And Restore](#system-backup-and-restore)
  - [Volume Backup Policy](#volume-backup-policy)
- [V2 Data Engine](#v2-data-engine)
  - [Longhorn System Upgrade](#longhorn-system-upgrade)
  - [Disaster Recovery Volumes](#disaster-recovery-volumes)
  - [Auto-salvage Volumes](#auto-salvage-volumes)

## Deprecation

### Environment Check Script

The functionality of the [environment check script](https://github.com/longhorn/longhorn/blob/master/scripts/environment_check.sh) (`environment_check.sh`) overlaps with that of the Longhorn CLI, which is available starting with v1.7.0. Because of this, the script is deprecated in v1.7.0 and is scheduled for removal in v1.9.0.

## General

### Minimum Kubernetes Supported

Please ensure your Kubernetes cluster is at least v1.25 before upgrading to Longhorn v{{< current-version >}} because this is the minimum version Longhorn v{{< current-version >}} supports.

### Upgrade Check Events

Longhorn performs a pre-upgrade check when upgrading with Helm or Rancher App Marketplace.  If a check fails, the upgrade will stop and the reason for the check's failure will be recorded in an event.  For more detail, see [Upgrading Longhorn Manager](../deploy/upgrade/longhorn-manager).

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

### Backup Data On The Remote Backup Server Might Be Deleted

Longhorn may unintentionally delete backup-related custom resources (such as `BackupVolume`, `BackupBackingImage`, `SystemBackup`, and `Backup`) and backup data on the remote backup server before Longhorn v{{< current-version >}} in the following scenarios:

- An empty response from the NFS server due to server downtime.
- A race condition could delete the remote backup volume and its corresponding backups when the backup target is reset within a short period.

Starting with v{{< current-version >}}, Longhorn handles backup-related custom resources in the following manner:

- If there are discrepancies between the backup information in the cluster and on the remote backup server, Longhorn deletes only the backup-related custom resources in the cluster.
- The backup-related custom resources in the cluster may be deleted unintentionally while the remote backup data remains safely stored. The deleted resources are resynchronized from the remote backup server during the next polling period (if the backup target is available).

For more information, see [#9530](https://github.com/longhorn/longhorn/issues/9530).

## System Backup And Restore

### Volume Backup Policy

Since Longhorn v1.8.0, the `if-not-present` volume backup policy now ensures the latest backup contains the most recent data. If the latest backup is outdated, Longhorn will create a new backup for the volume.

## V2 Data Engine

### Longhorn System Upgrade

Longhorn currently does not support live upgrading of V2 volumes. Ensure that all V2 volumes are detached before initiating the upgrade process.

### Disaster Recovery Volumes

Disaster recovery volumes are supported from Longhorn v1.8.0.

### Auto-salvage Volumes

Auto-salvage volumes are supported from Longhorn v1.8.0.
