---
title: Important Notes
weight: 4
---

This page lists important notes for Longhorn v{{< current-version >}}.
Please see [here](https://github.com/longhorn/longhorn/releases/tag/v{{< current-version >}}) for the full release note.

## Notes

### Supported Kubernetes Versions

Please ensure your Kubernetes cluster is at least v1.21 before upgrading to Longhorn v{{< current-version >}} because this is the minimum version Longhorn v{{< current-version >}} supports.

### Detach All V2 Volumes Before Upgrade

Please note that Longhorn does not support the upgrade when v2 volumes are attached. Prior to initiating the upgrade process, ensure that all v2 volumes are detached.

### Offline Upgrade Required To Fully Prevent Unexpected Replica Expansion

Longhorn v1.5.2 introduces a new mechanism to prevent [unexpected replica
expansion](../../../../kb/troubleshooting-unexpected-expansion-leads-to-degradation-or-attach-failure). This
mechanism is entirely transparent. However, a volume is only protected if it is running a new version of longhorn-engine
inside a new version of longhorn-instance-manager and managed by a new version of longhorn-manager. The [live upgrade
process](../../deploy/upgrade/upgrade-engine#live-upgrade) results in a volume running a new version of longhorn-engine
in an old version of longhorn-instance-manager until it is detached (by scaling its consuming workload down) and
reattached (by scaling its consuming workload up). Consider scaling workloads down and back up again as soon as possible
after upgrading from a version without this mechanism (v1.5.1 or older) to v{{< current-version >}}.

### Attachment/Detachment Refactoring Side Effect On The Upgrade Process

In Longhorn v1.5.0, we refactored the internal volume attach/detach mechanism.
As a side effect, when you are upgrading from v1.4.x to v1.5.x, if there are in-progress operations such as volume cloning, backing image export from volume, and volume offline expansion, these operations will fail.
You will have to retry them manually.
To avoid this issue, please don't perform these operations during the upgrade.
Ref: https://github.com/longhorn/longhorn/issues/3715#issuecomment-1562305097

### Recurring Jobs

The behavior of the recurring job types `Snapshot` and `Backup` will attempt to delete old snapshots first if they exceed the retained count before creating a new snapshot. Additionally, two new recurring job types have been introduced, `Snapshot Force Create` and `Backup Force Create`. They retain the original behavior of taking a snapshot or backup first before deleting outdated snapshots.

### Longhorn Uninstallation

To prevent Longhorn from being accidentally uninstalled (which leads to data lost),
we introduce a new setting, [deleting-confirmation-flag](../../references/settings/#deleting-confirmation-flag).
If this flag is **false**, the Longhorn uninstallation job will fail.
Set this flag to **true** to allow Longhorn uninstallation.
See more in the [uninstall](../uninstall) section.

### New Node Drain Policies Added

There are two new options for the [Node Drain Policy](../../references/settings#node-drain-policy) setting. Both `Block
For Eviction` and `Block for Eviction If Contains Last Replica` automatically evict replicas from draining nodes in
addition to preventing drain completion until volume data is sufficiently protected. `Block for Eviction` maintains
maximum data redundancy during maintenance operations, and both new options enable automated cluster upgrades when some
volumes have only one replica. See the new [Node Drain Policy
Recommendations](../../volumes-and-nodes/maintenance/#node-drain-policy-recommendations) section for help deciding which
policy to use.

### Custom Resource Fields Deprecated

Starting in `v1.5.4`, the following custom resource fields are deprecated. They will be removed in `v1.7.0`:

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

### `Custom mkfs.ext4 Parameters` Setting Removed

The `Custom mkfs.ext4 Parameters` setting was deprecated in Longhorn `v1.4.0` and is now removed. The per-StorageClass `mkfsParams` parameter should be used to specify mkfs options (e.g., `-I 256 -b 4096 -O ^metadata_csum,^64bit`) instead. See [Creating Longhorn Volumes with kubectl](../../volumes-and-nodes/create-volumes/#creating-longhorn-volumes-with-kubectl) for details.

### `Disable Replica Rebuild` Setting Removed

The `Disable Replica Rebuild` setting was deprecated and replaced by the [Concurrent Replica Rebuild Per Node Limit](../../references/settings/#concurrent-replica-rebuild-per-node-limit) setting in Longhorn `v1.2.1`. It should already have been ignored in any Longhorn deployment upgrading to Longhorn v{{< current-version >}} and is now removed. To disable replica rebuilding across the cluster, set the `Concurrent Replica Rebuild Per Node Limit` to 0.

### `Default Manager Image` Settings Removed

The `Default Backing Image Manager Image`, `Default Instance Manager Image` and `Default Share Manager Image` settings were deprecated and removed from `v1.5.0`. These default manager image settings can be changed on the manager starting command line only. They should be modified in the Longhorn deploying manifest or `values.yaml` in Longhorn chart.

### `Allow Node Drain with the Last Healthy Replica` Settings Removed
The `Allow Node Drain with the Last Healthy Replica` setting was deprecated in Longhorn v1.4.2  and is now removed.
Please use the new setting [Node Drain Policy](../../references/settings#node-drain-policy) instead.

### Instance Managers Consolidated

Engine instance managers and replica instance managers has been consolidated. Previous engine/replica instance managers are now deprecated, but they will still provide service to the existing attached volumes.

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

### Longhorn PVC with Block Volume Mode

Starting with v1.6.0, Longhorn is changing the default group ID of Longhorn devices from `0` (root group) to `6` (typically associated with the "disk" group).
This change allows non-root containers to read or write to PVs using the **Block** volume mode. Note that Longhorn still keeps the owner of the Longhorn block devices as root.
As a result, if your pod has security context such that it runs as non-root user and is part of the group id 0, the pod will no longer be able to read or write to Longhorn block volume mode PVC anymore.
This use case should be very rare because running as a non-root user with the root group does not make much sense.
More specifically, this example will not work anymore:
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: longhorn-block-vol
spec:
  accessModes:
    - ReadWriteOnce
  volumeMode: Block
  storageClassName: longhorn
  resources:
    requests:
      storage: 2Gi
---
apiVersion: v1
kind: Pod
metadata:
  name: block-volume-test
  namespace: default
spec:
  securityContext:
    runAsGroup: 1000
    runAsNonRoot: true
    runAsUser: 1000
    supplementalGroups:
    - 0
  containers:
    - name: block-volume-test
      image: ubuntu:20.04
      command: ["sleep", "360000"]
      imagePullPolicy: IfNotPresent
      volumeDevices:
        - devicePath: /dev/longhorn/testblk
          name: block-vol
  volumes:
    - name: block-vol
      persistentVolumeClaim:
        claimName: longhorn-block-vol
```
From this version, you need to add group id 6 to the security context or run container as root. For more information, see [Longhorn PVC ownership and permission](../../volumes-and-nodes/pvc-ownership-and-permission)

### Minimum XFS Filesystem Size

Recent versions of `xfsprogs` (including the version Longhorn currently uses) *do not allow* the creation of XFS
filesystems [smaller than 300
MiB](https://git.kernel.org/pub/scm/fs/xfs/xfsprogs-dev.git/commit/?id=6e0ed3d19c54603f0f7d628ea04b550151d8a262).
Longhorn v{{< current-version >}} does not allow the following:

- CSI flow: Volume provisioning if `resources.requests.storage < 300 Mi` and the corresponding StorageClass has `fsType:
  xfs`
- Longhorn UI: `Create PV/PVC` with `File System: XFS` action to be completed on a volume that has `spec.size < 300 Mi`

However, Longhorn still allows the listed actions when cloning or restoring volumes created with earlier Longhorn
versions.
