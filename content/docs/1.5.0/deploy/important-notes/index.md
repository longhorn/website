---
title: Important Notes
weight: 4
---

This page lists important notes for Longhorn v{{< current-version >}}.
Please see [here](https://github.com/longhorn/longhorn/releases/tag/v{{< current-version >}}) for the full release note.

## Notes

### Supported Kubernetes Versions
Please ensure your Kubernetes cluster is at least v1.21 before upgrading to Longhorn v{{< current-version >}} because this is the minimum version Longhorn v{{< current-version >}} supports.

### Attachment/Detachment Refactoring Side Effect On The Upgrade Process
In Longhorn v1.5.0, we refactored the internal volume attach/detach mechanism.
As a side effect, when you are upgrading from v1.4.x to v1.5.x, if there are in-progress operations such as volume cloning, backing image export from volume, and volume offline expansion, these operations will fail.
You will have to retry them manually.
To avoid this issue, please don't perform these operations during the upgrade.
Ref: https://github.com/longhorn/longhorn/issues/3715#issuecomment-1562305097

### Recurring Jobs
After the upgrade, the recurring job settings of volumes will be migrated to new recurring job resources, and the `RecurringJobs` field in the volume spec will be deprecated. [[doc](https://longhorn.io/docs/{{< current-version >}}/deploy/upgrade/#4-automatically-migrate-recurring-jobs)]

The behavior of the recurring job types `Snapshot` and `Backup` will attempt to delete old snapshots first if they exceed the retained count before creating a new snapshot. Additionally, two new recurring job types have been introduced, `Snapshot Force Create` and `Backup Force Create`. They retain the original behavior of taking a snapshot or backup first before deleting outdated snapshots.

### Longhorn Uninstallation
To prevent Longhorn from being accidentally uninstalled (which leads to data lost),
we introduce a new setting, [deleting-confirmation-flag](../../references/settings/#deleting-confirmation-flag).
If this flag is **false**, the Longhorn uninstallation job will fail.
Set this flag to **true** to allow Longhorn uninstallation.
See more in the [uninstall](../uninstall) section.

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

### `Custom mkfs.ext4 Parameters` Setting Removed

The `Custom mkfs.ext4 Parameters` setting was deprecated in Longhorn `v1.4.0` and is now removed. The per-StorageClass `mkfsParams` parameter should be used to specify mkfs options (e.g., `-I 256 -b 4096 -O ^metadata_csum,^64bit`) instead. See [Creating Longhorn Volumes with kubectl](../../volumes-and-nodes/create-volumes/#creating-longhorn-volumes-with-kubectl) for details.

### `Disable Replica Rebuild` Setting Removed

The `Disable Replica Rebuild` setting was deprecated and replaced by the [Concurrent Replica Rebuild Per Node Limit](../../references/settings/#concurrent-replica-rebuild-per-node-limit) setting in Longhorn `v1.2.1`. It should already have been ignored in any Longhorn deployment upgrading to Longhorn v{{< current-version >}} and is now removed. To disable replica rebuilding across the cluster, set the `Concurrent Replica Rebuild Per Node Limit` to 0.

### `Default Manager Image` Settings Removed

The `Default Backing Image Manager Image`, `Default Instance Manager Image` and `Default Share Manager Image` settings were deprecated and removed from `v1.5.0`. These default manager image settings can be changed on the manager starting command line only. They should be modified in the Longhorn deploying manifest or `values.yaml` in Longhorn chart.

### Longhorn Supports Fast Replica Rebuilding, and It Is Enabled by Default

Fast replica rebuilding is supported by Longhorn, and is enabled by default. The feature relies on the change timestamps and checksums of snapshot disk files, so `snapshot-data-integrity` is also set to `fast-check`. The file checksums for snapshot disks will be calculated periodically, with a default check period of 7 days. For more information, please refer to [Fast Replica Rebuild](../../advanced-resources/fast-replica-rebuild/index.html) and [Snapshot Data Integrity Check](../../advanced-resources/snapshot-data-integrity-check/index.html).

### Each Kubernetes Node Must Have a Unique Hostname for RWX Volumes

Longhorn has a dedicated recovery backend service for NFS servers in the share-manager pods used by the RWX volumes. The clients' information, including its hostname, will be stored in the recovery backend. The information will be used for connection recovery if the share-manager pod is abnormally terminated and a new one is created. The [environment check script](https://raw.githubusercontent.com/longhorn/longhorn/v{{< current-version >}}/scripts/environment_check.sh) helps users to check all nodes have unique hostnames.
More information please refer to [ReadWriteMany (RWX) Volume](../../advanced-resources/rwx-workloads/index.html).

### Instance Managers Consolidated

Engine instance mangers and replica instance managers has been consolidated. Previous engine/replica instance managers are now deprecated, but they will still provide service to the existing attached volumes.

The `Guaranteed Engine Manager CPU` and `Guaranteed Replica Manager CPU` settings are removed and replaced by `Guaranteed Instance Manager CPU`.

The `engineManagerCPURequest` and `replicaManagerCPURequest` fields in Longhorn Node custom resource spec are removed and replaced by `instanceManagerCPURequest`.

### Custom Resource Fields Removed

Starting from `v1.5.0`, the following deprecated custom resource fields will be removed:
- Volume.spec.recurringJob
- Volume.spec.baseImage
- Replica.spec.baseImage
- Replica.spec.dataPath
- InstanceManager.spec.engineImage
- BackingImage.spec.imageURL
- BackingImage.status.diskDownloadProgressMap
- BackingImage.status.diskDownloadStateMap
- BackingImageManager.status.backingImageFileMap.directory
- BackingImageManager.status.backingImageFileMap.downloadProgress
- BackingImageManager.status.backingImageFileMap.url
