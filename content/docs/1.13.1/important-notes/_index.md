---
title: Important Notes
weight: 1
---

This page summarizes the key notes for Longhorn v{{< current-version >}}.
For the full release note, see the [Longhorn v1.13.1 release notes](https://github.com/longhorn/longhorn/releases/tag/v1.13.1) on GitHub.

- [Breaking Changes](#breaking-changes)
  - [Deprecation of legacy v2 linked clone volumes](#deprecation-of-legacy-v2-linked-clone-volumes)
  - [Optional restriction of CSI controller Secret access](#optional-restriction-of-csi-controller-secret-access)
- [General](#general)
  - [Kubernetes Version Requirement](#kubernetes-version-requirement)
  - [Manual Checks Before Upgrade](#manual-checks-before-upgrade)
- [V2 Data Engine Notices](#v2-data-engine-notices)
  - [Longhorn System Upgrade](#longhorn-system-upgrade)
  - [Periodic Backups Recommended for V2 Volumes](#periodic-backups-recommended-for-v2-volumes)
  - [Volume Attach Latency at Scale](#volume-attach-latency-at-scale)
  - [ARM64 NVMe-backed Block-Type Node Disk Limitation](#arm64-nvme-backed-block-type-node-disk-limitation)
  - [UBLK Frontend Kernel Limitation](#ublk-frontend-kernel-limitation)
- [Changes in v1.13.1](#changes-in-v1131)
  - [V2 Data Engine](#v2-data-engine)
  - [Node and Disk Management](#node-and-disk-management)
  - [Networking and Security](#networking-and-security)
  - [Helm Chart](#helm-chart)
  - [Important Fixes](#important-fixes)
- [Changes in v1.13.0](#changes-in-v1130)
  - [V2 Data Engine](#v2-data-engine-1)
  - [Sharding Storage (Experimental)](#sharding-storage-experimental)
  - [Important Fixes](#important-fixes-1)
  - [Scheduling](#scheduling)
  - [Resource Efficiency](#resource-efficiency)
  - [Snapshots and Backups](#snapshots-and-backups)
  - [Networking](#networking)

## Breaking Changes

### Deprecation of legacy v2 linked clone volumes

V2 linked-clone volumes created in v1.12.0 or earlier are marked as legacy and deprecated starting in v1.12.1. The new linked-clone architecture introduced in [Ticket #12552](https://github.com/longhorn/longhorn/issues/12552) is not compatible with the legacy design.

After upgrading to v1.12.1 or later, **legacy linked-clone volumes cannot be operated on except for detachment and deletion**.

To replace, create new linked-clone volumes from the same source volumes that back the legacy ones. As long as a legacy volume exists, its source volume is guaranteed to still be present, so you can create a replacement linked clone directly; no data copy is required.

For more information, see [Ticket #12552](https://github.com/longhorn/longhorn/issues/12552).

### Optional restriction of CSI controller Secret access

Longhorn v{{< current-version >}} runs the CSI controller sidecars with the dedicated `longhorn-csi-service-account`, separate from the Longhorn manager and node plugin. The base `longhorn-csi-role` and `longhorn-csi-bind` remain Secret-free.

The released Helm chart and static installation manifests grant the CSI service account **cluster-wide `get` access to core Kubernetes Secrets by default**. The grant is implemented by `longhorn-csi-secret-role` and `longhorn-csi-secret-bind`: the ClusterRole contains only `get` on `secrets`, and the ClusterRoleBinding names exactly `longhorn-csi-service-account` in the Longhorn release namespace. This broad grant is intentional for CSI sidecar compatibility; review it against your cluster's Secret access policy.

The default grant is rendered for both fresh and upgraded installations, regardless of StorageClass parameters. It is static and installation-controlled: it is not created or removed by `longhorn-driver-deployer` startup, so changing StorageClasses does not trigger reconciliation and no deployer restart is needed. Deleting it is not automatically reversed by the deployer; only a later apply with the grant enabled can recreate it. Helm users who do not want controller-side Secret access must set `csi.allowControllerSecretAccess=false`; Helm then renders neither `longhorn-csi-secret-role` nor `longhorn-csi-secret-bind`.

Before disabling access, remove historical provisioner-side Secret parameters from StorageClasses using the migration guide below. Otherwise, new provisioning with those classes can fail. Review any custom controller-side Secret requirements separately.

For installations managed by applying a release manifest, opt out by deleting `longhorn-csi-secret-bind` and keeping that binding out of every future apply. The now-unbound `longhorn-csi-secret-role` may also be removed. Verify the local manifest or overlay will not restore either object. If access is disabled, existing workloads continue to use their node-side Secret references; do not edit or replace their PVs, rotate their encryption keys, or delete their encryption Secrets.

The optional [encrypted-volume Secret migration guide](/kb/how-to-migrate-encrypted-volumes-to-node-only-secrets) covers the historical StorageClass-only cleanup for administrators who choose to opt out. StorageClass parameters are immutable, so the procedure recreates each same-name class after removing only historical `csi.storage.k8s.io/provisioner-secret-*` parameters. Preserve all other fields, including node-side Secret parameters, labels, annotations, and default-class designation. The procedure does not touch existing PVCs, PVs, Longhorn volumes, CSI volume handles, or PV deletion annotations; no backup, detach, rebind, or PV replacement is required. A best-effort Secret read during a later deletion may be logged as denied by the external-provisioner, but deletion continues; do not restore broad controller access or remove PV deletion annotations to suppress that message.

This SC-only migration is documented only for historical provisioner-only parameters. Do not assume that custom `controller-publish-secret-*`, `controller-expand-secret-*`, generic Secret parameters, deprecated parameter spellings, or other custom controller configurations become safe or preserve controller-side behavior after the cleanup.

## General

### Kubernetes Version Requirement

Because the CSI external provisioner is upgraded to v6.3.0 or later, all clusters must be running Kubernetes v1.34 or later before upgrading to Longhorn v{{< current-version >}}.

### Manual Checks Before Upgrade

Automated pre-upgrade checks do not cover all scenarios. Manual checks via `kubectl` or the UI are recommended:

- For V2 Data Engine volumes, check the [V2 live upgrade prerequisites](../deploy/upgrade/v2-instance-upgrade/#prerequisites). If your deployment does not meet these prerequisites, detach all V2 volumes and ensure their replicas are stopped before upgrading.
- Avoid upgrading when volumes are in the "Faulted" state, as unusable replicas may be deleted, causing permanent data loss if no backups exist.
- Avoid upgrading if a failed BackingImage exists. See [Backing Image](../advanced-resources/backing-image/backing-image) for details.
- Create a [Longhorn system backup](../advanced-resources/system-backup-restore/backup-longhorn-system) before upgrading to ensure recoverability.

## V2 Data Engine Notices

### Longhorn System Upgrade

[V2 Data Engine live upgrade](../deploy/upgrade/v2-instance-upgrade/) to Longhorn v{{< current-version >}} is supported from Longhorn v1.12.2 or later. Upgrades from earlier versions, such as Longhorn v1.12.0 and v1.12.1, do not support V2 Data Engine live upgrade.

A live upgrade to v1.13.0 deleted user-created snapshots of V2 volumes. This is fixed in Longhorn v{{< current-version >}}. See [User Snapshots Deleted During V2 Live Upgrade](#user-snapshots-deleted-during-v2-live-upgrade).

For more information, see [V2 Data Engine live upgrade](../deploy/upgrade/v2-instance-upgrade/).

### Periodic Backups Recommended for V2 Volumes

In the V2 Data Engine, if a snapshot deletion or system-snapshot purge fails or is interrupted partway through (for example, by a disk I/O error, exhausted metadata pages, an `spdk_tgt` crash, an instance-manager pod restart, or a node reboot), inconsistent blobstore metadata can cause V2 volume data corruption, `spdk_tgt` crashes, or a disk lvstore load failure.

To protect against potential data loss, configure periodic backups for V2 volumes and avoid restarting V2 instance-manager pods or rebooting nodes while snapshots are being deleted or purged.

For more information, see [Issue #14474](https://github.com/longhorn/longhorn/issues/14474).

### Volume Attach Latency at Scale

In environments with a growing number of attached V2 volumes, increased attach latency has been observed for subsequent volumes. Initial analysis suggests this may be related to NVMe-TCP connection handling at scale, though the precise layer (SPDK user-space or Linux kernel) has not yet been identified. Further investigation is in progress. For follow-up status, see [Issue #13241](https://github.com/longhorn/longhorn/issues/13241).

### ARM64 NVMe-backed Block-Type Node Disk Limitation

On ARM64 systems, V2 volumes may experience stuck I/O when SPDK is configured with two or more CPU cores and node disks use the NVMe driver. The root cause may lie in either the Linux kernel or SPDK itself, and further investigation is required. As a workaround, use [AIO-backed node disks](../nodes-and-volumes/nodes/multidisk#using-aio-disks) instead of [NVMe-backed node disks](../nodes-and-volumes/nodes/multidisk#using-nvme-disks) on ARM64 systems. For follow-up status, see [Issue #13243](https://github.com/longhorn/longhorn/issues/13243).

### UBLK Frontend Kernel Limitation

This feature is experimental. On kernel v6.17, attaching a UBLK volume can cause a kernel panic. Do not use the UBLK frontend on this kernel version.

For more information, see [Issue #13509](https://github.com/longhorn/longhorn/issues/13509) and [UBLK Frontend Support](../advanced-resources/v2-data-engine/ublk-frontend-support).

## Changes in v1.13.1

### V2 Data Engine

#### Dedicated CPU Core for the SPDK Admin Reactor

When `data-engine-cpu-mask` or `data-engine-number-of-cpu-cores` assigns two or more cores, the lowest core in the mask now runs only the SPDK admin reactor, which handles management RPCs. The remaining cores run the I/O pollers for the NVMe-oF target and the UBLK target. Previously, that core handled both, so heavy I/O could delay RPC processing and cause timeouts. With a single core, the admin reactor and the pollers still share it.

> **Important:**
> Assign at least 2 CPU cores to the V2 Data Engine to keep it stable. One of those cores is reserved for the admin reactor, so the default two-core mask leaves one core for I/O. If a node needs more I/O capacity, add more cores.

For more information, see:
* [Issue #14190](https://github.com/longhorn/longhorn/issues/14190)
* [Data Engine CPU Mask](../references/settings/#data-engine-cpu-mask)
* [Data Engine Number of CPU Cores](../references/settings/#data-engine-number-of-cpu-cores)

#### V2 Volume Expansion Keeps the Frontend Connected

Expanding a replicated V2 volume no longer disconnects the frontend. Previously, the expansion tore down and recreated the NVMe-oF target.

For more information, see [Issue #14580](https://github.com/longhorn/longhorn/issues/14580).

#### Settings and Images Synced During Instance Manager Upgrade

After an instance manager upgrade, the `spec.image` and `status.currentImage` of replicated V2 volumes, engines, and replicas are now updated to the instance manager image they run. Previously, `spec.image` kept the old image, which left the resources out of sync with the running instance manager.

The `data-engine-log-level` and `data-engine-log-flags` settings are now applied to the new instance manager while an in-place upgrade is in progress. Previously, the sync was skipped until the upgrade completed, so the new instance manager logged at `DEBUG`, which slowed replica rebuilds and could leave the upgrade waiting for healthy volumes.

For more information, see [Issue #14317](https://github.com/longhorn/longhorn/issues/14317) and [Issue #14390](https://github.com/longhorn/longhorn/issues/14390).

#### Larger Default iobuf Large Pool Size

The default value of `data-engine-iobuf-large-pool-size` is now `6144` instead of `1024`. The larger pool takes 792 MiB of the memory set by `Data Engine Memory Size`, which is 2048 MiB by default.

The new default applies to new installations. An upgraded cluster keeps its current value, so set `data-engine-iobuf-large-pool-size` to `6144` after the upgrade to use the larger pool.

The larger pool gives V2 replica rebuilds under heavy writes more headroom. See [V2 Replica Rebuild Under Load and With Snapshots](#v2-replica-rebuild-under-load-and-with-snapshots).

> **Important:**
> On hosts with 4 or more NUMA nodes, or if you have lowered `Data Engine Memory Size`, `spdk_tgt` might not start with a value of `6144`. In that case, increase `Data Engine Memory Size` and the hugepages on the host, or set this value closer to `1024`.

For more information, see [Issue #14589](https://github.com/longhorn/longhorn/issues/14589) and [Data Engine iobuf Large Pool Size](../references/settings/#data-engine-iobuf-large-pool-size).

### Node and Disk Management

#### Disk Config Not Regenerated on an Unmounted Disk Path

Longhorn no longer creates a new disk config for a disk that already has a recorded UUID. If the disk's filesystem is not mounted (for example, after a node reboot), the disk stays `Ready=False` with reason `DiskFilesystemChanged` until the filesystem is mounted.

Previously, Longhorn found no config file at the empty mount point and created a new one. This wrote a `longhorn-disk.cfg` with a new UUID and a `replicas` directory to whatever was behind the path, such as the root filesystem.

For more information, see [Issue #14102](https://github.com/longhorn/longhorn/issues/14102).

#### Backing Image Manager Restart After Disk Recovery

When a disk becomes `Ready` again (for example, after its filesystem is remounted), Longhorn now recreates the backing image manager pod on that disk. Previously, the pod could not see the backing image files on the remounted disk.

For more information, see [Issue #14111](https://github.com/longhorn/longhorn/issues/14111).

#### Block-Type Disks After Node Reboot

V2 block-type disks on virtio devices (for example, `0000:05:00.0`) no longer stay `Unschedulable` after a node reboot. Previously, Longhorn looked for the disk's logical volume store before the device had finished loading, failed to add the disk, and could not retry.

For more information, see [Issue #12197](https://github.com/longhorn/longhorn/issues/12197).

### Networking and Security

#### V1 iSCSI Rule Removed From the Default Instance Manager NetworkPolicy

With `networkPolicies.restrictInternalTraffic=true` and an empty `networkPolicies.v1DataEngineInitiatorSourceCIDRs`, the instance-manager NetworkPolicy no longer renders a TCP/3260 rule. Previously, the rule had no source restriction, so any pod that could reach an instance-manager pod could log in to the V1 iSCSI target. The V1 initiator runs on the same node as its target, and Kubernetes NetworkPolicy always allows traffic from the pod's own node, so the default configuration is not affected.

> **Important:**
> If your CNI or mesh rewrites the source address of host traffic (for example, Istio Ambient), or if initiators on other hosts connect to the iSCSI frontend, add their source CIDRs to `networkPolicies.v1DataEngineInitiatorSourceCIDRs` before you upgrade. Otherwise, V1 volumes can fail to attach.

The rule is also removed from `longhorn.yaml` and `longhorn-okd.yaml`. For manifest installations, apply a separate NetworkPolicy for TCP/3260 instead.

For more information, see:
* [Issue #14416](https://github.com/longhorn/longhorn/issues/14416)
* [Network Policy](../advanced-resources/security/network-policy)
* [Troubleshooting volume attachment stuck due to CNI NetworkPolicies](../../../kb/troubleshooting-volume-attachment-stuck-cni-networkpolicies)

#### Development Packages Removed From Runtime Images

The instance-manager image no longer includes the `-devel` packages and build tools that were only needed at build time. This reduces image size and the number of packages reported by vulnerability scanners.

For more information, see [Issue #14135](https://github.com/longhorn/longhorn/issues/14135).

### Helm Chart

#### Topology Spread Constraints for Longhorn Global Manager

The Helm chart adds `longhornGlobalManager.topologySpreadConstraints` (default `[]`) so the `longhorn-global-manager` replicas can be spread across zones or nodes.

For more information, see [Issue #14224](https://github.com/longhorn/longhorn/issues/14224) and [Longhorn Global Manager Settings](../references/helm-values/#longhorn-global-manager-settings).

### Important Fixes

#### Data Loss During V1 Replica Rebuild With Unaligned Concurrent Writes

A V1 volume no longer loses data when a write whose offset or length is not a multiple of 4 KiB arrives while a replica is rebuilding. Previously, such a write could overwrite a concurrent write to the same 4 KiB block with stale data.

For more information, see [Issue #14447](https://github.com/longhorn/longhorn/issues/14447).

#### Missing Data After Fast Replica Rebuild

Fast replica rebuild no longer skips a snapshot file whose content was changed by a snapshot purge. Previously, the purge left the old checksum file in place, so the rebuild skipped the file and the rebuilt replica was missing data.

For more information, see [Issue #14096](https://github.com/longhorn/longhorn/issues/14096).

#### User Snapshots Deleted During V2 Live Upgrade

A V2 Data Engine live upgrade now keeps the user-created snapshots of V2 volumes. Previously, a live upgrade to v1.13.0 deleted them.

For more information, see [Issue #14582](https://github.com/longhorn/longhorn/issues/14582).

#### V2 Replica Rebuild Under Load and With Snapshots

Three problems with V2 replica rebuilds are fixed.

- Heavy writes during replica rebuilds no longer stop I/O on every V2 volume on the node. Previously, I/O stayed stopped until the instance-manager pod was deleted. See [Issue #14589](https://github.com/longhorn/longhorn/issues/14589).
- A rebuild that starts during a snapshot operation no longer deadlocks with it. Previously, the rebuild failed after about 3 minutes and the volume's I/O stayed suspended. See [Issue #14619](https://github.com/longhorn/longhorn/issues/14619).
- A snapshot taken a few seconds before a rebuild starts is now kept. Previously, Longhorn deleted it when the rebuild finished, and restoring from its CSI VolumeSnapshot failed. See [Issue #14596](https://github.com/longhorn/longhorn/issues/14596).

#### SPDK Target Crashes

Several `spdk_tgt` crashes in the V2 instance manager are fixed. A crash restarts every V2 replica and engine on the node.

- Double free in the NVMe-oF unmap path. See [Issue #14482](https://github.com/longhorn/longhorn/issues/14482).
- Assertion in `bdev_channel_destroy_resource` when a replica's parent was changed under I/O after a suspend timeout. See [Issue #14411](https://github.com/longhorn/longhorn/issues/14411).
- Race in `blob_insert_cluster_msg` when a snapshot was taken while writes allocated new clusters. See [Issue #14353](https://github.com/longhorn/longhorn/issues/14353).
- Multiple NVMe-oF transports created by concurrent expose requests. See [Issue #14399](https://github.com/longhorn/longhorn/issues/14399).
- Abort on every disk load after deleting a snapshot that was smaller than its child and whose size was not a multiple of 512 MiB. See [Issue #14344](https://github.com/longhorn/longhorn/issues/14344).
- Large block reads in interrupt mode. See [Issue #14095](https://github.com/longhorn/longhorn/issues/14095).

#### V1 Instance Manager Panic During Replica Rebuild

The V1 instance manager no longer panics when it checks snapshot checksum status while a replica is rebuilding. Previously, the panic took down every V1 engine on the node.

For more information, see [Issue #14251](https://github.com/longhorn/longhorn/issues/14251).

#### V2 DR Volume Faulted on Backupstore Lock Conflict

A V2 DR volume now retries a restore when another operation, such as a backup deletion, holds the backupstore lock. Previously, the volume became `Faulted`.

For more information, see [Issue #14085](https://github.com/longhorn/longhorn/issues/14085).

#### Unnecessary Rebuilds After Transient Failures

Two short-lived failures no longer cause Longhorn to rebuild healthy replicas.

- When a longhorn-manager pod is briefly not ready, such as during a restart or an upgrade, replica auto-balance now waits up to 3 minutes before it rebuilds the replicas of that node on other nodes. See [Issue #13941](https://github.com/longhorn/longhorn/issues/13941).
- When a request for a replica's snapshot purge or restore status fails on a dropped connection, Longhorn now retries the request. Previously, one failed request marked the replica as failed, and a volume with a single replica could become `Faulted`. See [Issue #13943](https://github.com/longhorn/longhorn/issues/13943).

#### V1 iSCSI Login Deadlock

A V1 volume no longer fails to attach when the kernel reads from the device during iSCSI login. Previously, the engine could not serve these reads until the login returned, so the login timed out and the volume kept detaching and reattaching.

For more information, see [Issue #13606](https://github.com/longhorn/longhorn/issues/13606).

#### V2 Volume Expansion

Expanding a V2 volume while it is attaching no longer times out. During a replica rebuild, a V2 volume expansion is now reported as complete only after the block device is resized. Expanding an encrypted V2 volume by 16 MiB or less is now rejected.

For more information, see [Issue #14521](https://github.com/longhorn/longhorn/issues/14521) and [Issue #13993](https://github.com/longhorn/longhorn/issues/13993).

#### Volume Attachment Cleanup for Force-Deleted Pods on Newer Kubernetes

Longhorn now removes the volume attachment of a force-deleted pod when Kubernetes reports `Waiting for detach` instead of `Multi-Attach error`. Kubernetes v1.35.9, v1.36.4, and v1.37.0 changed this event message. Previously, Longhorn did not recognize the new message, so the replacement pod waited about 6 minutes for the volume.

For more information, see [Issue #14182](https://github.com/longhorn/longhorn/issues/14182).

#### Hugepages Allocated From Another Pod's hugetlbfs

The V2 instance manager now allocates hugepages only from its own hugepages volume. Previously, `spdk_tgt` could allocate them from the hugepages volume of another pod on the node, and that pod then stayed in `Terminating` when it was deleted.

For more information, see [Issue #14340](https://github.com/longhorn/longhorn/issues/14340).

#### IPv4 Used for iSCSI on IPv6-First Dual-Stack Clusters

A V1 volume is now exposed over iSCSI on the primary IP address of the instance-manager pod. Previously, when Longhorn was installed as IPv6 single-stack in an IPv6-first dual-stack cluster, the volume could be exposed on the pod's IPv4 address.

For more information, see [Issue #14334](https://github.com/longhorn/longhorn/issues/14334).

#### Volume Clone With Mismatched Encryption Settings

Longhorn now rejects a volume clone when one volume is encrypted and the other is not. Previously, cloning an unencrypted PVC into an encrypted StorageClass completed, but the new volume could not be mounted.

For more information, see [Issue #14222](https://github.com/longhorn/longhorn/issues/14222).

## Changes in v1.13.0

### V2 Data Engine

#### General Availability

The V2 Data Engine became generally available in Longhorn v1.12.0. This milestone reflects improvements in stability, networking support, and feature maturity, making V2 volumes suitable for production use in supported environments.

Longhorn v1.13.0 builds on that GA foundation with [live upgrade](../deploy/upgrade/v2-instance-upgrade/) for V2 volumes and a refined V2 linked-clone feature. It also continues to improve V2 volume stability. Live upgrade to v1.13.0 itself is not supported; see [Longhorn System Upgrade](#longhorn-system-upgrade) for the supported upgrade paths.

For a summary of the current data engine behavior differences and feature support, see [Data Engine Comparison](../data-engine-comparison).

For more information, see [Issue #6229](https://github.com/longhorn/longhorn/issues/6229).

#### Full Interrupt Mode

Interrupt mode for the V2 Data Engine, available since v1.10.0, no longer polls for I/O completions in Longhorn v1.13.0. The kernel wakes the V2 Data Engine when I/O completes, so idle instance-manager pods use very little CPU. Latency can be slightly higher than in polling mode under sustained heavy I/O.

Polling mode remains the default. To enable interrupt mode, set `data-engine-interrupt-mode-enabled` to `{"v2":"true"}`. The setting applies to all V2 volumes and can be changed only when no V2 volumes are attached.

For more information, see:
* [Issue #11662](https://github.com/longhorn/longhorn/issues/11662)
* [Interrupt Mode Support](../advanced-resources/v2-data-engine/interrupt-mode)
* [Data Engine Interrupt Mode Enabled](../references/settings/#data-engine-interrupt-mode-enabled)

#### V2 Dedicated CPU Requirements

When assigning CPU cores to the V2 Data Engine, ensure that the V2 instance-manager pod has enough guaranteed CPU resources to cover the assigned cores. This provides dedicated CPU availability for SPDK reactors, prevents CPU contention, and helps maintain predictable performance and V2 Data Engine stability.

You can verify that the guaranteed CPU resources match the CPU cores specified by `data-engine-cpu-mask` or `data-engine-number-of-cpu-cores`. For more details, see [Guaranteed Instance Manager CPU](../references/settings/#guaranteed-instance-manager-cpu), [Data Engine CPU Mask](../references/settings/#data-engine-cpu-mask), and [Data Engine Number of CPU Cores](../references/settings/#data-engine-number-of-cpu-cores).

#### CPU Isolation Enabled by Default

Longhorn v1.13.0 enables [Data Engine CPU Isolation](../references/settings/#data-engine-cpu-isolation-enabled) by default for the V2 Data Engine (`{"v2":"true"}`). This keeps hardware interrupts and other kernel work off the CPU cores used by the V2 Data Engine, so it is not interrupted while it processes I/O.

CPU isolation applies only in polling mode. When [interrupt mode](#full-interrupt-mode) is enabled, Longhorn skips it automatically regardless of this setting.

For more information, see:
* [Issue #13724](https://github.com/longhorn/longhorn/issues/13724)
* [Issue #13973](https://github.com/longhorn/longhorn/issues/13973)
* [Data Engine CPU Isolation Enabled](../references/settings/#data-engine-cpu-isolation-enabled)

### Sharding Storage (Experimental)

Longhorn v1.12.1 introduces storage sharding for the V2 Data Engine as an experimental feature. Instead of storing a full copy of the volume on each replica, sharding splits the volume into data and parity chunks using erasure coding and distributes them across multiple nodes. This allows a volume to grow beyond the capacity of a single disk or node while using less disk space to achieve the same level of fault tolerance.

Because this feature is experimental, it is intended for evaluation and testing only and is not recommended for production use.

For more information, see [Issue #1061](https://github.com/longhorn/longhorn/issues/1061) and [Sharding Storage](../advanced-resources/sharding-storage).

### Important Fixes

#### Linked-Clone Backup Restore

Backups of V2 linked-clone volumes now record the source volume and the snapshot the clone was created from. A restore fails if the source volume or that snapshot no longer exists.

Previously, the restore succeeded and produced a corrupted volume.

For more information, see [Issue #13714](https://github.com/longhorn/longhorn/issues/13714) and [CSI Volume Clone](../snapshots-and-backups/csi-volume-clone).

#### CSI Volume Clone with Strict-Local Data Locality

When cloning a volume with `dataLocality: strict-local`, Longhorn now attaches the clone for its data copy on a node that matches the volume's `nodeSelector` and `diskSelector`.

Previously, this node was chosen without checking the selectors, and `strict-local` pinned the clone's single replica to it. If the node did not match the selectors, the replica could not be scheduled. The clone then failed with `hard affinity cannot be satisfied`.

For more information, see [Issue #12792](https://github.com/longhorn/longhorn/issues/12792).

#### Longhorn Node Removal After Kubernetes Node Deletion

Longhorn now allows you to clean up a Longhorn node after the Kubernetes node was deleted without evicting it first. You can disable scheduling on the node, remove its remaining replicas and engines, and then delete it.

Previously, the Longhorn admission webhook rejected the request to disable scheduling because the disk status of a deleted node can no longer be synced. Because a schedulable node cannot be deleted, the Longhorn node remained in the cluster until the webhook was disabled.

Evicting a node before deleting it from the cluster is still the recommended procedure.

For more information, see [Issue #13494](https://github.com/longhorn/longhorn/issues/13494) and [Graceful Node Removal](../nodes-and-volumes/nodes/graceful-node-removal).

#### Backing Image Copies on IPv6 Clusters

The backing image manager now copies backing images over the cluster's IP family and the storage network, like the other Longhorn components.

Previously, it always used IPv4. On IPv6 single-stack and IPv6-first dual-stack clusters, a backing image could not be copied to other nodes, so it stayed at one copy.

For more information, see [Issue #13864](https://github.com/longhorn/longhorn/issues/13864) and [Backing Image](../advanced-resources/backing-image/backing-image).

### Scheduling

#### Volume Topology Constraint

Longhorn v1.13.0 adds the `volumeTopology` StorageClass parameter to keep a volume's replicas in the zone or region where it was provisioned. Previously, zone labels only spread replicas apart, so a rebuild could place a replica in a different zone from the workload.

- `any` (default): no constraint.
- `zonal`: replicas stay in the zone chosen at provisioning time, including during rebuilds and replica count changes. With `WaitForFirstConsumer`, this is the zone the pod is scheduled to. With `Immediate` binding, the zone is selected from the provisioner-supplied topology at creation time, and the first consumer pod is constrained to that zone through the PV `nodeAffinity`.
- `regional`: same as `zonal`, but for regions.

If the chosen zone or region has no capacity, scheduling waits rather than falling back to another one. Clusters without topology labels are unaffected. A StorageClass with `volumeTopology: zonal` and `replicaZoneSoftAntiAffinity: disabled` is rejected at provisioning time.

For more information, see [Issue #13493](https://github.com/longhorn/longhorn/issues/13493) and [Topology-Aware Provisioning](../nodes-and-volumes/nodes/topology-aware-provisioning).

#### Scheduler Extender

Longhorn v1.13.0 adds a scheduler extender that lets kube-scheduler check actual Longhorn disk capacity when placing pods. Without it, kube-scheduler relies on `CSIStorageCapacity` objects, which have three limitations:

- The reported capacity lags behind when many pods are created at once.
- A pod with several PVCs is not checked against the combined space it needs across disks.
- A pod whose PVCs are already bound is rescheduled without any capacity check.

The extender reads Longhorn node and disk state directly. It also pins a restarted pod to the node that already holds all of its replicas, which makes it most useful for volumes with `best-effort` data locality.

The extender runs inside longhorn-manager under leader election, so there is no extra component to deploy. It requires a change to the kube-scheduler configuration, which is not possible on managed Kubernetes offerings such as GKE and EKS.

For more information, see [Issue #12591](https://github.com/longhorn/longhorn/issues/12591).

### Resource Efficiency

#### Longhorn Global Manager

Longhorn v1.13.0 moves the cluster-wide pod and PV controllers out of the longhorn-manager DaemonSet into a new `longhorn-global-manager` Deployment. Previously, every longhorn-manager pod watched every pod in the cluster, so kube-apiserver load and longhorn-manager memory grew with the number of nodes and pods. Now one elected leader runs these controllers, and longhorn-manager watches only the `longhorn-system` namespace.

The Deployment is created on install and upgrade, with three replicas by default (`longhornGlobalManager.replicas`): one leader and two standby replicas ready to take over. Before upgrading, make sure at least one of its pods can be scheduled. See [Upgrading Longhorn Manager](../deploy/upgrade/longhorn-manager).

For more information, see:
* [Issue #13059](https://github.com/longhorn/longhorn/issues/13059)
* [Longhorn Global Manager](../terminology/#longhorn-global-manager)
* [Longhorn Global Manager Settings](../references/helm-values/#longhorn-global-manager-settings)
* [Networking](../references/networking/#longhorn-global-manager)

### Snapshots and Backups

#### Volume Group Snapshot Support

Longhorn v1.13.0 can snapshot a set of volumes as one group with a single request. You can create snapshot groups from the Longhorn UI, with kubectl, or by creating Kubernetes `VolumeGroupSnapshot` objects through CSI. The CSI path also supports group backups.

The UI and kubectl paths work out of the box. The CSI path is disabled by default: it requires the VolumeGroupSnapshot CRDs, the `CSIVolumeGroupSnapshot` feature gate on the snapshot-controller, and a Longhorn toggle. For the setup steps, see [Enable CSI Volume Group Snapshot Support](../snapshots-and-backups/csi-snapshot-support/enable-csi-volume-group-snapshot-support).

> **Important: Snapshot Consistency**
> Each member volume is snapshotted independently, meaning the group is **not** captured at a single point in time. Application-level consistency across the group is future work built on top of this feature ([Issue #2128](https://github.com/longhorn/longhorn/issues/2128)).

For more information, see:
* [Issue #13349](https://github.com/longhorn/longhorn/issues/13349)
* [Create a Snapshot Group](../snapshots-and-backups/snapshot-groups)
* [CSI VolumeGroupSnapshot Associated with Longhorn Snapshot Group](../snapshots-and-backups/csi-snapshot-support/csi-volume-group-snapshot)

#### Age-Based Retention for Recurring Jobs

Longhorn v1.13.0 adds an `age-based` retention policy for snapshot, backup, and system backup recurring jobs. Set `retentionPolicy` to `age-based` and `retainAge` to a duration such as `720h`. On each run, the job deletes snapshots or backups older than `retainAge`, regardless of how many exist or how often the job runs. Supported units are `s`, `m`, and `h`, so write `24h` for one day.

The `count-based` policy remains the default, and existing recurring jobs keep it after the upgrade, so their behavior does not change. The two policies do not combine: `count-based` ignores `retainAge`, and `age-based` ignores `retain`.

For more information, see [Issue #12060](https://github.com/longhorn/longhorn/issues/12060).

### Networking

#### Internal Network Policies

Longhorn v1.12.1 enables ingress `NetworkPolicy` resources for internal component endpoints and RPCs by default, including the instance-manager gRPC endpoint used for engine control. The policies take effect only when the CNI plugin enforces `NetworkPolicy`. Otherwise, the resources are created but have no effect. For details, see [Network Policy](../advanced-resources/security/network-policy).

Longhorn v1.12.2 resolves the CNI compatibility issues found in v1.12.1 by providing two Helm values to manage the affected traffic paths:

- **`networkPolicies.v1DataEngineInitiatorSourceCIDRs`**: Controls source filtering for V1 iSCSI on TCP port 3260. Starting in v1.13.1, an empty list renders no TCP/3260 rule; see [V1 iSCSI Rule Removed From the Default Instance Manager NetworkPolicy](#v1-iscsi-rule-removed-from-the-default-instance-manager-networkpolicy). If populated, the CIDRs restrict connections to the effective sources observed by the CNI, so the required values are CNI-specific.
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
