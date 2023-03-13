---
title: Important Notes
weight: 4
---

This page lists important notes for Longhorn v{{< current-version >}}.
Please see [here](https://github.com/longhorn/longhorn/releases/tag/v{{< current-version >}}) for the full release note.

## Notes

### Supported Kubernetes Versions
Please ensure your Kubernetes cluster is at least v1.21 before upgrading to Longhorn v{{< current-version >}} because the supported Kubernetes version has been updated in v{{< current-version >}}.

### Recurring Jobs
After the upgrade, the recurring job settings of volumes will be migrated to new recurring job resources, and the `RecurringJobs` field in the volume spec will be deprecated. [[doc](https://longhorn.io/docs/{{< current-version >}}/deploy/upgrade/#4-automatically-migrate-recurring-jobs)]

### Backup Migration Time
When upgrading from a Longhorn version >= 1.2.0 and <= v1.2.3 to v{{< current-version >}}, if your cluster has many backups, you may expect to have a long upgrade time (with 22000 backups, it could take a few hours). Helm upgrade may timeout and you may need to re-run the upgrade command or set a longer timeout. This is [a known issue](https://github.com/longhorn/longhorn/issues/3890).

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

### Updating CSI Snapshot CRD `v1beta1` to `v1`, `v1beta1` Deprecated

The CSI snapshot CRDs `v1beta1` version is being deprecated and replaced by `v1` version,
please follow the instruction [Enable CSI Snapshot Support](../../snapshots-and-backups/csi-snapshot-support/enable-csi-snapshot-support) to update CSI snapshot CRDs and CSI snapshot controller.
If you have manifests or scripts that are still using `v1beta1` version, consider upgrading them to use `v1` as well.

### Add StorageClass Parameter `mkfsParams` and [`Custom mkfs.ext4 parameters`](../../references/settings/#custom-mkfsext4-parameters) Setting Deprecated

The [`Custom mkfs.ext4 parameters`](../../references/settings/#custom-mkfsext4-parameters) will be deprecated and replaced by a new parameter `mkfsParams` as a per-StorageClass mkfs option (e.g., `-I 256 -b 4096 -O ^metadata_csum,^64bit`).

### Longhorn Supports Fast Replica Rebuilding, and It Is Enabled by Default

Fast replica rebuilding is supported by Longhorn, and is enabled by default. The feature relies on the change timestamps and checksums of snapshot disk files, so `snapshot-data-integrity` is also set to `fast-check`. The file checksums for snapshot disks will be calculated periodically, with a default check period of 7 days. For more information, please refer to [Fast Replica Rebuild](../../advanced-resources/fast-replica-rebuild/index.html) and [Snapshot Data Integrity Check](../../advanced-resources/snapshot-data-integrity-check/index.html).

### Each Kubernetes Node Must Have a Unique Hostname for RWX Volumes
Longhorn has a dedicated recovery backend service for NFS servers in the share-manager pods used by the RWX volumes. The clients' information, including its hostname, will be stored in the recovery backend. The information will be used for connection recovery if the share-manager pod is abnormally terminated and a new one is created. The [environment check script](https://raw.githubusercontent.com/longhorn/longhorn/v{{< current-version >}}/scripts/environment_check.sh) helps users to check all nodes have unique hostnames.
More information please refer to [ReadWriteMany (RWX) Volume](../../advanced-resources/rwx-workloads/index.html).
