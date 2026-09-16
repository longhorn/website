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
  - [V2 Dedicated CPU Requirements](#v2-dedicated-cpu-requirements)
  - [CPU Isolation Enabled by Default](#cpu-isolation-enabled-by-default)
- [Storage Sharding (Experimental)](#storage-sharding-experimental)
- [General](#general)
  - [Kubernetes Version Requirement](#kubernetes-version-requirement)
  - [Manual Checks Before Upgrade](#manual-checks-before-upgrade)
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

This feature is experimental. The UBLK frontend works on all supported Linux kernels but may cause a kernel panic with kernel v6.17. 

For more information, see [GitHub Issue #11977](https://github.com/longhorn/longhorn/issues/11977) and [GitHub Issue #13509](https://github.com/longhorn/longhorn/issues/13509).

#### Longhorn System Upgrade

V2 volumes do not support live upgrades between Longhorn v1.12 patch releases and must be detached before upgrading. Support is planned when upgrading from a Longhorn v1.12 release to a Longhorn v1.13 release.

### V2 Dedicated CPU Requirements

When assigning CPU cores to the V2 Data Engine, ensure that the V2 instance-manager pod has enough guaranteed CPU resources to cover the assigned cores. This provides dedicated CPU availability for SPDK reactors, prevents CPU contention, and helps maintain predictable performance and V2 Data Engine stability.

You can verify that the guaranteed CPU resources match the CPU cores specified by `data-engine-cpu-mask` or `data-engine-number-of-cpu-cores`. For more details, see [Guaranteed Instance Manager CPU](../references/settings/#guaranteed-instance-manager-cpu), [Data Engine CPU Mask](../references/settings/#data-engine-cpu-mask), and [Data Engine Number of CPU Cores](../references/settings/#data-engine-number-of-cpu-cores).

### CPU Isolation Enabled by Default

Longhorn v{{< current-version >}} enables [Data Engine CPU Isolation](../references/settings/#data-engine-cpu-isolation-enabled) by default for the V2 Data Engine (`{"v2":"true"}`). This ensures that CPU cores are dedicated to the V2 Data Engine.

For more information, see [Issue #13724](https://github.com/longhorn/longhorn/issues/13724) and [Data Engine CPU Isolation Enabled](../references/settings/#data-engine-cpu-isolation-enabled).

## Storage Sharding (Experimental)

Longhorn v1.12.1 introduces storage sharding for the V2 Data Engine as an experimental feature. Instead of storing a full copy of the volume on each replica, sharding splits the volume into data and parity chunks using erasure coding and distributes them across multiple nodes. This allows a volume to grow beyond the capacity of a single disk or node while using less disk space to achieve the same level of fault tolerance.

Because this feature is experimental, it is intended for evaluation and testing only and is not recommended for production use.

For more information, see [Issue #1061](https://github.com/longhorn/longhorn/issues/1061) and [Sharding with Erasure Coding](../advanced-resources/v2-data-engine/sharding).

## General

### Kubernetes Version Requirement

Because the CSI external snapshotter is upgraded to v8.2.0, all clusters must be running Kubernetes v1.34 or later before upgrading to Longhorn v{{< current-version >}}.

### Manual Checks Before Upgrade

Automated pre-upgrade checks do not cover all scenarios. Manual checks via kubectl or the UI are recommended:

- Ensure all V2 Data Engine volumes are detached and replicas are stopped. The V2 engine does not support live upgrades.
- Avoid upgrading when volumes are in the "Faulted" state, as unusable replicas may be deleted, causing permanent data loss if no backups exist.
- Avoid upgrading if a failed BackingImage exists. See [Backing Image](../advanced-resources/backing-image/backing-image) for details.
- Creating a [Longhorn system backup](../advanced-resources/system-backup-restore/backup-longhorn-system) before upgrading is recommended to ensure recoverability.

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

Longhorn v1.12.1 enables network policy by default. It protects inbound access to internal component endpoints and RPCs, including the instance-manager gRPC endpoint used for engine control. For more details, see [Network Policy](../advanced-resources/security/network-policy).

Longhorn v1.12.2 resolves the CNI compatibility issues described for v1.12.1 by providing two Helm values to manage the affected traffic paths:

- **`networkPolicies.v1DataEngineInitiatorSourceCIDRs`**: Controls source filtering for V1 iSCSI on TCP port 3260. An empty list leaves this port without source filtering, allowing any source that can reach instance-manager to connect to TCP/3260. If populated, the CIDRs restrict connections to the effective sources observed by the CNI, so the required values are CNI-specific.
- **`networkPolicies.recoveryBackendAdditionalIngressPorts`**: Adds TCP ingress ports to the recovery backend (defaults to an empty list). Add `15008` when using Istio Ambient, which uses HTTP-Based Overlay Network Environment (HBONE) on this port. This should only be configured for applicable mesh transports.

For migration instructions from v1.12.1 and targeted workarounds, see [Troubleshooting volume attachment stuck due to CNI NetworkPolicies](../../../kb/troubleshooting-volume-attachment-stuck-cni-networkpolicies).

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
