---
title: Important Notes
weight: 1
---

This page summarizes the key notes for Longhorn v{{< current-version >}}.
For the full release note, see [here](https://github.com/longhorn/longhorn/releases/tag/v{{< current-version >}}).

- [Warning](#warning)
  - [Upgrade](#upgrade)
    - [Migration Requirement Before Longhorn v1.10 Upgrade](#migration-requirement-before-longhorn-v110-upgrade)
    - [Migration Verification](#migration-verification)
    - [Troubleshooting CRD Upgrade Failures During Upgrade to Longhorn v1.10](#troubleshooting-crd-upgrade-failures-during-upgrade-to-longhorn-v110)
      - [Downgrade Procedure (kubectl Installation)](#downgrade-procedure-kubectl-installation)
      - [Downgrade Procedure (Helm Installation)](#downgrade-procedure-helm-installation)
      - [Post-Downgrade](#post-downgrade)
- [Removal](#removal)
  - [`longhorn.io/v1beta1` API](#longhorniov1beta1-api)
  - [`replica.status.evictionRequested` Field](#replicastatusevictionrequested-field)
- [General](#general)
  - [Kubernetes Version Requirement](#kubernetes-version-requirement)
  - [CRD Upgrade Validation](#crd-upgrade-validation)
  - [Upgrade Check Events](#upgrade-check-events)
  - [Manual Checks Before Upgrade](#manual-checks-before-upgrade)
  - [Consolidation of Longhorn Settings](#consolidation-of-longhorn-settings)
  - [System Info Category in Setting](#system-info-category-in-setting)
  - [Volume Attachment Summary](#volume-attachment-summary)
- [Scheduling](#scheduling)
  - [Pod Scheduling with CSIStorageCapacity](#pod-scheduling-with-csistoragecapacity)
- [Performance](#performance)
  - [Configurable Backup Block Size](#configurable-backup-block-size)
  - [Profiling Support for Backup Sync Agent](#profiling-support-for-backup-sync-agent)
- [Resilience](#resilience)
  - [Configurable Liveness Probe for Instance Manager](#configurable-liveness-probe-for-instance-manager)
  - [Backing Image Manager CR Naming](#backing-image-manager-cr-naming)
- [Security](#security)
  - [Refined RBAC Permissions](#refined-rbac-permissions)
- [V1 Data Engine](#v1-data-engine)
  - [IPv6 Support](#ipv6-support)
- [V2 Data Engine](#v2-data-engine)
  - [Longhorn System Upgrade](#longhorn-system-upgrade)
  - [New Functionalities since Longhorn v1.10.0](#new-functionalities-since-longhorn-v1100)
    - [V2 Data Engine Without Hugepage Support](#v2-data-engine-without-hugepage-support)
    - [V2 Data Engine Interrupt Mode Support](#v2-data-engine-interrupt-mode-support)
    - [V2 Data Engine Volume Clone Support](#v2-data-engine-volume-clone-support)
    - [V2 Data Engine Replica Rebuild QoS](#v2-data-engine-replica-rebuild-qos)
    - [V2 Data Engine Volume Expansion](#v2-data-engine-volume-expansion)

## Warning

### Upgrade

If your Longhorn cluster was initially deployed with a version earlier than v1.3.0, the Custom Resources (CRs) were created using the `v1beta1` APIs. While the upgrade from Longhorn v1.8 to v1.9 automatically migrates all CRs to the new `v1beta2` version, **a manual CR migration is strongly advised before upgrading from Longhorn `v1.9` to `v1.10`**.

Certain operations, such as an `etcd` or CRD restore, may leave behind `v1beta1` data. Manually migrating your CRs ensures that all Longhorn data is properly updated to the `v1beta2` API, preventing potential compatibility issues and unexpected behavior with the new Longhorn version.

Following the manual migration, **verify that `v1beta1` has been removed from the CRD stored versions** to ensure completion and a successful upgrade.

For more details, see [Kubernetes official document for CRD storage version](https://kubernetes.io/docs/tasks/extend-kubernetes/custom-resources/custom-resource-definition-versioning/#upgrade-existing-objects-to-a-new-stored-version), and [Issue #11886](https://github.com/longhorn/longhorn/issues/11886).

#### Migration Requirement Before Longhorn v1.10 Upgrade

Before upgrading from Longhorn v1.9 to v1.10, perform the following manual CRD storage version migration.

> **Note**: If your Longhorn installation uses a namespace other than `longhorn-system`, replace `longhorn-system` with your custom namespace throughout the commands.

```bash
# Temporarily disable the CR validation webhook to allow updating read-only settings CRs.
kubectl patch validatingwebhookconfiguration longhorn-webhook-validator \
  --type=merge \
  -p "$(kubectl get validatingwebhookconfiguration longhorn-webhook-validator -o json | \
  jq '.webhooks[0].rules |= map(if .apiGroups == ["longhorn.io"] and .resources == ["settings"] then
    .operations |= map(select(. != "UPDATE")) else . end)')"

# Migrate CRDs that ever stored v1beta1 resources
migration_time="$(date +%Y-%m-%dT%H:%M:%S)"
crds=($(kubectl get crd -l app.kubernetes.io/name=longhorn -o json | jq -r '.items[] | select(.status.storedVersions | index("v1beta1")) | .metadata.name'))
for crd in "${crds[@]}"; do
  echo "Migrating ${crd} ..."
  for name in $(kubectl -n longhorn-system get "$crd" -o jsonpath='{.items[*].metadata.name}'); do
    # Attach additional annotations to trigger v1beta1 resource updating in the latest storage version.
    kubectl patch "${crd}" "${name}" -n longhorn-system --type=merge -p='{"metadata":{"annotations":{"migration-time":"'"${migration_time}"'"}}}'
  done
  # Clean up the stored version in CRD status
  kubectl patch crd "${crd}" --type=merge -p '{"status":{"storedVersions":["v1beta2"]}}' --subresource=status
done

# Re-enable the CR validation webhook.
kubectl patch validatingwebhookconfiguration longhorn-webhook-validator \
  --type=merge \
  -p "$(kubectl get validatingwebhookconfiguration longhorn-webhook-validator -o json | \
  jq '.webhooks[0].rules |= map(if .apiGroups == ["longhorn.io"] and .resources == ["settings"] then
    .operations |= (. + ["UPDATE"] | unique) else . end)')"
```

#### Migration Verification

After running the script, verify the CRD stored versions using this command:

```bash
kubectl get crd -l app.kubernetes.io/name=longhorn -o=jsonpath='{range .items[*]}{.metadata.name}{": "}{.status.storedVersions}{"\n"}{end}'
```

Crucially, all Longhorn CRDs MUST have only `"v1beta2"` listed in `storedVersions` (i.e., `"v1beta1"` must be completely absent) before proceeding to the v1.10 upgrade.

Example of successful output:

```
backingimagedatasources.longhorn.io: ["v1beta2"]
backingimagemanagers.longhorn.io: ["v1beta2"]
backingimages.longhorn.io: ["v1beta2"]
backupbackingimages.longhorn.io: ["v1beta2"]
backups.longhorn.io: ["v1beta2"]
backuptargets.longhorn.io: ["v1beta2"]
backupvolumes.longhorn.io: ["v1beta2"]
engineimages.longhorn.io: ["v1beta2"]
engines.longhorn.io: ["v1beta2"]
instancemanagers.longhorn.io: ["v1beta2"]
nodes.longhorn.io: ["v1beta2"]
orphans.longhorn.io: ["v1beta2"]
recurringjobs.longhorn.io: ["v1beta2"]
replicas.longhorn.io: ["v1beta2"]
settings.longhorn.io: ["v1beta2"]
sharemanagers.longhorn.io: ["v1beta2"]
snapshots.longhorn.io: ["v1beta2"]
supportbundles.longhorn.io: ["v1beta2"]
systembackups.longhorn.io: ["v1beta2"]
systemrestores.longhorn.io: ["v1beta2"]
volumeattachments.longhorn.io: ["v1beta2"]
volumes.longhorn.io: ["v1beta2"]
```

With these steps completed, the Longhorn upgrade to v1.10 should now proceed without issues.

#### Troubleshooting CRD Upgrade Failures During Upgrade to Longhorn v1.10

If you did not apply the required pre-upgrade migration steps and the CRs are not fully migrated to `v1beta2`, the `longhorn-manager` Pods may fail to operate correctly. A common error message for this issue is:

```
Upgrade failed: cannot patch "backingimagedatasources.longhorn.io" with kind CustomResourceDefinition: CustomResourceDefinition.apiextensions.k8s.io "backingimagedatasources.longhorn.io" is invalid: status.storedVersions[0]: Invalid value: "v1beta1": missing from spec.versions; v1beta1 was previously a storage version, and must remain in spec.versions until a storage migration ensures no data remains persisted in v1beta1 and removes v1beta1 from status.storedVersions
```

To fix this issue, you must perform a **forced downgrade** back to the **exact Longhorn v1.9.x version** that was running before the failed upgrade attempt.

##### Downgrade Procedure (kubectl Installation)

If Longhorn was installed using `kubectl`, you must patch the `current-longhorn-version` setting before downgrading. Replace `"v1.9.x" to the original version before upgrade in the following commands.

```bash
# Attaching annotation to allow patching current-longhorn-version.
kubectl patch settings.longhorn.io current-longhorn-version -n longhorn-system --type=merge -p='{"metadata":{"annotations":{"longhorn.io/update-setting-from-longhorn":""}}}'
# Temporarily override current version to allow old version installation
# Replace the value `"v1.9.x" to the original version before upgrade.
kubectl patch settings.longhorn.io current-longhorn-version -n longhorn-system --type=merge -p='{"value":"v1.9.x"}'
```

After modifying `current-longhorn-version`, you can proceed to downgrade to the original Longhorn v1.9.x deployment.

##### Downgrade Procedure (Helm Installation)

If Longhorn was installed using Helm, the downgrade is allowed by disabling the [`preUpgradeChecker.upgradeVersionCheck`](https://github.com/longhorn/longhorn/tree/v1.9.x/chart#other-settings) flag.

##### Post-Downgrade

Once the downgrade is complete and the Longhorn system is stable on the v1.9.x version, you must immediately follow the steps outlined in the [Manual CRD Migration Guide](#migration-requirement-before-longhorn-v110-upgrade). This step is crucial to migrate all remaining `v1beta1` CRs to `v1beta2` before attempting the Longhorn v1.10 upgrade again.

## Removal

### `longhorn.io/v1beta1` API

The `v1beta1` Longhorn API version was removed in v1.10.0.

For more details, see [Issue #10249](https://github.com/longhorn/longhorn/issues/10249).

### `replica.status.evictionRequested` Field

The deprecated `replica.status.evictionRequested` field has been removed.

For more details, see [Issue #7022](https://github.com/longhorn/longhorn/issues/7022)

## General

### Kubernetes Version Requirement

Due to the upgrade of the CSI external snapshotter to v8.2.0, all clusters must be running Kubernetes v1.25 or later before you can upgrade to Longhorn v1.8.0 or a newer version.

### CRD Upgrade Validation

During an upgrade, a new Longhorn manager may start before the Custom Resource Definitions (CRDs) are applied. This sequencing ensures the controller does not process objects containing deprecated data or fields. However, it can cause the Longhorn manager to fail during the initial upgrade phase if the CRD has not yet been applied.

If the Longhorn manager crashes during the upgrade, check the logs to determine if the failure is due to the CRD not being applied. In such cases, the logs may contain error messages similar to the following:

```
time="2025-03-27T06:59:55Z" level=fatal msg="Error starting manager: upgrade resources failed: BackingImage in version \"v1beta2\" cannot be handled as a BackingImage: strict decoding error: unknown field \"spec.diskFileSpecMap\", unknown field \"spec.diskSelector\", unknown field \"spec.minNumberOfCopies\", unknown field \"spec.nodeSelector\", unknown field \"spec.secret\", unknown field \"spec.secretNamespace\"" func=main.main.DaemonCmd.func3 file="daemon.go:94"
```

### Upgrade Check Events

When upgrading via Helm or Rancher App Marketplace, Longhorn performs pre-upgrade checks. If a check fails, the upgrade stops, and the reason for the failure is recorded in an event.

For more detail, see [Upgrading Longhorn Manager](../deploy/upgrade/longhorn-manager).

### Manual Checks Before Upgrade

Automated pre-upgrade checks do not cover all scenarios. Manual checks via kubectl or the UI are recommended:

- Ensure all V2 Data Engine volumes are detached and replicas are stopped. The V2 engine does not support live upgrades.
- Avoid upgrading when volumes are "Faulted", as unusable replicas may be deleted, causing permanent data loss if no backups exist.
- Avoid upgrading if a failed BackingImage exists. See [Backing Image](../advanced-resources/backing-image/backing-image) for details.
- Creating a [Longhorn system backup](../advanced-resources/system-backup-restore/backup-longhorn-system) before upgrading is recommended to ensure recoverability.

### Consolidation of Longhorn Settings

Settings have been consolidated for easier management across V1 and V2 Data Engines. Each setting now uses one of the following formats:

- Single value for all supported Data Engines
  - Format: Non-JSON string (e.g., `1024`)
  - The value applies to all supported Data Engines and must be the same across them.
  - Data-engine-specific values are not allowed.
- Data-engine-specific values for V1 and V2 Data Engines
  - Format: JSON object (e.g., `{"v1": "value1", "v2": "value2"}`)
  - Allows specifying different values for V1 and V2 Data Engines.
- Data-engine-specific values for V1 Data Engine only
  - Format: JSON object with `v1` key only (e.g., `{"v1": "value1"}`)
  - Only the V1 Data Engine can be configured; the V2 Data Engine is not affected.
- Data-engine-specific values for V2 Data Engine only
  - Format: JSON object with `v2` key only (e.g., `{"v2": "value1"}`)
  - Only the V2 Data Engine can be configured; the V1 Data Engine is not affected.

For more information, see [Longhorn Settings](../references/settings).

### System Info Category in Setting

A new **System Info** category has been added to show cluster-level information more clearly.

For more details, see [Issue #11656](https://github.com/longhorn/longhorn/issues/11656)

### Volume Attachment Summary

The UI now display a summary of attachment tickets on each volume overview page for improved visibility into volume state.

For more details, see [Issue #11400](https://github.com/longhorn/longhorn/issues/11400) and [Issue #11401](https://github.com/longhorn/longhorn/issues/11401).

## Scheduling

### Pod Scheduling with CSIStorageCapacity

Longhorn now supports Kubernetes **CSIStorageCapacity**, which enables the scheduler to verify node storage before scheduling pods that use StorageClasses with **WaitForFirstConsumer**.

This reduces scheduling errors and improves reliability.

For more information, see [GitHub Issue #10685](https://github.com/longhorn/longhorn/issues/10685)

## Performance

### Configurable Backup Block Size

Starting in Longhorn v1.10.0,  backup block size can be configured when creating a volume, allowing optimization for performance, efficiency, and cost.

For more information, see [Create Longhorn Volumes](../nodes-and-volumes/volumes/create-volumes).

### Profiling Support for Backup Sync Agent

The backup sync agent exposes a `pprof` server for profiling runtime resource usage during backup sync operations.

For more information, see [Profiling](../troubleshoot/troubleshooting#profiling).

## Resilience

### Configurable Liveness Probe for Instance Manager

You can now configure the instance-manager pod liveness probes. This allows the system to better distinguish between temporary delays and actual failures, which helps reduce unnecessary restarts and improves overall cluster stability.

For more information, see [Longhorn Settings](../references/settings#instance-manager-pod-liveness-probe-timeout).

### Backing Image Manager CR Naming

Backing Image Manager CRs now use a compact, collision-resistant naming format to reduce conflict risk.

For details, see [Issue #11455](https://github.com/longhorn/longhorn/issues/11455)

## Security

### Refined RBAC Permissions

RBAC permissions have been refined to minimize privileges and improve cluster security.

For details, see [Issue #11345](https://github.com/longhorn/longhorn/issues/11345)

## V1 Data Engine

### IPv6 Support

V1 volumes now support single-stack IPv6 Kubernetes clusters.

> **Warning:** Dual-stack Kubernetes clusters and V2 volumes are not supported in this release.

For details, see [Issue #2259](https://github.com/longhorn/longhorn/issues/2259).

## V2 Data Engine

### Longhorn System Upgrade

Live upgrades of V2 volumes are **not supported**. Ensure all V2 volumes are detached before upgrading.

### New Functionalities since Longhorn v1.10.0

#### V2 Data Engine Without Hugepage Support

The V2 Data Engine can run without Hugepage by setting `data-engine-hugepage-enabled` to `{"v2":"false"}`.

This reduces memory pressure on low‑spec nodes and increases deployment flexibility. Performance may be lower compared to running with Hugepage.

#### V2 Data Engine Interrupt Mode Support

Interrupt mode has been added to the V2 Data Engine to help reduce CPU usage. This feature is especially beneficial for clusters with idle or low I/O workloads, where conserving CPU resources is more important than minimizing latency.

While interrupt mode lowers CPU consumption, it may introduce slightly higher I/O latency compared to polling mode. In addition, the current implementation uses a hybrid approach, which still incurs a minimal, constant CPU load even when interrupts are enabled.

For more information, see [Interrupt Mode](../v2-data-engine/features/interrupt-mode) for more information.

> **Limitation:** Interrupt mode currently supports only AIO disks.

#### V2 Data Engine Volume Clone Support

Longhorn now supports volume and snapshot cloning for V2 data engine volumes.
For more information, see [Volume Clone Support](../v2-data-engine/features/volume-clone).

#### V2 Data Engine Replica Rebuild QoS

Provides Quality of Service (QoS) control for V2 volume replica rebuilds. You can configure bandwidth limits globally or per volume to prevent storage throughput overload on source and destination nodes.

For more information, see [Replica Rebuild QoS](../v2-data-engine/features/replica-rebuild-qos).

#### V2 Data Engine Volume Expansion

Longhorn now supports volume expansion for V2 Data Engine volumes. Users can expand the volume through the UI or by modifying the PVC manifest.

For more information, see [V2 Volume Expansion](../v2-data-engine/features/volume-expansion).
