---
title: Important Notes
weight: 1
---

This page lists important notes for Longhorn v{{< current-version >}}.
Please see [here](https://github.com/longhorn/longhorn/releases/tag/v{{< current-version >}}) for the full release note.

- [Removal](#removal)
  - [`longhorn.io/v1beta1` API](#longhorniov1beta1-api)
- [General](#general)
  - [Kubernetes Version Requirement](#kubernetes-version-requirement)
  - [CRD Upgrade Validation](#crd-upgrade-validation)
  - [Upgrade Check Events](#upgrade-check-events)
  - [Manual Checks Before Upgrade](#manual-checks-before-upgrade)
- [V2 Data Engine](#v2-data-engine)
  - [Longhorn System Upgrade](#longhorn-system-upgrade)
  - [Newly Introduced Functionalities since Longhorn v1.10.0](#newly-introduced-functionalities-since-longhorn-v1100)

## Removal

### `longhorn.io/v1beta1` API

The `v1beta1` version of the Longhorn API is removed since Longhorn v1.10.0.

For more details, see [Issue #10249](https://github.com/longhorn/longhorn/issues/10249).

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

## V1 Data Engine

### IPv6 Support

Longhorn v1.10.0 and later version support usage of V1 volumes in single-stacked IPv6 Kubernetes cluster. For more information, see [Issue #2259](https://github.com/longhorn/longhorn/issues/2259).

> **Warning:** Dual-stack Kubernetes clusters and V2 volumes are not supported at this version.

## V2 Data Engine

### Longhorn System Upgrade

Longhorn currently does not support live upgrading of V2 volumes. Ensure that all V2 volumes are detached before initiating the upgrade process.

### Newly Introduced Functionalities since Longhorn v1.10.0

## Backup And Restore

### Configurable Backup Block Size

Starting in Longhorn v1.10.0, users can configure the backup block size when creating a volume. This feature offers greater flexibility, allowing the block size to be adjusted based on different needs and cost considerations to balance performance, efficiency, and transmission cost.

For more information, see [Create Longhorn Volumes](../nodes-and-volumes/volumes/create-volumes).
