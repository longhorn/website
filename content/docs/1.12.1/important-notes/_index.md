---
title: Important Notes
weight: 1
---

This page summarizes the key notes for Longhorn v{{< current-version >}}.
For the full release note, see the Longhorn v{{< current-version >}} release notes on GitHub.

- [Breaking Changes](#breaking-changes)
  - [Deprecation of legacy v2 linked clone volumes](#deprecation-of-legacy-v2-linked-clone-volumes)
  - [Removal of V2 Backing Images](#removal-of-v2-backing-images)
- [V2 Data Engine](#v2-data-engine)
  - [General Availability](#general-availability)
  - [Notice](#notice)
    - [Volume Attach Latency at Scale](#volume-attach-latency-at-scale)
    - [ARM64 NVMe-backed Block-Type Node Disk Limitation](#arm64-nvme-backed-block-type-node-disk-limitation)
    - [UBLK Frontend Kernel Limitation](#ublk-frontend-kernel-limitation)
    - [Longhorn System Upgrade](#longhorn-system-upgrade)
  - [Fast Volume Cloning](#fast-volume-cloning)
  - [Default CPU Allocation](#default-cpu-allocation)
  - [V2 Dedicated CPU Requirements](#v2-dedicated-cpu-requirements)
  - [CPU Core Allocation with the Kubernetes CPU Manager](#cpu-core-allocation-with-the-kubernetes-cpu-manager)
  - [Host CPU Isolation](#host-cpu-isolation)
  - [SPDK iobuf Pool Size Configuration](#spdk-iobuf-pool-size-configuration)
  - [IPv6 Support](#ipv6-support)
- [Storage Sharding (Experimental)](#storage-sharding-experimental)
- [Important Fixes](#important-fixes)
  - [Instance Manager Panic During Replica Rebuild](#instance-manager-panic-during-replica-rebuild)
  - [Replica Rebuild Progress Reporting](#replica-rebuild-progress-reporting)
  - [Replica Auto-Balance Scheduling Loop](#replica-auto-balance-scheduling-loop)
  - [Replica CR Leak During Failed Local Scheduling](#replica-cr-leak-during-failed-local-scheduling)
  - [CSI Storage Capacity Tracking](#csi-storage-capacity-tracking)
  - [Encrypted Volume Size Correction](#encrypted-volume-size-correction)
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
  - [Internal Network Policies](#internal-network-policies)
  - [Instance Manager gRPC mTLS Coverage](#instance-manager-grpc-mtls-coverage)
  - [Dual-Stack Cluster Support](#dual-stack-cluster-support)
- [Monitoring](#monitoring)
  - [Toggle Kubernetes Metrics Server Integration](#toggle-kubernetes-metrics-server-integration)
- [Command-Line Tool](#command-line-tool)
  - [On-Demand Snapshot Checksum Calculation](#on-demand-snapshot-checksum-calculation)

## Breaking Changes

### Deprecation of legacy v2 linked clone volumes

V2 linked-clone volumes created in v1.12.0 or earlier are marked as legacy and deprecated starting in v{{< current-version >}}. The new linked-clone architecture introduced in [Ticket #12552](https://github.com/longhorn/longhorn/issues/12552) is not compatible with the legacy design.

After upgrading to v{{< current-version >}}, **legacy linked-clone volumes cannot be operated on except for detachment and deletion**.

To replace, create new linked-clone volumes from the same source volumes that back the legacy ones. As long as a legacy volume exists, its source volume is guaranteed to still be present, so you can create a replacement linked clone directly; no data copy is required.

For more information, see [Ticket #12552](https://github.com/longhorn/longhorn/issues/12552).

### Removal of V2 Backing Images

V2 Backing Images are removed in Longhorn v{{< current-version >}}. Use the Containerized Data Importer (CDI) to import images into Longhorn for compatibility with the current engine.

**Migration required for existing V2 volumes with backing images:**

If you have V2 volumes that were created from backing images, you must migrate them before upgrading to v{{< current-version >}}:

1. **Backup and recreate** (recommended): Create a backup of the V2 volume, delete the original volume, then restore from backup. The restored volume will not have a backing image dependency.
2. **Delete the volume**: If the data is not needed, delete the V2 volume directly.

V2 volumes with backing image dependencies cannot be upgraded in-place. Attempting to upgrade without migration may result in volume attachment failures.

For more information, see [Issue #13181](https://github.com/longhorn/longhorn/issues/13181) and [Longhorn with CDI Imports](../advanced-resources/containerized-data-importer/containerized-data-importer).

## V2 Data Engine

### General Availability

The V2 Data Engine is generally available in Longhorn v{{< current-version >}}. This milestone reflects improvements in stability, operational safety, networking support, and feature maturity, making V2 volumes suitable for production use in supported environments.

For a summary of the current V1 and V2 behavior differences and feature parity, see [V1 and V2 Volume Behavior and Feature Parity](../v1-v2-volume-behavior-and-feature-parity).

For more information, see [Issue #6229](https://github.com/longhorn/longhorn/issues/6229).

### Notice

#### Volume Attach Latency at Scale

In environments with a growing number of attached V2 volumes, increased attach latency has been observed for subsequent volumes. Initial analysis suggests this may be related to NVMe-TCP connection handling at scale, though the precise layer (SPDK user-space or Linux kernel) has not yet been identified. Further investigation is in progress. For follow-up status, see [Issue #13241](https://github.com/longhorn/longhorn/issues/13241).

#### ARM64 NVMe-backed Block-Type Node Disk Limitation

On ARM64 systems, V2 volumes may experience stuck I/O when SPDK is configured with two or more CPU cores and node disks use the NVMe driver. The root cause may lie in either the Linux kernel or SPDK itself, and further investigation is required. As a workaround, use [AIO-backed node disks](../nodes-and-volumes/nodes/multidisk#using-aio-disks) instead of [NVMe-backed node disks](../nodes-and-volumes/nodes/multidisk#using-nvme-disks) on ARM64 systems. For follow-up status, see [Issue #13243](https://github.com/longhorn/longhorn/issues/13243).

#### UBLK Frontend Kernel Limitation

The UBLK frontend for V2 Data Engine volumes is experimental and only functional on Linux kernels below v6.17. On kernel v6.17.0 and above, UBLK fails due to upstream UBLK API changes that cause `EINVAL` errors when starting UBLK devices.

For more information, see [Issue #11977](https://github.com/longhorn/longhorn/issues/11977) and [UBLK Frontend Support](../advanced-resources/v2-data-engine/ublk-frontend-support).

#### Longhorn System Upgrade

V2 volumes do not support live upgrades between Longhorn v1.12 patch releases and must be detached before upgrading. Support is planned when upgrading from a Longhorn v1.12 release to a Longhorn v1.13 release.

### Fast Volume Cloning

Longhorn v{{< current-version >}} enhances fast volume cloning for the V2 Data Engine. A `linked-clone` volume shares data blocks with its source instead of copying data. With the new architecture, a source replica can share its data blocks with multiple linked-clone volumes, and multiple clone replicas can be created in parallel.

Linked-clone volumes now support most operations available to regular volumes, including snapshots, backups, expansion, replica rebuilding, and use as the source of nested linked clones.

The new architecture is not compatible with clones created in v1.12.0 or earlier. See [Deprecation of legacy v2 linked clone volumes](#deprecation-of-legacy-v2-linked-clone-volumes).

For more information, see [Issue #12552](https://github.com/longhorn/longhorn/issues/12552) and [CSI Volume Clone](../snapshots-and-backups/csi-volume-clone).

### Default CPU Allocation

Longhorn v{{< current-version >}} changes the default `data-engine-cpu-mask` from `0x1` (1 CPU core) to `0x3` (2 CPU cores). V2 Data Engine uses a busy-polling reactor model where the master reactor handles both I/O polling and management RPCs. When only a single core is assigned, heavy I/O workloads can delay or starve RPC processing, resulting in increased latency, timeout events, and operational instability.

Assigning 2 or more cores allows I/O and management tasks to run on separate reactors, improving responsiveness and operational stability.

For more information, see [Issue #13237](https://github.com/longhorn/longhorn/issues/13237) and [Configurable CPU Cores](../advanced-resources/v2-data-engine/configurable-cpu-cores).

### V2 Dedicated CPU Requirements

When assigning CPU cores to the V2 Data Engine, ensure that the V2 instance-manager pod has enough guaranteed CPU resources to cover the assigned cores. This provides dedicated CPU availability for SPDK reactors, prevents CPU contention, and helps maintain predictable performance and V2 Data Engine stability.

You can verify that the guaranteed CPU resources match the CPU cores specified by `data-engine-cpu-mask` or `data-engine-number-of-cpu-cores`. For more details, see [Guaranteed Instance Manager CPU](../references/settings/#guaranteed-instance-manager-cpu), [Data Engine CPU Mask](../references/settings/#data-engine-cpu-mask), and [Data Engine Number of CPU Cores](../references/settings/#data-engine-number-of-cpu-cores).

### CPU Core Allocation with the Kubernetes CPU Manager

Longhorn v{{< current-version >}} can allocate exclusive CPU cores to the SPDK target daemon, which runs in each V2 Instance Manager pod, through the Kubernetes CPU Manager by using the `data-engine-number-of-cpu-cores` setting.

The setting can be applied only when the kubelet CPU Manager policy is set to `static` on all worker nodes; otherwise, the update is rejected. When the value is positive, it takes precedence, and `data-engine-cpu-mask` is ignored.

For more information, see [Issue #13248](https://github.com/longhorn/longhorn/issues/13248) and [Data Engine Number of CPU Cores](../references/settings/#data-engine-number-of-cpu-cores).

### Host CPU Isolation

The `data-engine-cpu-isolation-enabled` setting now also steers network Receive Packet Steering (RPS) away from the CPU cores used by the SPDK target daemon, in addition to hardware IRQs and unbound kernel workqueue workers. This further reduces preemption of the SPDK polling reactors on busy nodes.

For more information, see [Issue #13483](https://github.com/longhorn/longhorn/issues/13483) and [Data Engine CPU Isolation Enabled](../references/settings/#data-engine-cpu-isolation-enabled).

### SPDK iobuf Pool Size Configuration

Longhorn v{{< current-version >}} allows tuning the SPDK iobuf buffer pools used by the V2 Data Engine. The `data-engine-iobuf-large-pool-size` setting configures the large buffer pool (`large_pool_count`), while `data-engine-iobuf-small-pool-size` configures the 8 KiB small buffer pool (`small_pool_count`). Increasing the small pool can relieve buffer exhaustion under high-queue-depth workloads with I/O sizes of 8 KiB or less, such as 4 KiB random reads across many volumes.

Larger small pool values consume more of the fixed memory budget configured by `data-engine-memory-size`, so increase that setting accordingly; otherwise, fewer volumes may fit on each node. Because iobuf pools can only be sized when the SPDK target starts, changing either pool setting recreates V2 Instance Manager pods that have no running instances so the new value can take effect.

For more information, see [Data Engine iobuf Large Pool Size](../references/settings/#data-engine-iobuf-large-pool-size) and [Data Engine iobuf Small Pool Size](../references/settings/#data-engine-iobuf-small-pool-size).

### IPv6 Support

V2 volumes now support single-stack IPv6 Kubernetes clusters. For dual-stack cluster support and its limitations, see [Dual-Stack Cluster Support](#dual-stack-cluster-support).

For more information, see [Issue #10928](https://github.com/longhorn/longhorn/issues/10928).

## Storage Sharding (Experimental)

Longhorn v{{< current-version >}} introduces storage sharding as an experimental data protection and storage layout feature built on the V2 Data Engine. Instead of storing a full copy of the volume on each replica, sharding uses erasure coding to encode written data into data and parity chunks, which are distributed across multiple nodes. This allows a volume to grow beyond the capacity of a single disk or node while using less disk space to achieve the same level of fault tolerance.

Because this feature is experimental, it is intended for evaluation and testing only and is not recommended for production use.

For more information, see [Issue #1061](https://github.com/longhorn/longhorn/issues/1061) and [Sharding with Erasure Coding](../advanced-resources/v2-data-engine/sharding).

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

### Encrypted Volume Size Correction

Longhorn reserves an additional 16 MiB of raw capacity for the LUKS2 metadata used by encrypted volumes, allowing the mapped device to expose the full capacity requested by the workload. Previously, the metadata was taken from usable capacity, so a requested 1 GiB encrypted volume exposed only 1008 MiB. This discrepancy could cause operations such as block-level copies between equally sized unencrypted and encrypted volumes to fail.

- **V1 Data Engine**: This correction was introduced in Longhorn v1.12.0. Existing encrypted V1 volumes created with v1.11.x or earlier receive the additional capacity automatically when their engine image is upgraded to v1.12 or later. Existing data is preserved. Encrypted migratable V1 volumes cannot be live-migrated while using an engine image with a CLI API version earlier than 12; upgrade the engine image first.
- **V2 Data Engine**: Longhorn v{{< current-version >}} applies the correction to newly created encrypted V2 volumes.

> **Notice:** Existing encrypted V2 volumes upgraded from v1.11.3 or v1.12.0 do not receive the additional 16 MiB of raw capacity and continue to expose 16 MiB less than requested. Existing data is preserved.

For more information, see [Issue #9205](https://github.com/longhorn/longhorn/issues/9205) and [Issue #13163](https://github.com/longhorn/longhorn/issues/13163).

## General

### Kubernetes Version Requirement

Because the CSI external snapshotter is upgraded to v8.2.0, all clusters must be running Kubernetes v1.34 or later before upgrading to Longhorn v{{< current-version >}}.

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

### Internal Network Policies

Longhorn v{{< current-version >}} enables ingress policies for internal component endpoints and RPCs by default, including the instance-manager gRPC endpoint used for engine control. These policies require a CNI plugin that enforces Kubernetes `NetworkPolicy`. Before upgrading, review the [CNI Plugin Compatibility](../best-practices#cni-plugin-compatibility) table and verify that the policies allow the traffic required by your cluster topology.

For Helm installations, `networkPolicies.restrictInternalTraffic` controls the internal policies and defaults to `true`. If your environment is incompatible or you manage these policies separately, set `networkPolicies.restrictInternalTraffic=false` in the values file or pass `--set networkPolicies.restrictInternalTraffic=false` when running or retrying `helm upgrade`. Use `--reuse-values` with `helm upgrade` when appropriate to retain previous release settings. This setting is independent of `networkPolicies.enabled`, which controls only the Longhorn UI frontend policy.

After a successful upgrade with `networkPolicies.restrictInternalTraffic=false`, the six internal NetworkPolicy templates are omitted from the rendered output, and policies owned by the Helm release are removed. Preview the rendered output with `helm upgrade --dry-run` or `helm template`; do not add `--reuse-values` to `helm template`. If installed, `helm diff` can optionally compare the changes.

For manifest installations, delete only these six internal NetworkPolicy resources:

- `backing-image-data-source`
- `backing-image-manager`
- `instance-manager`
- `longhorn-manager`
- `longhorn-recovery-backend`
- `longhorn-webhook`

These resources are defined in `longhorn.yaml` and `longhorn-okd.yaml`. Do not use `kubectl delete -f` on an entire Longhorn manifest or delete the Longhorn installation. Applying either unmodified manifest later recreates the policies.

If an upgrade fails because these policies block required traffic, disable or remove the internal policies as appropriate and retry the same upgrade. For policy behavior, Kubernetes API server source restrictions, and Helm values, see [Network Policies](../advanced-resources/security/network-policy). For more information, see [Issue #13438](https://github.com/longhorn/longhorn/issues/13438).

### Instance Manager gRPC mTLS Coverage

When the `longhorn-grpc-tls` secret is configured, the remaining instance-manager gRPC services now also require mutual TLS. Plaintext clients and clients without a valid certificate are rejected.

For more information, see [Issue #7787](https://github.com/longhorn/longhorn/issues/7787) and [MTLS Support](../advanced-resources/security/mtls-support).

### Dual-Stack Cluster Support

Longhorn supports dual-stack Kubernetes clusters under a specific requirement: all nodes must be configured with their IP families in the same order (either all IPv4-first, or all IPv6-first). When the order is consistent, Longhorn uses the first IP family of each node and operates correctly. This applies to both the V1 and V2 Data Engines.

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
