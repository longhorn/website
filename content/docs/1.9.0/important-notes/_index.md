---
title: Important Notes
weight: 1
---

This page lists important notes for Longhorn v{{< current-version >}}.
Please see [here](https://github.com/longhorn/longhorn/releases/tag/v{{< current-version >}}) for the full release note.

- [Warning](#warning)
- [Removal](#removal)
  - [Environment Check Script](#environment-check-script)
  - [Orphan-Auto-Deletion Setting](#orphan-auto-deletion-setting)
  - [Deprecated Fields in `longhorn.io/v1beta2` CRDs](#deprecated-fields-in-longhorniov1beta2-crds)
- [Deprecation](#deprecation)
  - [`longhorn.io/v1beta1` API](#longhorniov1beta1-api)
- [Breaking Change](#breaking-change)
  - [V2 Backing Image](#v2-backing-image)
- [General](#general)
  - [Kubernetes Version Requirement](#kubernetes-version-requirement)
  - [CRD Upgrade Validation](#crd-upgrade-validation)
  - [Upgrade Check Events](#upgrade-check-events)
  - [Manual Checks Before Upgrade](#manual-checks-before-upgrade)
- [Backup And Restore](#backup-and-restore)
  - [Recurring System Backup](#recurring-system-backup)
- [Replica Rebuilding](#replica-rebuilding)
  - [Offline Replica Rebuilding](#offline-replica-rebuilding)
- [Resilience](#resilience)
  - [Orphaned Instance Deletion](#orphaned-instance-deletion)
- [Performance](#performance)
  - [Snapshot Checksum Disabled for Single-Replica Volumes](#snapshot-checksum-disabled-for-single-replica-volumes)
- [Observability](#observability)
  - [Improved Metrics for Replica, Engine, and Rebuild Status](#improved-metrics-for-replica-engine-and-rebuild-status)
- [V2 Data Engine](#v2-data-engine)
  - [Longhorn System Upgrade](#longhorn-system-upgrade)
  - [Newly Introduced Functionalities since Longhorn v1.9.0](#newly-introduced-functionalities-since-longhorn-v190)
    - [Performance Enhancement](#performance-enhancement)
    - [Rebuilding](#rebuilding)
    - [Networking](#networking)

## Warning

The longhorn-manager v1.9.0 is impacted by a [regression issue](https://github.com/longhorn/longhorn/issues/11016), which causes failures of recurring jobs. To resolve this issue, replace `longhorn-manager:v1.9.0` with the hotfixed image `longhorn-manager:v1.9.0-hotfix-1`.

You can apply the update in one of the following ways:

- **Helm or Deployment Manifest**:
  Update the `longhorn-manager` image from `v1.9.0` to `v1.9.0-hotfix-1`, then perform an upgrade.

## Removal

### Environment Check Script

The environment check script (`environment_check.sh`), which was deprecated in v1.7.0, has been removed from v1.9.0. Use the [Longhorn Command Line Tool](../advanced-resources/longhornctl/) to check the Longhorn environment for potential issues.

### Orphan-Auto-Deletion Setting

The `orphan-auto-deletion` setting has been replaced by `orphan-resource-auto-deletion` in v1.9.0. To replicate the previous behavior, include `replica-data` in the `orphan-resource-auto-deletion` value. During the upgrade, the original `orphan-auto-deletion` setting is automatically migrated.

For more information, see [Orphaned Data Cleanup](../advanced-resources/data-cleanup/orphaned-data-cleanup) and [Orphaned Instance Cleanup](../advanced-resources/data-cleanup/orphaned-instance-cleanup).

### Deprecated Fields in `longhorn.io/v1beta2` CRDs

Deprecated fields have been removed from the CRDs. For details, see [#6684](https://github.com/longhorn/longhorn/issues/6684).

## Deprecation

### `longhorn.io/v1beta1` API

The `v1beta1` version of the Longhorn API is marked unserved and unsupported in v1.9.0 and will be removed in v1.10.0.

For more details, see [Issue #10250](https://github.com/longhorn/longhorn/issues/10250).

## Breaking Change

### V2 Backing Image

Starting with Longhorn v1.9.0, V2 backing images are incompatible with earlier versions due to naming conflicts in the extended attributes (`xattrs`) used by SPDK backing image logical volumes. As a result, V2 backing images must be deleted and recreated during the upgrade process. Since backing images cannot be deleted while volumes using them still exist, you must first back up, delete, and later restore those volumes as the following steps:

- Before upgrading to v1.9.0:
  - Verify that backup targets are functioning properly.
  - Create full backups of all volumes that use a V2 backing image.
  - Detach and delete these volumes after the backups complete.
  - In the **Backing Image** page, save the specifications of all V2 backing images, including the name and the image source.
  - Delete all V2 backing images.
- After upgrading:
  - Recreate the V2 backing images using the same names and image sources.
  - Restore the volumes from your backups.

For more details, see [Issue #10805](https://github.com/longhorn/longhorn/issues/10805).

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

- Ensure that all V2 Data Engine volumes are detached and the replicas are stopped. The V2 Data Engine currently does not support live upgrades.
- Avoid upgrading when volumes are in the "Faulted" status.  If all the replicas are deemed unusable, they may be deleted and data may be permanently lost (if no usable backups exist).
- Avoid upgrading if a failed BackingImage exists.  For more information, see [Backing Image](../advanced-resources/backing-image/backing-image).
- It is recommended to create a [Longhorn system backup](../advanced-resources/system-backup-restore/backup-longhorn-system) before performing the upgrade. This ensures that all critical resources, such as volumes and backing images, are backed up and can be restored in case any issues arise.

## Backup And Restore

### Recurring System Backup

Starting with Longhorn v1.9.0, you can create a recurring job for system backup creation.

For more information, see [#6534](https://github.com/longhorn/longhorn/issues/6534)

## Replica Rebuilding

### Offline Replica Rebuilding

Longhorn introduces offline replica rebuilding, a feature that allows degraded volumes to automatically recover replicas even while the volume is detached. This capability minimizes the need for manual recovery steps, accelerates restoration, and ensures high data availability. By default, offline replica rebuilding is disabled. To enable it, set the `offline-replica-rebuilding` setting to `true` in the Longhorn UI or CLI.

For more information, see [Offline replica rebuilding](../advanced-resources/rebuilding/offline-replica-rebuilding) and [#8443](https://github.com/longhorn/longhorn/issues/8443).

## Resilience

### Orphaned Instance Deletion

Longhorn can now track and remove orphaned instances, which are leftover resources like replicas or engines that are no longer associated with an active volume. These instances may accumulate due to unexpected failures or incomplete cleanup.

To reduce resource usage and maintain system performance, Longhorn supports both automatic and manual cleanup. By default, this feature is disabled. To enable it, set the `orphan-resource-auto-deletion` setting to `instance` in the Longhorn UI or CLI.

For more information, see [#6764](https://github.com/longhorn/longhorn/issues/6764).

## Performance

### Snapshot Checksum Disabled for Single-Replica Volumes

Starting with v1.9.0, Longhorn won't calculate snapshot checksums by default for single-replica v1 volumes. Since snapshot checksums are primarily used for ensuring data integrity and speeding up replica rebuilding, they are unnecessary in single-replica setups and disabling them helps reduce performance overhead.

For more information, see [#10518](https://github.com/longhorn/longhorn/issues/10518).

## Observability

### Improved Metrics for Replica, Engine, and Rebuild Status

Longhorn improves observability with new Prometheus metrics that expose the status and identity of Replica and Engine CRs, along with rebuild activity. These metrics make it easier to monitor rebuilds across the cluster.

For more information, see [#10550](https://github.com/longhorn/longhorn/issues/10550) and [#10722](https://github.com/longhorn/longhorn/issues/10722).

## V2 Data Engine

### Longhorn System Upgrade

Longhorn currently does not support live upgrading of V2 volumes. Ensure that all V2 volumes are detached before initiating the upgrade process.

### Newly Introduced Functionalities since Longhorn v1.9.0

#### Performance Enhancement

- [Support UBLK Frontend](../v2-data-engine/features/ublk-frontend-support): Support for UBLK frontend in the V2 Data Engine, which allows for better performance and resource utilization.

#### Rebuilding

- [Offline Replica Rebuilding](../advanced-resources/rebuilding/offline-replica-rebuilding): Support for offline replica rebuilding, which allows degraded volumes to automatically recover replicas even while the volume is detached. This capability ensures high data availability without manual intervention.

#### Networking

- [Storage Network](https://github.com/longhorn/longhorn/issues/6450): Introduces support for storage networks in the V2 Data Engine to allow network segregation.
