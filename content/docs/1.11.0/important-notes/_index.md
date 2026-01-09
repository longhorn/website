---
title: Important Notes
weight: 1
---

This page summarizes the key notes for Longhorn v{{< current-version >}}.
For the full release note, see [here](https://github.com/longhorn/longhorn/releases/tag/v{{< current-version >}}).

- [Deprecation](#deprecation)
- [Behavior Change](#behavior-change)
  - [Cloned Volume Health After Efficient Cloning](#cloned-volume-health-after-efficient-cloning)
- [General](#general)
  - [Kubernetes Version Requirement](#kubernetes-version-requirement)
  - [Upgrade Check Events](#upgrade-check-events)
  - [Manual Checks Before Upgrade](#manual-checks-before-upgrade)
  - [Consolidation of Longhorn Settings](#consolidation-of-longhorn-settings)
  - [System Info Category in Setting](#system-info-category-in-setting)
  - [Volume Attachment Summary](#volume-attachment-summary)
  - [Manager URL for External API Access](#manager-url-for-external-api-access)
- [Scheduling](#scheduling)
  - [Replica Scheduling with Balance Algorithm](#replica-scheduling-with-balance-algorithm)
- [Monitoring](#monitoring)
  - [Disk Health Monitoring](#disk-health-monitoring)
- [V2 Data Engine](#v2-data-engine)
  - [Longhorn System Upgrade](#longhorn-system-upgrade)

## Deprecation

V2 Backing Image is deprecated and will be removed in a future release. Users can used containerized data importer (CDI) to import images into Longhorn as an alternative. For more information, see [Longhorn with CDI Imports](../advanced-resources/containerized-data-importer/containerized-data-importer).

## Behavior Change

### Cloned Volume Health After Efficient Cloning

With efficient cloning enabled, a newly cloned and detached volume is degraded and has only one replica, with its clone status set to `copy-completed-awaiting-healthy`. To bring the volume to a healthy state, transition the clone status to `completed` and rebuild the remaining replica by either enabling offline replica rebuilding or attaching the volume to trigger replica rebuilding. See [Issue #12341](https://github.com/longhorn/longhorn/issues/12341) and [Issue #12328](https://github.com/longhorn/longhorn/issues/12328).

## General

### Kubernetes Version Requirement

Due to the upgrade of the CSI external snapshotter to v8.2.0, all clusters must be running Kubernetes v1.25 or later before you can upgrade to Longhorn v1.8.0 or a newer version.

### Upgrade Check Events

When upgrading via Helm or Rancher App Marketplace, Longhorn performs pre-upgrade checks. If a check fails, the upgrade stops, and the reason for the failure is recorded in an event.

For more detail, see [Upgrading Longhorn Manager](../deploy/upgrade/longhorn-manager).

### Manual Checks Before Upgrade

Automated pre-upgrade checks do not cover all scenarios. Manual checks via kubectl or the UI are recommended:

- Ensure all V2 Data Engine volumes are detached and replicas are stopped. The V2 engine does not support live upgrades.
- Avoid upgrading when volumes are "Faulted", as unusable replicas may be deleted, causing permanent data loss if no backups exist.
- Avoid upgrading if a failed BackingImage exists. See [Backing Image](../advanced-resources/backing-image/backing-image) for details.
- Creating a [Longhorn system backup](../advanced-resources/system-backup-restore/backup-longhorn-system) before upgrading is recommended to ensure recoverability.

### Manager URL for External API Access

Longhorn v{{< current-version >}} introduces the `manager-url` setting that allows explicit configuration of the external URL for accessing the Longhorn Manager API.

**Background**: When Longhorn Manager is accessed through Ingress or Gateway API HTTPRoute, API responses may contain internal cluster IPs (e.g., `10.42.x.x:9500`) in the `actions` and `links` fields. This occurs when the ingress controller does not properly set `X-Forwarded-*` headers, causing the API to fall back to the internal pod IP.

**Solution**: Configure the `manager-url` setting with your external URL (e.g., `https://longhorn.example.com`). The Manager will inject proper forwarded headers to ensure API responses contain correct external URLs.

**Configuration**:
- **Via Helm**: `--set defaultSettings.managerUrl="https://longhorn.example.com"`
- **Via kubectl**: `kubectl -n longhorn-system patch settings.longhorn.io manager-url --type='merge' -p '{"value":"https://longhorn.example.com"}'`
- **Via UI**: Settings > General > Manager URL

For more details, see [Manager URL](../references/settings#manager-url).

## Scheduling

### Replica Scheduling with Balance Algorithm

To improve data distribution and resource utilization, Longhorn introduces a **balance algorithm** that schedules replicas evenly across nodes and disks based on calculated balance scores.

For more information, see [Scheduling](../nodes-and-volumes/nodes/scheduling).

## Monitoring

### Disk Health Monitoring

Starting with Longhorn v1.11.0, disk health monitoring is available for both V1 and V2 data engines. Longhorn collects health data from disks and exposes it through Prometheus metrics and Longhorn `Node` Custom Resources.

**Key Features:**

- Automatic health data collection every 10 minutes
- Disk health status and detailed attributes exposed as Prometheus metrics
- Health data available in `nodes.longhorn.io` Custom Resources

> **Note:**
> 
> - SMART data may not be fully available in virtualized or cloud environments (e.g., AWS EBS), which may result in zero values for certain attributes.
> - Available health attributes vary depending on disk type and hardware.

For more information, see [Disk Health Monitoring](../monitoring/disk-heath).

## V2 Data Engine

### Longhorn System Upgrade

Live upgrades of V2 volumes are **not supported**. Ensure all V2 volumes are detached before upgrading.
