---
title: Important Notes
weight: 1
---

This page summarizes the key notes for Longhorn v{{< current-version >}}.
For the full release note, see the [Longhorn v1.12.2 release notes](https://github.com/longhorn/longhorn/releases/tag/v1.12.2) on GitHub.

- [Breaking Changes](#breaking-changes)
  - [Deprecation of legacy v2 linked clone volumes](#deprecation-of-legacy-v2-linked-clone-volumes)
  - [Removal of V2 Backing Images](#removal-of-v2-backing-images)
- [General](#general)
  - [Kubernetes Version Requirement](#kubernetes-version-requirement)
  - [Manual Checks Before Upgrade](#manual-checks-before-upgrade)
- [V2 Data Engine Notices](#v2-data-engine-notices)
  - [Longhorn System Upgrade](#longhorn-system-upgrade)
  - [Periodic Backups Recommended for V2 Volumes](#periodic-backups-recommended-for-v2-volumes)
  - [Volume Attach Latency at Scale](#volume-attach-latency-at-scale)
  - [ARM64 NVMe-backed Block-Type Node Disk Limitation](#arm64-nvme-backed-block-type-node-disk-limitation)
  - [UBLK Frontend Kernel Limitation](#ublk-frontend-kernel-limitation)
- [Changes in v1.12.2](#changes-in-v1122)
  - [V2 Data Engine](#v2-data-engine)
    - [Dedicated CPU Core for the SPDK Admin Reactor](#dedicated-cpu-core-for-the-spdk-admin-reactor)
    - [Configurable NVMe-TCP Initiator I/O Queue Count](#configurable-nvme-tcp-initiator-io-queue-count)
  - [Networking](#networking)
    - [IPv6 and Dual-Stack Support for Backing Images](#ipv6-and-dual-stack-support-for-backing-images)
    - [CNI Compatibility Helm Values for Internal Network Policies](#cni-compatibility-helm-values-for-internal-network-policies)
  - [Important Fixes](#important-fixes)
    - [Data Loss During Replica Rebuilds with Concurrent Unaligned Writes](#data-loss-during-replica-rebuilds-with-concurrent-unaligned-writes)
    - [Replica Rebuild Failure Caused by a Lost gRPC TCP Keepalive](#replica-rebuild-failure-caused-by-a-lost-grpc-tcp-keepalive)
    - [V2 Instance Manager Pod Crashes](#v2-instance-manager-pod-crashes)
    - [Engine Fault Caused by a V2 Replica Rebuild Destination Failure](#engine-fault-caused-by-a-v2-replica-rebuild-destination-failure)
    - [Sharding Storage Volume Write Stall on arm64](#sharding-storage-volume-write-stall-on-arm64)
- [Changes in v1.12.1](#changes-in-v1121)
  - [V2 Data Engine](#v2-data-engine-1)
    - [Fast Volume Cloning](#fast-volume-cloning)
    - [CPU Core Allocation with the Kubernetes CPU Manager](#cpu-core-allocation-with-the-kubernetes-cpu-manager)
    - [Host CPU Isolation](#host-cpu-isolation)
    - [SPDK iobuf Pool Size Configuration](#spdk-iobuf-pool-size-configuration)
  - [Sharding Storage (Experimental)](#sharding-storage-experimental)
  - [Networking](#networking-1)
    - [Internal Network Policies](#internal-network-policies)
    - [Instance Manager gRPC mTLS Coverage](#instance-manager-grpc-mtls-coverage)
- [Changes in v1.12.0](#changes-in-v1120)
  - [V2 Data Engine](#v2-data-engine-2)
    - [General Availability](#general-availability)
    - [Default CPU Allocation](#default-cpu-allocation)
    - [V2 Dedicated CPU Requirements](#v2-dedicated-cpu-requirements)
    - [IPv6 Support](#ipv6-support)
  - [Scheduling](#scheduling)
    - [Topology-Aware PV Node Affinity Control](#topology-aware-pv-node-affinity-control)
  - [Stability](#stability)
    - [Configurable Engine Image Pod Liveness Probe](#configurable-engine-image-pod-liveness-probe)
  - [Resource Efficiency](#resource-efficiency)
    - [Longhorn Manager Memory Optimization](#longhorn-manager-memory-optimization)
  - [Networking](#networking-2)
    - [Dual-Stack Cluster Support](#dual-stack-cluster-support)
  - [Monitoring](#monitoring)
    - [Toggle Kubernetes Metrics Server Integration](#toggle-kubernetes-metrics-server-integration)
  - [Command-Line Tool](#command-line-tool)
    - [On-Demand Snapshot Checksum Calculation](#on-demand-snapshot-checksum-calculation)
  - [Important Fixes](#important-fixes-1)
    - [Instance Manager Panic During Replica Rebuild](#instance-manager-panic-during-replica-rebuild)
    - [Replica Rebuild Progress Reporting](#replica-rebuild-progress-reporting)
    - [Replica Auto-Balance Scheduling Loop](#replica-auto-balance-scheduling-loop)
    - [Replica CR Leak During Failed Local Scheduling](#replica-cr-leak-during-failed-local-scheduling)
    - [CSI Storage Capacity Tracking](#csi-storage-capacity-tracking)
    - [Encrypted Volume Size Correction](#encrypted-volume-size-correction)

## Breaking Changes

### Deprecation of legacy v2 linked clone volumes

V2 linked-clone volumes created in v1.12.0 or earlier are marked as legacy and deprecated starting in v1.12.1. The new linked-clone architecture introduced in [Issue #12552](https://github.com/longhorn/longhorn/issues/12552) is not compatible with the legacy design.

After upgrading to v1.12.1 or later, **legacy linked-clone volumes cannot be operated on except for detachment and deletion**.

To replace, create new linked-clone volumes from the same source volumes that back the legacy ones. As long as a legacy volume exists, its source volume is guaranteed to still be present, so you can create a replacement linked clone directly; no data copy is required.

For more information, see [Issue #12552](https://github.com/longhorn/longhorn/issues/12552).

### Removal of V2 Backing Images

V2 Backing Images are removed in Longhorn v1.12.0. Use the Containerized Data Importer (CDI) to import images into Longhorn for compatibility with the current engine.

**Migration required for existing V2 volumes with backing images:**

> **Warning: Upgrade Failure Risk**
> V2 volumes with backing image dependencies cannot be upgraded in-place. Attempting to upgrade without migration may result in volume attachment failures.
>
> Furthermore, a direct backup of a V2 volume does not include its V2 backing image data, meaning a restore would still require the original backing image. If the volume data is still needed, you **must** perform the migration below before upgrading. If the data is no longer needed, simply delete the V2 volume instead.

Before upgrading to v{{< current-version >}}, flatten each required V2 volume into a temporary V1 volume and back up the V1 volume:

1. **Stop writes to the source volume:** Detach the workload or otherwise ensure that no process can modify the V2 volume during the copy.
2. **Create a temporary V1 volume:** Do not configure a backing image, and make the volume exactly the same size as the source V2 volume.
3. **Copy every block:** Use an offline migration pod or maintenance environment that exposes both volumes as raw block devices on the same node. Copy the source device to the temporary V1 device, then verify the result.

   ```shell
   dd if=/dev/source of=/dev/target bs=4M conv=fsync
   cmp /dev/source /dev/target
   sha256sum /dev/source /dev/target
   ```

4. **Back up the temporary V1 volume:** Detach the migration pod and create a Longhorn backup of the temporary V1 volume in the configured backup target.
5. **Test the standalone backup:** Verify that the backup does not list a backing image, restore it to a new volume, and validate the restored data before deleting any source data.
6. **Remove the dependency:** After the test restore succeeds, delete the original V2 volume and backing image. The temporary V1 volume can also be deleted after confirming that its backup is available.

For more information, see [Issue #13181](https://github.com/longhorn/longhorn/issues/13181) and [Longhorn with CDI Imports](../advanced-resources/containerized-data-importer/containerized-data-importer).

## General

### Kubernetes Version Requirement

Because the CSI external snapshotter is upgraded to v8.2.0, all clusters must be running Kubernetes v1.25 or later before upgrading to Longhorn v{{< current-version >}}.

### Manual Checks Before Upgrade

Automated pre-upgrade checks do not cover all scenarios. Manual checks via kubectl or the UI are recommended:

- Ensure all V2 Data Engine volumes are detached and replicas are stopped. The V2 engine does not support live upgrades between v1.12 patch releases or from v1.12.2 to v1.13.0.
- Avoid upgrading when volumes are in the "Faulted" state, as unusable replicas may be deleted, causing permanent data loss if no backups exist.
- Avoid upgrading if a failed BackingImage exists. See [Backing Image](../advanced-resources/backing-image/backing-image) for details.
- Creating a [Longhorn system backup](../advanced-resources/system-backup-restore/backup-longhorn-system) before upgrading is recommended to ensure recoverability.

## V2 Data Engine Notices

### Longhorn System Upgrade

V2 volumes do not support live upgrades between Longhorn v1.12 patch releases and must be detached before upgrading.

> **Live upgrade of the V2 Data Engine from v1.12.2 to v1.13.0 is not supported.**
>
> During a V2 Data Engine live upgrade, replicas are rebuilt while volumes are serving I/O. Because Longhorn v1.13.0 was released before several critical V2 rebuild and live-upgrade fixes (which are included in v1.12.2 and v1.13.1), `spdk_tgt` in the v1.13.0 instance-manager pods may crash or get stuck and prevent the upgrade from completing. These issues include [V2 Instance Manager Pod Crashes](#v2-instance-manager-pod-crashes), [Issue #14425](https://github.com/longhorn/longhorn/issues/14425), and other stability issues fixed in this release.
>
> - **Upgrading from v1.12.2 to v1.13.0:** Detach all V2 volumes before upgrading. The V2 instance-manager pods then restart with the new instance-manager image.
> - **Upgrading from v1.12.2 to v1.13.1 or later:** Live upgrade of the V2 Data Engine is supported. For instructions, see [V2 Instance Manager Upgrade](https://longhorn.io/docs/1.13.1/deploy/upgrade/v2-instance-upgrade/).

### Periodic Backups Recommended for V2 Volumes

In the V2 Data Engine, if a snapshot deletion or system-snapshot purge fails or is interrupted partway through (for example, by a disk I/O error, exhausted metadata pages, an `spdk_tgt` crash, an instance-manager pod restart, or a node reboot), inconsistent blobstore metadata can cause V2 volume data corruption, `spdk_tgt` crashes, or a disk lvstore load failure.

To protect against potential data loss, configure periodic backups for V2 volumes and avoid restarting V2 instance-manager pods or rebooting nodes while snapshots are being deleted or purged.

For more information, see [Issue #14474](https://github.com/longhorn/longhorn/issues/14474).

### Volume Attach Latency at Scale

In environments with a growing number of attached V2 volumes, increased attach latency has been observed for subsequent volumes. Initial analysis suggests this may be related to NVMe-TCP connection handling at scale, though the precise layer (SPDK user-space or Linux kernel) has not yet been identified. Further investigation is in progress. For follow-up status, see [Issue #13241](https://github.com/longhorn/longhorn/issues/13241).

### ARM64 NVMe-backed Block-Type Node Disk Limitation

On ARM64 systems, V2 volumes may experience stuck I/O when SPDK is configured with two or more CPU cores and node disks use the NVMe driver. The root cause may lie in either the Linux kernel or SPDK itself, and further investigation is required. As a workaround, use [AIO-backed node disks](../nodes-and-volumes/nodes/multidisk#using-aio-disks) instead of [NVMe-backed node disks](../nodes-and-volumes/nodes/multidisk#using-nvme-disks) on ARM64 systems. For follow-up status, see [Issue #13243](https://github.com/longhorn/longhorn/issues/13243).

### UBLK Frontend Kernel Limitation

This feature is experimental. The UBLK frontend works on all supported Linux kernels but may cause a kernel panic with kernel v6.17. For more information, see [GitHub Issue #11977](https://github.com/longhorn/longhorn/issues/11977) and [GitHub Issue #13509](https://github.com/longhorn/longhorn/issues/13509).

For more information, see [Issue #11977](https://github.com/longhorn/longhorn/issues/11977) and [UBLK Frontend Support](../advanced-resources/v2-data-engine/ublk-frontend-support).

---

## Changes in v1.12.2

### V2 Data Engine

#### Dedicated CPU Core for the SPDK Admin Reactor

The first core of the SPDK CPU mask now runs only the admin reactor, and the other cores run the I/O pollers (NVMe-oF target poll groups and ublk target). This keeps I/O load from starving the admin reactor. With a single-core mask, the admin reactor and the pollers share the core.

> **Important:** For stability, configure at least 2 CPU cores for the V2 Data Engine. With a multi-core mask, one core is reserved for the admin reactor, so one fewer core serves I/O.

For more information, see [Issue #14443](https://github.com/longhorn/longhorn/issues/14443) and [Issue #14190](https://github.com/longhorn/longhorn/issues/14190).

#### Configurable NVMe-TCP Initiator I/O Queue Count

You can now limit the number of I/O queues that the kernel NVMe-TCP initiator creates for V2 volumes, instead of one per CPU core, to reduce memory use on high-core-count nodes. Set it globally with the `default-nvme-tcp-nr-io-queues` setting (default `0`, the kernel default) or per volume with `nvmeTcpNrIoQueues`. Valid values are `0` or `1` to `128`, and changes take effect on the next attach.

For more information, see [Issue #13725](https://github.com/longhorn/longhorn/issues/13725) and [Issue #13706](https://github.com/longhorn/longhorn/issues/13706).

### Networking

#### IPv6 and Dual-Stack Support for Backing Images

The backing image manager and data source now follow Longhorn's IP family selection logic and serve on an IPv4 or IPv6 address that matches the cluster or storage network, including IPv4-first and IPv6-first dual-stack clusters. Previously, they always used IPv4.

For more information, see [Issue #14148](https://github.com/longhorn/longhorn/issues/14148) and [Issue #13864](https://github.com/longhorn/longhorn/issues/13864).

#### CNI Compatibility Helm Values for Internal Network Policies

Longhorn v1.12.2 resolves CNI compatibility issues with internal [Network Policies](#internal-network-policies) by providing two new Helm values to manage the affected traffic paths:

- **`networkPolicies.v1DataEngineInitiatorSourceCIDRs`**: Controls source filtering for V1 iSCSI on TCP port 3260. An empty list leaves this port without source filtering, allowing any source that can reach instance-manager to connect to TCP/3260. If populated, the CIDRs restrict connections to the effective sources observed by the CNI, so the required values are CNI-specific.
- **`networkPolicies.recoveryBackendAdditionalIngressPorts`**: Adds TCP ingress ports to the recovery backend (defaults to an empty list). Add `15008` when using Istio Ambient, which uses HTTP-Based Overlay Network Environment (HBONE) on this port. This should only be configured for applicable mesh transports.

For migration instructions from v1.12.1 and targeted workarounds, see [Troubleshooting volume attachment stuck due to CNI NetworkPolicies](../../../kb/troubleshooting-volume-attachment-stuck-cni-networkpolicies).

### Important Fixes

#### Data Loss During Replica Rebuilds with Concurrent Unaligned Writes

Fixes a bug in which acknowledged writes could be silently lost during a V1 replica rebuild. Concurrent writes smaller than 4 KiB to the same 4 KiB sector (for example, a database transaction log using 512-byte writes) could overwrite each other because the read-modify-write sequence was not locked. Longhorn now serializes these writes with a range lock. Users running such workloads on V1 volumes are strongly encouraged to upgrade.

For more information, see [Issue #14451](https://github.com/longhorn/longhorn/issues/14451) and [Issue #14447](https://github.com/longhorn/longhorn/issues/14447).

#### Replica Rebuild Failure Caused by a Lost gRPC TCP Keepalive

Fixes V1 replica rebuilds that randomly failed on busy networks because a single lost TCP keepalive terminated the idle sync-agent gRPC connection after 20 seconds. The sync-agent now uses the operating system's default keepalive parameters.

For more information, see [Issue #13768](https://github.com/longhorn/longhorn/issues/13768) and [Issue #13703](https://github.com/longhorn/longhorn/issues/13703).

#### V2 Instance Manager Pod Crashes

Fixes several critical issues in which `spdk_tgt` aborted and brought down the V2 instance-manager pod, taking every V2 volume on the node offline:

- **Replica rebuild finishing under I/O:** If suspending the engine frontend timed out, the rebuild switched the parent of the destination replica head while it was still serving I/O, causing the `bdev_channel_destroy_resource: Assertion 'TAILQ_EMPTY(&ch->io_submitted)' failed` abort. This is more likely when many replicas are rebuilt under load, such as during a live upgrade. See [Issue #14495](https://github.com/longhorn/longhorn/issues/14495) and [Issue #14411](https://github.com/longhorn/longhorn/issues/14411).
- **Replica rebuilds:** `spdk_tgt` could abort with `double free or corruption (fasttop)` during replica rebuilds. See [Issue #14484](https://github.com/longhorn/longhorn/issues/14484) and [Issue #14482](https://github.com/longhorn/longhorn/issues/14482).
- **Large-block reads in interrupt mode:** Large reads (for example, 1 MiB at a high queue depth) could flood the NVMe-oF TCP target with flush retries, and a retry could run after its connection was freed, causing the `spdk_for_each_channel: Assertion 'false' failed` abort. See [Issue #14162](https://github.com/longhorn/longhorn/issues/14162) and [Issue #14095](https://github.com/longhorn/longhorn/issues/14095).
- **Deleting a snapshot of an expanded volume:** Deleting a snapshot that is smaller than its child and not a multiple of 512 MiB could leave lvol metadata that SPDK fails to load, causing the instance-manager pod to crash-loop after the next restart or reboot. See [Issue #14347](https://github.com/longhorn/longhorn/issues/14347) and [Issue #14344](https://github.com/longhorn/longhorn/issues/14344).

#### Engine Fault Caused by a V2 Replica Rebuild Destination Failure

Fixes a critical issue in which a failure while setting up a rebuild on the destination replica faulted the entire engine and recreated the frontend, even though healthy replicas remained. Now only the failed destination replica is marked `ERR`, and the engine, frontend, and I/O are preserved.

For more information, see [Issue #13780](https://github.com/longhorn/longhorn/issues/13780) and [Issue #13673](https://github.com/longhorn/longhorn/issues/13673).

#### Sharding Storage Volume Write Stall on arm64

Fixes a lost wakeup in the SPDK erasure-coding bdev that could stall writes and leave the SPDK target unresponsive, blocking volume deletion until the instance-manager pod was restarted. The race is more likely on arm64. This affects the experimental [Sharding Storage](#sharding-storage-experimental) feature.

For more information, see [Issue #13895](https://github.com/longhorn/longhorn/issues/13895) and [Issue #13789](https://github.com/longhorn/longhorn/issues/13789).

---

## Changes in v1.12.1

### V2 Data Engine

#### Fast Volume Cloning

Longhorn v1.12.1 enhances fast volume cloning for the V2 Data Engine. A `linked-clone` volume shares data blocks with its source instead of copying data. With the new architecture, a source replica can share its data blocks with multiple linked-clone volumes, and multiple clone replicas can be created in parallel.

Linked-clone volumes now support most operations available to regular volumes, including snapshots, backups, expansion, replica rebuilding, and use as the source of nested linked clones.

The new architecture is not compatible with clones created in v1.12.0 or earlier. See [Deprecation of legacy v2 linked clone volumes](#deprecation-of-legacy-v2-linked-clone-volumes).

For more information, see [Issue #12552](https://github.com/longhorn/longhorn/issues/12552) and [CSI Volume Clone](../snapshots-and-backups/csi-volume-clone).

#### CPU Core Allocation with the Kubernetes CPU Manager

Longhorn v1.12.1 can allocate exclusive CPU cores to the SPDK target daemon, which runs in each V2 Instance Manager pod, through the Kubernetes CPU Manager by using the `data-engine-number-of-cpu-cores` setting.

The setting can be applied only when the kubelet CPU Manager policy is set to `static` on all worker nodes; otherwise, the update is rejected. When the value is positive, it takes precedence, and `data-engine-cpu-mask` is ignored.

For more information, see [Issue #13248](https://github.com/longhorn/longhorn/issues/13248).

#### Host CPU Isolation

The `data-engine-cpu-isolation-enabled` setting now also configures host network Receive Packet Steering (RPS) to steer RX softirq processing away from the CPU cores used by the SPDK target daemon, in addition to hardware IRQs and unbound kernel workqueue workers. Without this, the kernel can distribute incoming network packets to the SPDK reactor cores, and the resulting softirq work competes with the reactor's busy-poll loop, degrading volume I/O under network load.

For more information, see [Issue #13483](https://github.com/longhorn/longhorn/issues/13483) and [Issue #13502](https://github.com/longhorn/longhorn/issues/13502).

#### SPDK iobuf Pool Size Configuration

Longhorn v1.12.1 allows tuning the SPDK iobuf buffer pools used by the V2 Data Engine. The `data-engine-iobuf-large-pool-size` and `data-engine-iobuf-small-pool-size` settings configure the large and 8 KiB small buffer pools, respectively. Increasing the small pool can relieve buffer exhaustion under high-queue-depth workloads with small I/O sizes. Because iobuf pools can only be sized at SPDK target startup, changing either setting recreates V2 Instance Manager pods that have no running instances.

For more information, see [Issue #13322](https://github.com/longhorn/longhorn/issues/13322) and [Issue #13674](https://github.com/longhorn/longhorn/issues/13674).

### Sharding Storage (Experimental)

Longhorn v1.12.1 introduces storage sharding as an experimental data protection and storage layout feature built on the V2 Data Engine. Instead of storing a full copy of the volume on each replica, sharding uses erasure coding to encode written data into data and parity chunks, which are distributed across multiple nodes. This allows a volume to grow beyond the capacity of a single disk or node while using less disk space to achieve the same level of fault tolerance.

Because this feature is experimental, it is intended for evaluation and testing only and is not recommended for production use.

For more information, see [Issue #1061](https://github.com/longhorn/longhorn/issues/1061) and [Sharding Storage](../advanced-resources/sharding-storage).

### Networking

#### Internal Network Policies

Longhorn v1.12.1 enables ingress `NetworkPolicy` resources for internal component endpoints and RPCs by default, including the instance-manager gRPC endpoint used for engine control. These policies are enforced only when the cluster has a network plugin that supports and enforces Kubernetes `NetworkPolicy`. Without such a provider, the resources are created but do not affect traffic and do not need to be removed. For the CNI compatibility Helm values added in v1.12.2, see [CNI Compatibility Helm Values for Internal Network Policies](#cni-compatibility-helm-values-for-internal-network-policies).

The [CNI Plugin Compatibility](../best-practices#cni-plugin-compatibility) table lists the Kubernetes distribution and CNI combinations that the Longhorn project has validated with `networkPolicies.restrictInternalTraffic` enabled. If your CNI enforces `NetworkPolicy` but your distribution and CNI combination is not listed, test the policies in your target environment before upgrading. For policy behavior and configuration details, see [Network Policies](../advanced-resources/security/network-policy).

> **Note:**
> ServiceMonitor discovery does not automatically authorize network traffic. Cross-namespace Prometheus scrapers might be blocked by the Longhorn Manager's network policy. To allow this traffic, apply a scoped additive policy as detailed in the [Prometheus and Grafana setup](../monitoring/prometheus-and-grafana-setup) guide.

For Helm installations, `networkPolicies.restrictInternalTraffic` controls the internal policies and defaults to `true`. Leave this setting enabled unless the policies block traffic required by your environment or you manage the policies separately. To disable the policies, set `networkPolicies.restrictInternalTraffic=false` in the values file or pass `--set networkPolicies.restrictInternalTraffic=false` when running or retrying `helm upgrade`. Use `--reuse-values` with `helm upgrade` when appropriate to retain previous release settings. This setting is independent of `networkPolicies.enabled`, which controls only the Longhorn UI frontend policy.

After a successful upgrade with `networkPolicies.restrictInternalTraffic=false`, the six internal `NetworkPolicy` templates are omitted from the rendered output, and policies owned by the Helm release are removed. Preview the rendered output with `helm upgrade --dry-run` or `helm template`; do not add `--reuse-values` to `helm template`. If installed, `helm diff` can optionally compare the changes.

For manifest installations, no action is required if the policies are not enforced or do not block required traffic. If the internal policies must be disabled, delete only these six `NetworkPolicy` resources:

- `backing-image-data-source`
- `backing-image-manager`
- `instance-manager`
- `longhorn-manager`
- `longhorn-recovery-backend`
- `longhorn-webhook`

These resources are defined in `longhorn.yaml` and `longhorn-okd.yaml`. Do not use `kubectl delete -f` on an entire Longhorn manifest or delete the Longhorn installation. Applying either unmodified manifest later recreates the policies.

If an upgrade fails because these policies block required traffic, disable or remove the internal policies as appropriate and retry the same upgrade.

For more information, see [Issue #13438](https://github.com/longhorn/longhorn/issues/13438).

#### Instance Manager gRPC mTLS Coverage

When the `longhorn-grpc-tls` secret is configured, the remaining instance-manager gRPC services now also require mutual TLS. Plaintext clients and clients without a valid certificate are rejected.

For more information, see [Issue #7787](https://github.com/longhorn/longhorn/issues/7787) and [MTLS Support](../advanced-resources/security/mtls-support).

---

## Changes in v1.12.0

### V2 Data Engine

#### General Availability

The V2 Data Engine is generally available in Longhorn v1.12.0. This milestone reflects improvements in stability, operational safety, networking support, and feature maturity, making V2 volumes suitable for production use in supported environments.

For a summary of the current data engine behavior differences and feature support, see [Data Engine Comparison](../data-engine-comparison).

For more information, see [Issue #6229](https://github.com/longhorn/longhorn/issues/6229).

#### Default CPU Allocation

Longhorn v1.12.0 changes the default `data-engine-cpu-mask` from `0x1` (1 CPU core) to `0x3` (2 CPU cores). V2 Data Engine uses a busy-polling reactor model where the master reactor handles both I/O polling and management RPCs. When only a single core is assigned, heavy I/O workloads can delay or starve RPC processing, resulting in increased latency, timeout events, and operational instability.

Assigning 2 or more cores allows I/O and management tasks to run on separate reactors, improving responsiveness and operational stability. In v1.12.2, the first core is further dedicated exclusively to the admin reactor; see [Dedicated CPU Core for the SPDK Admin Reactor](#dedicated-cpu-core-for-the-spdk-admin-reactor).

For more information, see [Issue #13237](https://github.com/longhorn/longhorn/issues/13237) and [Configurable CPU Cores](../advanced-resources/v2-data-engine/configurable-cpu-cores).

#### V2 Dedicated CPU Requirements

When assigning CPU cores to the V2 Data Engine, ensure that the V2 instance-manager pod has enough guaranteed CPU resources to cover the assigned cores. This provides dedicated CPU availability for SPDK reactors, prevents CPU contention, and helps maintain predictable performance and V2 Data Engine stability.

You can verify that the guaranteed CPU resources match the CPU cores specified by `data-engine-cpu-mask` or `data-engine-number-of-cpu-cores`. For more details, see [Guaranteed Instance Manager CPU](../references/settings/#guaranteed-instance-manager-cpu), [Data Engine CPU Mask](../references/settings/#data-engine-cpu-mask), and [Data Engine Number of CPU Cores](../references/settings/#data-engine-number-of-cpu-cores).

#### IPv6 Support

V2 volumes now support single-stack IPv6 Kubernetes clusters. For dual-stack cluster support and its limitations, see [Dual-Stack Cluster Support](#dual-stack-cluster-support).

For more information, see [Issue #10928](https://github.com/longhorn/longhorn/issues/10928).

### Scheduling

#### Topology-Aware PV Node Affinity Control

Longhorn v1.12.0 adds the `csi-allowed-topology-keys` setting and `strictTopology` StorageClass parameter for more precise control of PV `nodeAffinity`. These options allow users to limit which topology keys are propagated and, with `WaitForFirstConsumer`, pin the PV to the selected node topology when needed.

For more information, see [Issue #12684](https://github.com/longhorn/longhorn/issues/12684) and [Topology-Aware Provisioning](../nodes-and-volumes/nodes/topology-aware-provisioning).

### Stability

#### Configurable Engine Image Pod Liveness Probe

Longhorn v1.12.0 adds settings to configure the engine-image DaemonSet liveness probe period, timeout, and failure threshold. These settings help reduce unnecessary engine-image pod restarts on resource-constrained clusters, especially during upgrades or transient CPU spikes.

For more information, see [Issue #12846](https://github.com/longhorn/longhorn/issues/12846) and [Settings](../references/settings#engine-image-pod-liveness-probe-period).

### Resource Efficiency

#### Longhorn Manager Memory Optimization

Longhorn v1.12.0 optimizes longhorn-manager informer caching to reduce memory usage, especially in large clusters with high pod counts. This lowers cluster-wide memory overhead caused by repeated caching of non-Longhorn pod data on every manager instance.

For more information, see [Issue #12771](https://github.com/longhorn/longhorn/issues/12771).

### Networking

#### Dual-Stack Cluster Support

Longhorn supports dual-stack Kubernetes clusters under a specific requirement: all nodes must be configured with their IP families in the same order (either all IPv4-first, or all IPv6-first). When the order is consistent, Longhorn uses the first IP family of each node and operates correctly. This applies to both the V1 and V2 Data Engines.

> **Warning:** Dual-stack clusters with mixed IP family ordering across nodes are not supported and may result in connectivity failures between replicas and the engine.

For more information, see [Issue #11531](https://github.com/longhorn/longhorn/issues/11531).

### Monitoring

#### Toggle Kubernetes Metrics Server Integration

Longhorn v1.12.0 adds the `Kubernetes Metrics Server Metrics Enabled` setting to disable metrics-server-dependent metrics when the Kubernetes Metrics Server API is unavailable. This reduces repeated scrape warnings and unnecessary API calls while preserving other Longhorn metrics.

For more information, see [Issue #13011](https://github.com/longhorn/longhorn/issues/13011) and [Settings](../references/settings#kubernetes-metrics-server-metrics-enabled).

### Command-Line Tool

#### On-Demand Snapshot Checksum Calculation

Longhorn v1.12.0 adds `longhornctl` support for triggering on-demand snapshot checksum calculation. This is useful when snapshot checksum recalculation needs to be requested without waiting for the periodic integrity-check schedule.

The command can target a specific volume, all volumes on a specific node, or all volumes in the cluster. The checksum operation runs asynchronously in the background.

For more information, see [Issue #11442](https://github.com/longhorn/longhorn/issues/11442) and [On-Demand Snapshot Checksum Calculation](../advanced-resources/data-integrity/on-demand-snapshot-data-integrity).

### Important Fixes

#### Instance Manager Panic During Replica Rebuild

Longhorn v1.12.0 fixes an instance-manager panic that could occur during replica rebuild storms. In affected environments, the panic could terminate all iSCSI targets served by the instance-manager and trigger cascading volume detachments across multiple PVCs.

For more information, see [Issue #13087](https://github.com/longhorn/longhorn/issues/13087).

#### Replica Rebuild Progress Reporting

Longhorn v1.12.0 fixes a replica rebuild progress reporting bug that could display values greater than 100% after file-sync retries on unstable networks. Progress accounting is now reset correctly for retried files, so rebuild progress remains within the valid 0% to 100% range.

For more information, see [Issue #12949](https://github.com/longhorn/longhorn/issues/12949).

#### Replica Auto-Balance Scheduling Loop

Longhorn v1.12.0 fixes a regression in replica auto-balance that could trigger a repeated replica create-and-delete loop when `Replica Auto Balance` was set to `best-effort`. In affected clusters, Longhorn could keep scheduling an extra replica instead of stabilizing at the configured replica count.

For more information, see [Issue #12926](https://github.com/longhorn/longhorn/issues/12926).

#### Replica CR Leak During Failed Local Scheduling

Longhorn v1.12.0 fixes a replica scheduling issue where large numbers of stopped Replica CRs could accumulate when `dataLocality` was set to `best-effort` and the node did not have enough eligible local disk space for another replica. In affected clusters, recurring reconciliation could keep creating placeholder Replica CRs instead of reusing a single failed-schedule placeholder.

For more information, see [Issue #13152](https://github.com/longhorn/longhorn/issues/13152).

#### CSI Storage Capacity Tracking

Longhorn v1.12.0 fixes a CSIStorageCapacity scheduling issue that could cause compute nodes without Longhorn disks to report zero capacity and be rejected by `WaitForFirstConsumer` scheduling. In affected clusters with separated compute and storage nodes, new PVCs could remain pending even though eligible storage was available on storage nodes.

For more information, see [Issue #12807](https://github.com/longhorn/longhorn/issues/12807) and [Settings](../references/settings#csi-storage-capacity-tracking).

#### Encrypted Volume Size Correction

Longhorn reserves an additional 16 MiB of raw capacity for the LUKS2 metadata used by encrypted volumes, allowing the mapped device to expose the full capacity requested by the workload. Previously, the metadata was taken from usable capacity, so a requested 1 GiB encrypted volume exposed only 1008 MiB. This discrepancy could cause operations such as block-level copies between equally sized unencrypted and encrypted volumes to fail.

- **V1 Data Engine**: This correction was introduced in Longhorn v1.12.0. Existing encrypted V1 volumes created with v1.11.x or earlier receive the additional capacity automatically when their engine image is upgraded to v1.12 or later. Existing data is preserved. Encrypted migratable V1 volumes cannot be live-migrated while using an engine image with a CLI API version earlier than 12; upgrade the engine image first.
- **V2 Data Engine**: Longhorn v1.12.1 applies the correction to newly created encrypted V2 volumes.

> **Notice:** Existing encrypted V2 volumes upgraded from v1.11.3 or v1.12.0 do not receive the additional 16 MiB of raw capacity and continue to expose 16 MiB less than requested. Existing data is preserved.

For more information, see [Issue #9205](https://github.com/longhorn/longhorn/issues/9205) and [Issue #13163](https://github.com/longhorn/longhorn/issues/13163).
