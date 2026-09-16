---
title: Important Notes
weight: 1
---

This page summarizes the key notes for Longhorn v{{< current-version >}}.
For the full release note, see the Longhorn v{{< current-version >}} release notes on GitHub.

- [Breaking Changes](#breaking-changes)
  - [Deprecation of legacy v2 linked clone volumes](#deprecation-of-legacy-v2-linked-clone-volumes)
- [V2 Data Engine](#v2-data-engine)
  - [General Availability](#general-availability)
  - [Notice](#notice)
    - [Volume Attach Latency at Scale](#volume-attach-latency-at-scale)
    - [ARM64 NVMe-backed Block-Type Node Disk Limitation](#arm64-nvme-backed-block-type-node-disk-limitation)
    - [UBLK Frontend Kernel Limitation](#ublk-frontend-kernel-limitation)
    - [Longhorn System Upgrade](#longhorn-system-upgrade)
  - [Full Interrupt Mode](#full-interrupt-mode)
  - [V2 Dedicated CPU Requirements](#v2-dedicated-cpu-requirements)
  - [CPU Isolation Enabled by Default](#cpu-isolation-enabled-by-default)
- [Storage Sharding (Experimental)](#storage-sharding-experimental)
- [Important Fixes](#important-fixes)
  - [Linked-Clone Backup Restore](#linked-clone-backup-restore)
- [General](#general)
  - [Kubernetes Version Requirement](#kubernetes-version-requirement)
  - [Manual Checks Before Upgrade](#manual-checks-before-upgrade)
- [Scheduling](#scheduling)
  - [Volume Topology Constraint](#volume-topology-constraint)
  - [Scheduler Extender](#scheduler-extender)
- [Resource Efficiency](#resource-efficiency)
  - [Longhorn Global Manager](#longhorn-global-manager)
- [Snapshots and Backups](#snapshots-and-backups)
  - [Volume Group Snapshot Support](#volume-group-snapshot-support)
- [Networking](#networking)
  - [Internal Network Policies](#internal-network-policies)

## Breaking Changes

### Deprecation of legacy v2 linked clone volumes

V2 linked-clone volumes created in v1.12.0 or earlier are marked as legacy and deprecated starting in v1.12.1. The new linked-clone architecture introduced in [Ticket #12552](https://github.com/longhorn/longhorn/issues/12552) is not compatible with the legacy design.

After upgrading to v1.12.1 or later, **legacy linked-clone volumes cannot be operated on except for detachment and deletion**.

To replace, create new linked-clone volumes from the same source volumes that back the legacy ones. As long as a legacy volume exists, its source volume is guaranteed to still be present, so you can create a replacement linked clone directly; no data copy is required.

For more information, see [Ticket #12552](https://github.com/longhorn/longhorn/issues/12552).

## V2 Data Engine

### General Availability

The V2 Data Engine is generally available in Longhorn v1.12.0. This milestone reflects improvements in stability, operational safety, networking support, and feature maturity, making V2 volumes suitable for production use in supported environments.

For a summary of the current V1 and V2 behavior differences and feature parity, see [V1 and V2 Volume Behavior and Feature Parity](../v1-v2-volume-behavior-and-feature-parity).

For more information, see [Issue #6229](https://github.com/longhorn/longhorn/issues/6229).

### Notice

#### Volume Attach Latency at Scale

In environments with a growing number of attached V2 volumes, increased attach latency has been observed for subsequent volumes. Initial analysis suggests this may be related to NVMe-TCP connection handling at scale, though the precise layer (SPDK user-space or Linux kernel) has not yet been identified. Further investigation is in progress. For follow-up status, see [Issue #13241](https://github.com/longhorn/longhorn/issues/13241).

#### ARM64 NVMe-backed Block-Type Node Disk Limitation

On ARM64 systems, V2 volumes may experience stuck I/O when SPDK is configured with two or more CPU cores and node disks use the NVMe driver. The root cause may lie in either the Linux kernel or SPDK itself, and further investigation is required. As a workaround, use [AIO-backed node disks](../nodes-and-volumes/nodes/multidisk#using-aio-disks) instead of [NVMe-backed node disks](../nodes-and-volumes/nodes/multidisk#using-nvme-disks) on ARM64 systems. For follow-up status, see [Issue #13243](https://github.com/longhorn/longhorn/issues/13243).

#### UBLK Frontend Kernel Limitation

This feature is experimental. On kernel v6.17, attaching a UBLK volume can cause a kernel panic. Do not use the UBLK frontend on this kernel version.

For more information, see [Issue #13509](https://github.com/longhorn/longhorn/issues/13509) and [UBLK Frontend Support](../advanced-resources/v2-data-engine/ublk-frontend-support).

#### Longhorn System Upgrade

V2 volumes do not support live upgrades between Longhorn v1.12 patch releases and must be detached before upgrading. Support is planned when upgrading from a Longhorn v1.12 release to a Longhorn v1.13 release.

### Full Interrupt Mode

Interrupt mode for the V2 Data Engine, available since v1.10.0, no longer polls for I/O completions in Longhorn v{{< current-version >}}. The kernel wakes the V2 Data Engine when I/O completes, so idle instance-manager pods use very little CPU. Latency can be slightly higher than in polling mode under sustained heavy I/O.

Polling mode remains the default. To enable interrupt mode, set `data-engine-interrupt-mode-enabled` to `{"v2":"true"}`. The setting applies to all V2 volumes and can be changed only when no V2 volumes are attached.

For more information, see:
* [Issue #11662](https://github.com/longhorn/longhorn/issues/11662)
* [Interrupt Mode Support](../advanced-resources/v2-data-engine/interrupt-mode)
* [Data Engine Interrupt Mode Enabled](../references/settings/#data-engine-interrupt-mode-enabled)

### V2 Dedicated CPU Requirements

When assigning CPU cores to the V2 Data Engine, ensure that the V2 instance-manager pod has enough guaranteed CPU resources to cover the assigned cores. This provides dedicated CPU availability for SPDK reactors, prevents CPU contention, and helps maintain predictable performance and V2 Data Engine stability.

You can verify that the guaranteed CPU resources match the CPU cores specified by `data-engine-cpu-mask` or `data-engine-number-of-cpu-cores`. For more details, see [Guaranteed Instance Manager CPU](../references/settings/#guaranteed-instance-manager-cpu), [Data Engine CPU Mask](../references/settings/#data-engine-cpu-mask), and [Data Engine Number of CPU Cores](../references/settings/#data-engine-number-of-cpu-cores).

### CPU Isolation Enabled by Default

Longhorn v{{< current-version >}} enables [Data Engine CPU Isolation](../references/settings/#data-engine-cpu-isolation-enabled) by default for the V2 Data Engine (`{"v2":"true"}`). This keeps hardware interrupts and other kernel work off the CPU cores used by the V2 Data Engine, so it is not interrupted while it processes I/O.

CPU isolation applies only in polling mode. When [interrupt mode](#full-interrupt-mode) is enabled, Longhorn skips it automatically regardless of this setting.

For more information, see:
* [Issue #13724](https://github.com/longhorn/longhorn/issues/13724)
* [Issue #13973](https://github.com/longhorn/longhorn/issues/13973)
* [Data Engine CPU Isolation Enabled](../references/settings/#data-engine-cpu-isolation-enabled)

## Storage Sharding (Experimental)

Longhorn v1.12.1 introduces storage sharding for the V2 Data Engine as an experimental feature. Instead of storing a full copy of the volume on each replica, sharding splits the volume into data and parity chunks using erasure coding and distributes them across multiple nodes. This allows a volume to grow beyond the capacity of a single disk or node while using less disk space to achieve the same level of fault tolerance.

Because this feature is experimental, it is intended for evaluation and testing only and is not recommended for production use.

For more information, see [Issue #1061](https://github.com/longhorn/longhorn/issues/1061) and [Sharding with Erasure Coding](../advanced-resources/v2-data-engine/sharding).

## Important Fixes

### Linked-Clone Backup Restore

Backups of V2 linked-clone volumes now record the source volume and the snapshot the clone was created from. A restore fails if the source volume or that snapshot no longer exists.

Previously, the restore succeeded and produced a corrupted volume.

For more information, see [Issue #13714](https://github.com/longhorn/longhorn/issues/13714) and [CSI Volume Clone](../snapshots-and-backups/csi-volume-clone).

## General

### Kubernetes Version Requirement

Because the CSI external provisioner is upgraded to v6.3.0, all clusters must be running Kubernetes v1.34 or later before upgrading to Longhorn v{{< current-version >}}.

### Manual Checks Before Upgrade

Automated pre-upgrade checks do not cover all scenarios. Manual checks via kubectl or the UI are recommended:

- Ensure all V2 Data Engine volumes are detached and replicas are stopped. The V2 engine does not support live upgrades.
- Avoid upgrading when volumes are in the "Faulted" state, as unusable replicas may be deleted, causing permanent data loss if no backups exist.
- Avoid upgrading if a failed BackingImage exists. See [Backing Image](../advanced-resources/backing-image/backing-image) for details.
- Creating a [Longhorn system backup](../advanced-resources/system-backup-restore/backup-longhorn-system) before upgrading is recommended to ensure recoverability.

## Scheduling

### Volume Topology Constraint

Longhorn v{{< current-version >}} adds the `volumeTopology` StorageClass parameter to keep a volume's replicas in the zone or region where it was provisioned. Previously, zone labels only spread replicas apart, so a rebuild could place a replica in a different zone from the workload.

- `any` (default): no constraint.
- `zonal`: replicas stay in the zone chosen at provisioning time, including during rebuilds and replica count changes. With `WaitForFirstConsumer`, this is the zone the pod is scheduled to.
- `regional`: same as `zonal`, but for regions.

If the chosen zone or region has no capacity, scheduling waits rather than falling back to another one. Clusters without topology labels are unaffected. A StorageClass with `volumeTopology: zonal` and `replicaZoneSoftAntiAffinity: disabled` is rejected at provisioning time.

For more information, see [Issue #13493](https://github.com/longhorn/longhorn/issues/13493) and [Topology-Aware Provisioning](../nodes-and-volumes/nodes/topology-aware-provisioning).

### Scheduler Extender

Longhorn v{{< current-version >}} adds a scheduler extender that lets kube-scheduler check actual Longhorn disk capacity when placing pods. Without it, kube-scheduler relies on `CSIStorageCapacity` objects, which have three limitations:

- The reported capacity lags behind when many pods are created at once.
- A pod with several PVCs is not checked against the combined space it needs across disks.
- A pod whose PVCs are already bound is rescheduled without any capacity check.

The extender reads Longhorn node and disk state directly. It also pins a restarted pod to the node that already holds all of its replicas, which makes it most useful for volumes with `best-effort` data locality.

The extender runs inside longhorn-manager under leader election, so there is no extra component to deploy. It requires a change to the kube-scheduler configuration, which is not possible on managed Kubernetes offerings such as GKE and EKS.

For more information, see [Issue #12591](https://github.com/longhorn/longhorn/issues/12591).

## Resource Efficiency

### Longhorn Global Manager

Longhorn v{{< current-version >}} moves the cluster-wide pod and PV controllers out of the longhorn-manager DaemonSet into a new `longhorn-global-manager` Deployment. Previously, every longhorn-manager pod watched every pod in the cluster, so kube-apiserver load and longhorn-manager memory grew with the number of nodes and pods. Now one elected leader runs these controllers, and longhorn-manager watches only the `longhorn-system` namespace.

The Deployment is created on install and upgrade, with three replicas by default (`longhornGlobalManager.replicas`): one leader and two standby replicas ready to take over. Before upgrading, make sure at least one of its pods can be scheduled. See [Upgrading Longhorn Manager](../deploy/upgrade/longhorn-manager).

For more information, see:
* [Issue #13059](https://github.com/longhorn/longhorn/issues/13059)
* [Longhorn Global Manager](../terminology/#longhorn-global-manager)
* [Longhorn Global Manager Settings](../references/helm-values/#longhorn-global-manager-settings)
* [Networking](../references/networking/#longhorn-global-manager)

## Snapshots and Backups

### Volume Group Snapshot Support

Longhorn v{{< current-version >}} can snapshot a set of volumes as one group with a single request. You can create snapshot groups from the Longhorn UI, with kubectl, or by creating Kubernetes `VolumeGroupSnapshot` objects through CSI. The CSI path also supports group backups.

The UI and kubectl paths work out of the box. The CSI path is disabled by default: it requires the VolumeGroupSnapshot CRDs, the `CSIVolumeGroupSnapshot` feature gate on the snapshot-controller, and a Longhorn toggle. For the setup steps, see [Enable CSI Volume Group Snapshot Support](../snapshots-and-backups/csi-snapshot-support/enable-csi-volume-group-snapshot-support).

> **Important: Snapshot Consistency**
> Each member volume is snapshotted independently, meaning the group is **not** captured at a single point in time. Application-level consistency across the group is future work built on top of this feature ([Issue #2128](https://github.com/longhorn/longhorn/issues/2128)).

For more information, see:
* [Issue #13349](https://github.com/longhorn/longhorn/issues/13349)
* [Create a Snapshot Group](../snapshots-and-backups/snapshot-groups)
* [CSI VolumeGroupSnapshot Associated with Longhorn Snapshot Group](../snapshots-and-backups/csi-snapshot-support/csi-volume-group-snapshot)

## Networking

### Internal Network Policies

Longhorn v1.12.1 enables ingress `NetworkPolicy` resources for internal component endpoints and RPCs by default, including the instance-manager gRPC endpoint used for engine control. The policies take effect only when the CNI plugin enforces `NetworkPolicy`. Otherwise, the resources are created but have no effect. For details, see [Network Policy](../advanced-resources/security/network-policy).

Longhorn v1.12.2 resolves the CNI compatibility issues found in v1.12.1 by providing two Helm values to manage the affected traffic paths:

- **`networkPolicies.v1DataEngineInitiatorSourceCIDRs`**: Controls source filtering for V1 iSCSI on TCP port 3260. An empty list leaves this port without source filtering, allowing any source that can reach instance-manager to connect to TCP/3260. If populated, the CIDRs restrict connections to the effective sources observed by the CNI, so the required values are CNI-specific.
- **`networkPolicies.recoveryBackendAdditionalIngressPorts`**: Adds TCP ingress ports to the recovery backend (defaults to an empty list). Add `15008` when using Istio Ambient, which uses HTTP-Based Overlay Network Environment (HBONE) on this port. This should only be configured for applicable mesh transports.

For migration instructions from v1.12.1 and targeted workarounds, see [Troubleshooting volume attachment stuck due to CNI NetworkPolicies](../../../kb/troubleshooting-volume-attachment-stuck-cni-networkpolicies).

For the Kubernetes distribution and CNI combinations validated with `networkPolicies.restrictInternalTraffic` enabled, see [CNI Plugin Compatibility](../best-practices#cni-plugin-compatibility). If your combination is not listed, test the policies in a non-production environment before upgrading.

> **Note:**
> ServiceMonitor discovery does not automatically authorize network traffic. Cross-namespace Prometheus scrapers might be blocked by the Longhorn Manager's network policy. To allow this traffic, apply a scoped additive policy as detailed in the [Prometheus and Grafana setup](../monitoring/prometheus-and-grafana-setup) guide.

For Helm installations, opt out by explicitly setting `networkPolicies.restrictInternalTraffic=false` in the values file or passing `--set networkPolicies.restrictInternalTraffic=false` when running or retrying `helm upgrade`. Use `--reuse-values` with `helm upgrade` when appropriate to retain previous release settings. Keep this separate from `networkPolicies.enabled`, which controls only the UI frontend policy. See the [Helm upgrade documentation](https://helm.sh/docs/helm/helm_upgrade/) for command behavior.

After a successful upgrade with `networkPolicies.restrictInternalTraffic=false`, the six internal NetworkPolicy templates render nothing (they are excluded from the output), and policies owned by the Helm release are removed. Preview the rendered output with `helm upgrade --dry-run` or `helm template`; do not add `--reuse-values` to `helm template`. If installed, `helm diff` can optionally compare the changes.

For manifest installations, delete only these six internal NetworkPolicy resources:

- `backing-image-data-source`
- `backing-image-manager`
- `instance-manager`
- `longhorn-manager`
- `longhorn-recovery-backend`
- `longhorn-webhook`

These resources are defined in `longhorn.yaml` and `longhorn-okd.yaml`. Do not use `kubectl delete -f` on an entire Longhorn manifest or delete the Longhorn installation. Applying either unmodified manifest later recreates the policies.

If an upgrade fails because these policies block required traffic, set `networkPolicies.restrictInternalTraffic=false` and retry the same upgrade.

For more information, see [Issue #13438](https://github.com/longhorn/longhorn/issues/13438).
