---
title: Important Notes
weight: 1
---

This page summarizes the key notes for Longhorn v{{< current-version >}}.
For the full release note, see [here](https://github.com/longhorn/longhorn/releases/tag/v{{< current-version >}}).

- [Removal](#removal)
- [Important Fixes](#important-fixes)
  - [Instance Manager Panic During Replica Rebuild](#instance-manager-panic-during-replica-rebuild)
  - [Replica Rebuild Progress Reporting](#replica-rebuild-progress-reporting)
  - [Replica Auto-Balance Scheduling Loop](#replica-auto-balance-scheduling-loop)
  - [Replica CR Leak During Failed Local Scheduling](#replica-cr-leak-during-failed-local-scheduling)
  - [CSI Storage Capacity Tracking](#csi-storage-capacity-tracking)
  - [Encrypted Volume Size After Engine Upgrade](#encrypted-volume-size-after-engine-upgrade)
- [General](#general)
  - [Kubernetes Version Requirement](#kubernetes-version-requirement)
  - [Manual Checks Before Upgrade](#manual-checks-before-upgrade)
- [Scheduling](#scheduling)
  - [Topology-Aware PV Node Affinity Control](#topology-aware-pv-node-affinity-control)
- [Stability](#stability)
  - [Configurable Engine Image Pod Liveness Probe](#configurable-engine-image-pod-liveness-probe)
- [Resource Efficiency](#resource-efficiency)
  - [Longhorn Manager Memory Optimization](#longhorn-manager-memory-optimization)
- [Networking](#networking)
  - [Dual-Stack Cluster Support](#dual-stack-cluster-support)
- [Monitoring](#monitoring)
  - [Toggle Kubernetes Metrics Server Integration](#toggle-kubernetes-metrics-server-integration)
- [Command-Line Tool](#command-line-tool)
  - [On-Demand Snapshot Checksum Calculation](#on-demand-snapshot-checksum-calculation)
- [V2 Data Engine](#v2-data-engine)
  - [Longhorn System Upgrade](#longhorn-system-upgrade)
  - [Default SPDK CPU Allocation](#default-spdk-cpu-allocation)
  - [UBLK Frontend Kernel Limitation](#ublk-frontend-kernel-limitation)
  - [IPv6 Support](#ipv6-support)
  - [V2 Features Planned for Longhorn v1.12.1](#v2-features-planned-for-longhorn-v1121)
    - [Fast Volume Cloning](#fast-volume-cloning)
    - [Storage Sharding](#storage-sharding)

## Removal

V2 Backing Images are removed in Longhorn v{{< current-version >}}. Use the Containerized Data Importer (CDI) to import images into Longhorn for compatibility with the current engine.

**Migration required for existing V2 volumes with backing images:**

If you have V2 volumes that were created from backing images, you must migrate them before upgrading to v{{< current-version >}}:

1. **Backup and recreate** (recommended): Create a backup of the V2 volume, delete the original volume, then restore from backup. The restored volume will not have a backing image dependency.
2. **Delete the volume**: If the data is not needed, delete the V2 volume directly.

V2 volumes with backing image dependencies cannot be upgraded in-place. Attempting to upgrade without migration may result in volume attachment failures.

For more information, see [Issue #13181](https://github.com/longhorn/longhorn/issues/13181) and [Longhorn with CDI Imports](../advanced-resources/containerized-data-importer/containerized-data-importer).

## Important Fixes

This release includes critical stability fixes.

### Instance Manager Panic During Replica Rebuild

Longhorn v{{< current-version >}} fixes an instance-manager panic that could occur during replica rebuild storms. In affected environments, the panic could terminate all iSCSI targets served by the instance-manager and trigger cascading volume detachments across multiple PVCs.

For more information, see [Issue #13087](https://github.com/longhorn/longhorn/issues/13087).

### Replica Rebuild Progress Reporting

Longhorn v{{< current-version >}} fixes a replica rebuild progress reporting bug that could display values greater than 100% after file-sync retries on unstable networks. Progress accounting is now reset correctly for retried files, so rebuild progress remains within the valid 0% to 100% range.

For more information, see [Issue #12949](https://github.com/longhorn/longhorn/issues/12949).

### Replica Auto-Balance Scheduling Loop

Longhorn v{{< current-version >}} fixes a regression in replica auto-balance that could trigger a repeated replica create-and-delete loop when `Replica Auto Balance` was set to `best-effort`. In affected clusters, Longhorn could keep scheduling an extra replica instead of stabilizing at the configured replica count.

For more information, see [Issue #12926](https://github.com/longhorn/longhorn/issues/12926).

### Replica CR Leak During Failed Local Scheduling

Longhorn v{{< current-version >}} fixes a replica scheduling issue where large numbers of stopped Replica CRs could accumulate when `dataLocality` was set to `best-effort` and the node did not have enough eligible local disk space for another replica. In affected clusters, recurring reconciliation could keep creating placeholder Replica CRs instead of reusing a single failed-schedule placeholder.

For more information, see [Issue #13152](https://github.com/longhorn/longhorn/issues/13152).

### CSI Storage Capacity Tracking

Longhorn v{{< current-version >}} fixes a CSIStorageCapacity scheduling issue that could cause compute nodes without Longhorn disks to report zero capacity and be rejected by `WaitForFirstConsumer` scheduling. In affected clusters with separated compute and storage nodes, new PVCs could remain pending even though eligible storage was available on storage nodes.

For more information, see [Issue #12807](https://github.com/longhorn/longhorn/issues/12807) and [Settings](../references/settings#csi-storage-capacity-tracking).

### Encrypted Volume Size After Engine Upgrade

Longhorn v{{< current-version >}} pre-allocates the 16 MiB LUKS2 header in the replica backend file for encrypted volumes (replica size = requested size + 16 MiB). As a result, the dm-crypt device now exposes the full requested size to workloads.

**Before v1.12**: The 16 MiB LUKS2 header was consumed from the usable volume space. For example, a 1 GiB encrypted volume yielded approximately 1008 MiB to the workload.

**After upgrading to v1.12**: Once the engine image is upgraded for an encrypted volume, Longhorn automatically expands the backend size by 16 MiB. The dm-crypt device then exposes the full requested size (e.g., exactly 1 GiB for a 1 GiB volume). Existing data is not affected.

**Live migration restriction**: Encrypted migratable volumes cannot be live-migrated when using an engine image with a CLI API version older than 12 (pre-v1.12 engine images). Upgrade the engine image to v1.12 or later before attempting live migration of encrypted volumes.

For more information, see [Issue #9205](https://github.com/longhorn/longhorn/issues/9205).

## General

### Kubernetes Version Requirement

Because the CSI external snapshotter is upgraded to v8.2.0, all clusters must be running Kubernetes v1.25 or later before upgrading to Longhorn v{{< current-version >}}.

### Manual Checks Before Upgrade

Automated pre-upgrade checks do not cover all scenarios. Manual checks via kubectl or the UI are recommended:

- Ensure all V2 Data Engine volumes are detached and replicas are stopped. The V2 engine does not support live upgrades.
- Avoid upgrading when volumes are in the "Faulted" state, as unusable replicas may be deleted, causing permanent data loss if no backups exist.
- Avoid upgrading if a failed BackingImage exists. See [Backing Image](../advanced-resources/backing-image/backing-image) for details.
- Creating a [Longhorn system backup](../advanced-resources/system-backup-restore/backup-longhorn-system) before upgrading is recommended to ensure recoverability.

## Scheduling

### Topology-Aware PV Node Affinity Control

Longhorn v{{< current-version >}} adds the `csi-allowed-topology-keys` setting and `strictTopology` StorageClass parameter for more precise control of PV `nodeAffinity`. These options allow users to limit which topology keys are propagated and, with `WaitForFirstConsumer`, pin the PV to the selected node topology when needed.

For more information, see [Issue #12684](https://github.com/longhorn/longhorn/issues/12684) and [Topology-Aware Provisioning](../nodes-and-volumes/nodes/topology-aware-provisioning).

## Stability

### Configurable Engine Image Pod Liveness Probe

Longhorn v{{< current-version >}} adds settings to configure the engine-image DaemonSet liveness probe period, timeout, and failure threshold. These settings help reduce unnecessary engine-image pod restarts on resource-constrained clusters, especially during upgrades or transient CPU spikes.

For more information, see [Issue #12846](https://github.com/longhorn/longhorn/issues/12846) and [Settings](../references/settings#engine-image-pod-liveness-probe-period).

## Resource Efficiency

### Longhorn Manager Memory Optimization

Longhorn v{{< current-version >}} optimizes longhorn-manager informer caching to reduce memory usage, especially in large clusters with high pod counts. This lowers cluster-wide memory overhead caused by repeated caching of non-Longhorn pod data on every manager instance.

For more information, see [Issue #12771](https://github.com/longhorn/longhorn/issues/12771).

## Networking

### Dual-Stack Cluster Support

Longhorn supports dual-stack Kubernetes clusters under a specific requirement: all nodes must be configured with their IP families in the same order (either all IPv4-first, or all IPv6-first). When the order is consistent, Longhorn uses the first IP family of each node and operates correctly. This applies to both the V1 and V2 data engines.

> **Warning:** Dual-stack clusters with mixed IP family ordering across nodes are not supported and may result in connectivity failures between replicas and the engine.

For more information, see [Issue #11531](https://github.com/longhorn/longhorn/issues/11531).

## Monitoring

### Toggle Kubernetes Metrics Server Integration

Longhorn v{{< current-version >}} adds the `Kubernetes Metrics Server Metrics Enabled` setting to disable metrics-server-dependent metrics when the Kubernetes Metrics Server API is unavailable. This reduces repeated scrape warnings and unnecessary API calls while preserving other Longhorn metrics.

For more information, see [Issue #13011](https://github.com/longhorn/longhorn/issues/13011) and [Settings](../references/settings#kubernetes-metrics-server-metrics-enabled).

## Command-Line Tool

### On-Demand Snapshot Checksum Calculation

Longhorn v{{< current-version >}} adds `longhornctl` support for triggering on-demand snapshot checksum calculation. This is useful when snapshot checksum recalculation needs to be requested without waiting for the periodic integrity-check schedule.

The command can target a specific volume, all volumes on a specific node, or all volumes in the cluster. The checksum operation runs asynchronously in the background.

For more information, see [Issue #11442](https://github.com/longhorn/longhorn/issues/11442) and [On-Demand Snapshot Checksum Calculation](../advanced-resources/data-integrity/on-demand-snapshot-data-integrity).

## V2 Data Engine

### Longhorn System Upgrade

Live upgrades of V2 volumes are **not supported**. Ensure all V2 volumes are detached before upgrading.

### Default SPDK CPU Allocation

Longhorn v{{< current-version >}} changes the default `data-engine-cpu-mask` from `0x1` (1 CPU core) to `0x3` (2 CPU cores). SPDK uses a busy-polling reactor model where the master reactor handles both I/O polling and management RPCs. When only a single core is assigned, heavy I/O workloads can delay or starve RPC processing, resulting in increased latency, timeout events, and operational instability.

Assigning 2 or more cores allows I/O and management tasks to run on separate reactors, improving responsiveness and operational stability.

For more information, see [Issue #13237](https://github.com/longhorn/longhorn/issues/13237) and [Configurable CPU Cores](../advanced-resources/v2-data-engine/configurable-cpu-cores).

### UBLK Frontend Kernel Limitation

The UBLK frontend for V2 data engine volumes is experimental and only functional on Linux kernels below v6.17. On kernel v6.17.0 and above, UBLK fails due to upstream UBLK API changes that cause `EINVAL` errors when starting UBLK devices.

For more information, see [Issue #11977](https://github.com/longhorn/longhorn/issues/11977) and [UBLK Frontend Support](../advanced-resources/v2-data-engine/ublk-frontend-support).

### IPv6 Support

V2 volumes now support single-stack IPv6 Kubernetes clusters. For dual-stack cluster support and its limitations, see [Dual-Stack Cluster Support](#dual-stack-cluster-support).

For more information, see [Issue #10928](https://github.com/longhorn/longhorn/issues/10928).

### V2 Features Planned for Longhorn v1.12.1

#### Fast Volume Cloning

Fast volume cloning for the V2 data engine is planned for Longhorn v1.12.1. This enhancement is intended to allow the initial `linked-clone` to be created with multiple replicas in parallel instead of being limited to a single replica.

For more information, see [Issue #12552](https://github.com/longhorn/longhorn/issues/12552).

#### Storage Sharding

Storage sharding for the V2 data engine is planned as an experimental feature for Longhorn v1.12.1. This capability is intended to address the existing space efficiency limitations caused by replica-based storage overhead.

For more information, see [Issue #1061](https://github.com/longhorn/longhorn/issues/1061).
