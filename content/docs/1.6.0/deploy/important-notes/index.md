---
title: Important Notes
weight: 4
---

This page lists important notes for Longhorn v{{< current-version >}}.
Please see [here](https://github.com/longhorn/longhorn/releases/tag/v{{< current-version >}}) for the full release note.

- [General](#general)
  - [Supported Kubernetes Versions](#supported-kubernetes-versions)
  - [Offline Upgrade Required To Fully Prevent Unexpected Replica Expansion](#offline-upgrade-required-to-fully-prevent-unexpected-replica-expansion)
  - [Default Priority Class](#default-priority-class)
  - [New Node Drain Policies Added](#new-node-drain-policies-added)
  - [Custom Resource Fields Deprecated](#custom-resource-fields-deprecated)
  - [Pod Security Policies Disabled \& Pod Security Admission Introduction](#pod-security-policies-disabled--pod-security-admission-introduction)
  - [Updating CSI Snapshot CRD `v1beta1` to `v1`, `v1beta1` Removed](#updating-csi-snapshot-crd-v1beta1-to-v1-v1beta1-removed)
  - [Engine Upgrade Enforcement](#engine-upgrade-enforcement)
  - [Danger Zone Setting Configuration](#danger-zone-setting-configuration)
- [V2 Data Engine](#v2-data-engine)
  - [Longhorn System Upgrade](#longhorn-system-upgrade)
  - [Changing Default Huge Page Size to 2 GiB](#changing-default-huge-page-size-to-2-gib)
  - [Support for ARM64 Platform](#support-for-arm64-platform)
  - [Replacing `backendStoreDriver` with `dataEngine`](#replacing-backendstoredriver-with-dataengine)
  - [Updating the Linux Kernel on Longhorn Nodes](#updating-the-linux-kernel-on-longhorn-nodes)

## General

### Supported Kubernetes Versions

Please ensure your Kubernetes cluster is at least v1.21 before upgrading to Longhorn v{{< current-version >}} because this is the minimum version Longhorn v{{< current-version >}} supports.

### Offline Upgrade Required To Fully Prevent Unexpected Replica Expansion

Longhorn v1.6.0 introduces a new mechanism to prevent [unexpected replica
expansion](../../../../kb/troubleshooting-unexpected-expansion-leads-to-degradation-or-attach-failure). This
mechanism is entirely transparent. However, a volume is only protected if it is running a new version of longhorn-engine
inside a new version of longhorn-instance-manager and managed by a new version of longhorn-manager. The [live upgrade
process](../../deploy/upgrade/upgrade-engine#live-upgrade) results in a volume running a new version of longhorn-engine
in an old version of longhorn-instance-manager until it is detached (by scaling its consuming workload down) and
reattached (by scaling its consuming workload up). Consider scaling workloads down and back up again as soon as possible
after upgrading from a version without this mechanism (v1.5.1 or older) to v{{< current-version >}}.

### Default Priority Class

Longhorn v1.6.0 introduces the default Priority Class `longhorn-critical`, which has the highest value and ensures that Longhorn pods are not evicted by kube-scheduler when system resources are low.

During upgrades, Longhorn applies the default Priority Class to components depending on specific settings.

- When all volumes are detached and you did not specify a value for the global Priority Class setting `priority-class`, the default Priority Class is applied to all Longhorn components. `priority-class` is updated.
- When all volumes are detached and you specified a value for the global Priority Class setting `priority-class`, the default Priority Class is applied only to user-deployed components. `priority-class` is not updated.
- When one or more volumes are attached and you did not specify a value for `PriorityClass` in the `chart/value.yaml` or `longhorn/deploy/longhorn.yaml`, the default Priority Class is applied only to user-deployed components. `priority-class` is not updated.

If you want to apply the default Priority Class to system-managed components, you must detach all volumes and change the Priority Class default setting value after the upgrade is successfully completed.

You can change these behaviors by customizing the following before starting the upgrade process:

- For user deployed components: `priorityClass` parameters for each component in the `values.yaml` file of the [Longhorn Helm chart](https://github.com/longhorn/longhorn/blob/v1.6.0/chart/values.yaml)
- For system managed components: `defaultSetting.priorityClass` in the `values.yaml` file of the [Longhorn Helm chart](https://github.com/longhorn/longhorn/blob/v1.6.0/chart/values.yaml)

### New Node Drain Policies Added

There are two new options for the [Node Drain Policy](../../references/settings#node-drain-policy) setting. Both `Block
For Eviction` and `Block for Eviction If Contains Last Replica` automatically evict replicas from draining nodes in
addition to preventing drain completion until volume data is sufficiently protected. `Block for Eviction` maintains
maximum data redundancy during maintenance operations, and both new options enable automated cluster upgrades when some
volumes have only one replica. See the new [Node Drain Policy
Recommendations](../../maintenance/maintenance/#node-drain-policy-recommendations) section for help deciding which
policy to use.

### Custom Resource Fields Deprecated

Starting in `v1.6.0`, the following custom resource fields are deprecated. They will be removed in `v1.7.0`:

- Volume.status.evictionRequested

### Pod Security Policies Disabled & Pod Security Admission Introduction

- Longhorn pods require privileged access to manage nodes' storage. In Longhorn `v1.3.x` or older, Longhorn was shipping some Pod Security Policies by default, (e.g., [link](https://github.com/longhorn/longhorn/blob/4ba39a989b4b482d51fd4bc651f61f2b419428bd/chart/values.yaml#L260)).
However, Pod Security Policy has been deprecated since Kubernetes v1.21 and removed since Kubernetes v1.25, [link](https://kubernetes.io/docs/concepts/security/pod-security-policy/).
Therefore, we stopped shipping the Pod Security Policies by default.
For Kubernetes < v1.25, if your cluster still enables Pod Security Policy admission controller, please do:
  - Helm installation method: set the helm value `enablePSP` to `true` to install `longhorn-psp` PodSecurityPolicy resource which allows privileged Longhorn pods to start.
  - Kubectl installation method: need to apply the [podsecuritypolicy.yaml](https://raw.githubusercontent.com/longhorn/longhorn/master/deploy/podsecuritypolicy.yaml) manifest in addition to applying the `longhorn.yaml` manifests.
  - Rancher UI installation method: set `Other Settings > Pod Security Policy` to `true` to install `longhorn-psp` PodSecurityPolicy resource which allows privileged Longhorn pods to start.

- As a replacement for Pod Security Policy, Kubernetes provides a new mechanism, [Pod Security Admission](https://kubernetes.io/docs/concepts/security/pod-security-admission/).
If you enable the Pod Security Admission controller and change the default behavior to block privileged pods,
you must add the correct labels to the namespace where Longhorn pods run to allow Longhorn pods to start successfully
(because Longhorn pods require privileged access to manage storage).
For example, adding the following labels to the namespace that is running Longhorn pods:
    ```yaml
    apiVersion: v1
    kind: Namespace
    metadata:
      name: longhorn-system
      labels:
        pod-security.kubernetes.io/enforce: privileged
        pod-security.kubernetes.io/enforce-version: latest
        pod-security.kubernetes.io/audit: privileged
        pod-security.kubernetes.io/audit-version: latest
        pod-security.kubernetes.io/warn: privileged
        pod-security.kubernetes.io/warn-version: latest
   	```

### Updating CSI Snapshot CRD `v1beta1` to `v1`, `v1beta1` Removed

Support for the `v1beta1` version of CSI snapshot CRDs was previously deprecated in favor of the `v1` version.
The CSI components in Longhorn v{{< current-version >}} only function with the `v1` version.
Please follow the instructions at [Enable CSI Snapshot Support](../../snapshots-and-backups/csi-snapshot-support/enable-csi-snapshot-support) to update CSI snapshot CRDs and the CSI snapshot controller.
If you have Longhorn volume manifests or scripts that are still using `v1beta1` version, you must upgrade them to `v1` as well.

### Engine Upgrade Enforcement

Beginning with version v1.6.0, Longhorn is implementing mandatory engine upgrades. See the [release note](https://github.com/longhorn/longhorn/releases/tag/v{{< current-version >}}) for information about the minimum supported engine image version.

When upgrading through Helm, a component compatibility check is automatically performed. If the new Longhorn is not compatible with the engine images that are currently in use, the upgrade path is blocked through a pre-hook mechanism.

If you installed Longhorn using the manifests, engine upgrades are enforced by the Longhorn Manager. Attempts to upgrade Longhorn Manager may cause unsuccessful pod launches and generate corresponding error logs, although it poses no harm. If you encounter such errors, you must revert to the previous Longhorn version and then upgrade the engines that are using the incompatible engine images before the next upgrade.

> **Warning:**
> Whenever engine upgrade enforcement causes upgrade failure, Longhorn allows you to revert to the previous version because Longhorn Manager will block the entire upgrade. However, Longhorn prohibits downgrading when an upgrade is successful. For more information, see [Upgrade Path Enforcement](../../deploy/upgrade/#upgrade-path-enforcement-and-downgrade-prevention).

You can determine the versions of engine images that are currently in use with the following script:
```bash
#!/bin/bash

namespace="longhorn-system"

engine_images=$(kubectl -n $namespace get engineimage -o=jsonpath='{.items[*].metadata.name}')

for engine_image in $engine_images; do
    cli_api_version=$(kubectl -n $namespace get engineimage $engine_image -o=jsonpath='{.status.cliAPIVersion}')
    controller_api_version=$(kubectl -n $namespace get engineimage $engine_image -o=jsonpath='{.status.controllerAPIVersion}')
    echo "EngineImage: $engine_image | cliAPIVersion: $cli_api_version | controllerAPIVersion: $controller_api_version"
done
```

Once you successfully upgrade to version v1.6.0, you will be able to view information about engine image versions on the UI.

### Danger Zone Setting Configuration

Starting with Longhorn v1.6.0, Longhorn allows you to modify the [Danger Zone settings](https://longhorn.io/docs/1.6.0/references/settings/#danger-zone) without the need to wait for all volumes to become detached. Your preferred settings are immediately applied in the following scenarios:

- No attached volumes: When no volumes are attached before the settings are configured, the setting changes are immediately applied.
- Engine image upgrade (live upgrade): During a live upgrade, which involves creating a new Instance Manager pod, the setting changes are immediately applied to the new pod.

Settings are synchronized hourly. When all volumes are detached, the settings in the following table are immediately applied and the system-managed components (for example, Instance Manager, CSI Driver, and engine images) are restarted. If you do not detach all volumes before the settings are synchronized, the settings are not applied and you must reconfigure the same settings after detaching the remaining volumes.

  | Setting | Additional Information| Affected Components |
  | --- | --- | --- |
  | [Kubernetes Taint Toleration](../../references/settings/#kubernetes-taint-toleration)| [Taints and Tolerations](../../advanced-resources/deploy/taint-toleration/) | System-managed components |
  | [Priority Class](../../references/settings/#priority-class) | [Priority Class](../../advanced-resources/deploy/priority-class/) | System-managed components |
  | [System Managed Components Node Selector](../../references/settings/#system-managed-components-node-selector) | [Node Selector](../../advanced-resources/deploy/node-selector/) | System-managed components |
  | [Storage Network](../../references/settings/#storage-network) | [Storage Network](../../advanced-resources/deploy/storage-network/) | Instance Manager and Backing Image components |
  | [V1 Data Engine](../../references/settings/#v1-data-engine) || Instance Manager component |
  | [V2 Data Engine](../../references/settings/#v2-data-engine) | [V2 Data Engine (Preview Feature)](../../v2-data-engine/) | Instance Manager component |
  | [Guaranteed Instance Manager CPU](../../references/settings/#guaranteed-instance-manager-cpu) || Instance Manager component |
  | [Guaranteed Instance Manager CPU for V2 Data Engine](../../references/settings/#guaranteed-instance-manager-cpu-for-v2-data-engine) || Instance Manager component |

For V1 and V2 Data Engine settings, you can disable the Data Engines only when all associated volumes are detached. For example, you can disable the V2 Data Engine only when all V2 volumes are detached (even when V1 volumes are still attached).

## V2 Data Engine

### Longhorn System Upgrade

Longhorn currently does not support live upgrading of V2 volumes. Ensure that all V2 volumes are detached before initiating the upgrade process.

### Changing Default Huge Page Size to 2 GiB

The default huge page size for the V2 Data Engine has been raised to 2 GiB, allowing the creation of more V2 volumes and enhancing the overall user experience. Before upgrading to v1.6.0, ensure that the configured huge page size on each node is 2 GiB.

### Support for ARM64 Platform

As of Longhorn v1.6.0, volumes using the V2 Data Engine support the ARM64 platform. For more information, see [Prerequisites](../../v2-data-engine/prerequisites/).

### Replacing `backendStoreDriver` with `dataEngine`

The attribute `backendStoreDriver`, which is defined in the parameters of StorageClasses and other Longhorn resources (for example, volumes, engines, and replicas), has been replaced with `dataEngine`. You must remove the existing StorageClasses for V2 volumes and create new ones that use `dataEngine`.

### Updating the Linux Kernel on Longhorn Nodes

Host machines with Linux kernel 5.15 may unexpectedly reboot when volume-related IO errors occur. Update the Linux kernel on Longhorn nodes to version 5.19 or later to prevent such issues. For more information, see [Prerequisites](../../v2-data-engine/prerequisites/).
