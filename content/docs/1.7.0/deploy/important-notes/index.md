---
title: Important Notes
weight: 4
---

This page lists important notes for Longhorn v{{< current-version >}}.
Please see [here](https://github.com/longhorn/longhorn/releases/tag/v{{< current-version >}}) for the full release note.

- [General](#general)
  - [Supported Kubernetes Versions](#supported-kubernetes-versions)
  - [Pod Security Policies Disabled \& Pod Security Admission Introduction](#pod-security-policies-disabled--pod-security-admission-introduction)
  - [Introduction of Commandline Tool](#introduction-of-commandline-tool)
  - [Minimum XFS Filesystem Size](#minimum-xfs-filesystem-size)
  - [Longhorn PVC with Block Volume Mode](#longhorn-pvc-with-block-volume-mode)
- [Networking](#networking)
  - [Storage Network Support for Read-Write-Many (RWX) Volumes](#storage-network-support-for-read-write-many-rwx-volumes)
- [Resilience](#resilience)
  - [RWX Volumes Fast Failover](#rwx-volumes-fast-failover)
  - [Support Configurable Timeout for Replica Rebuilding and Snapshot cloning](#support-configurable-timeout-for-replica-rebuilding-and-snapshot-cloning)
- [Data Integrity and Reliability](#data-integrity-and-reliability)
  - [Support Periodic and On-Demand Full Backups to Enhance Backup Reliability](#support-periodic-and-on-demand-full-backups-to-enhance-backup-reliability)
  - [High Availability of Backing Images](#high-availability-of-backing-images)
- [V2 Data Engine](#v2-data-engine)
  - [Longhorn System Upgrade](#longhorn-system-upgrade)
  - [Introduction of Online Replica Rebuilding](#introduction-of-online-replica-rebuilding)
  - [Block-type Disk Supports SPDK AIO, NVMe and VirtIO Bdev Drivers](#block-type-disk-supports-spdk-aio-nvme-and-virtio-bdev-drivers)
  - [Introduction of Filesystem Trim](#introduction-of-filesystem-trim)
  - [Linux Kernel on Longhorn Nodes](#linux-kernel-on-longhorn-nodes)
  - [Snapshot Creation Time as shown in the UI occasionally changes](#snapshot-creation-time-as-shown-in-the-ui-occasionally-changes)
  - [Unable to Revert a Volume to a Snapshot Created before Longhorn v1.7.0](#unable-to-revert-a-volume-to-a-snapshot-created-before-longhorn-v170)

## General

### Supported Kubernetes Versions

Please ensure your Kubernetes cluster is at least v1.21 before upgrading to Longhorn v{{< current-version >}} because this is the minimum version Longhorn v{{< current-version >}} supports.

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

### Introduction of Commandline Tool

The longhornctl command-line tool was introduced in v1.7.0. It interacts with Longhorn by creating Kubernetes Custom Resources (CRs) and executing commands inside a dedicated Pod for in-cluster and host operations. Usage scenarios include installation, operations such as exporting replicas, and troubleshooting. For more information, please see [Command Line Tool (longhornctl)](../../advanced-resources/longhornctl/).

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
From this version, you need to add group id 6 to the security context or run container as root. For more information, see [Longhorn PVC ownership and permission](../../nodes-and-volumes/volumes/pvc-ownership-and-permission)

## Networking

### Storage Network Support for Read-Write-Many (RWX) Volumes

Starting with Longhorn v1.7.0, the [storage network](../../advanced-resources/deploy/storage-network/) supports RWX volumes. However, the network's reliance on Multus results in a significant restriction.

Multus networks operate within the Kubernetes network namespace, so Longhorn can mount NFS endpoints only within the CSI plugin pod container network namespace. Consequently, NFS mount connections to the Share Manager pod become unresponsive when the CSI plugin pod restarts. This occurs because the namespace in which the connection was established is no longer available.

Longhorn circumvents this restriction by providing the following settings:
- [Storage Network For RWX Volume Enabled](../../references/settings#storage-network-for-rwx-volume-enabled): When this setting is disabled, the storage network applies only to RWO volumes. The NFS client for RWX volumes is mounted over the cluster network in the host network namespace. This means that restarting the CSI plugin pod does not affect the NFS mount connections
- [Automatically Delete Workload Pod when The Volume Is Detached Unexpectedly](../../references/settings#automatically-delete-workload-pod-when-the-volume-is-detached-unexpectedly): When the RWX volumes are created over the storage network, this setting actively deletes RWX volume workload pods when the CSI plugin pod restarts. This allows the pods to be remounted and prevents dangling mount entries.

You can upgrade clusters with pre-existing RWX volume workloads to Longhorn v1.7.0. During and after the upgrade, the workload pod must not be interrupted because the NFS share connection uses the cluster IP, which remains valid in the host network namespace.

To apply the storage network to existing RWX volumes, you must detach the volumes, enable the [Storage Network For RWX Volume Enabled](../../references/settings#storage-network-for-rwx-volume-enabled) setting, and then reattach the volumes.

For more information, see [Issue #8184](https://github.com/longhorn/longhorn/issues/8184).

## Resilience

### RWX Volumes Fast Failover

RWX Volumes fast failover is introduced in Longhorn v1.7.0 to improve resilience to share-manager pod failures. This failover mechanism quickly detects and responds to share-manager pod failures independently of the Kubernetes node failure sequence and timing. For more information, see https://github.com/longhorn/longhorn/issues/6205.

### Support Configurable Timeout for Replica Rebuilding and Snapshot cloning

Since Longhorn v1.7.0, configurable timeouts for replica rebuilding and snapshot cloning are supported. Prior to v1.7.0, the timeout for replica rebuilding was capped at 24 hours, which could cause failures for large volumes in slow bandwidth environments. Now, the timeout is still 24 hours by default but can be adjusted to accommodate different environments. More information can be found [Settings Reference](http://0.0.0.0:8085/docs/1.7.0/references/settings/#long-grpc-timeout).

## Data Integrity and Reliability

### Support Periodic and On-Demand Full Backups to Enhance Backup Reliability

Since Longhorn v1.7.0, periodic and on-demand full backups have been supported to enhance backup reliability. Prior to v1.7.0, the initial backup was a full backup, with subsequent backups being incremental. If any block became corrupted, all backup revisions relying on that block would also be corrupted. To address this issue, Longhorn now supports performing a full backup after every N incremental backups, as well as on-demand full backups. This approach decreases the likelihood of backup corruption and enhances the overall reliability of the backup process. For more information, see [Recurring Snapshots and Backups](../../snapshots-and-backups/scheduling-backups-and-snapshots/) and [Create a Backup](../../snapshots-and-backups/backup-and-restore/create-a-backup/).

### High Availability of Backing Images

To address the single point of failure (SPOF) issue with backing images, high availability for backing images was introduced in Longhorn v1.7.0. For more information, please see [Backing Image](../../advanced-resources/backing-image/backing-image/#number-of-copies).

## V2 Data Engine

### Longhorn System Upgrade

Longhorn currently does not support live upgrading of V2 volumes. Ensure that all V2 volumes are detached before initiating the upgrade process.

### Introduction of Online Replica Rebuilding

Online replica rebuilding was introduced in Longhorn 1.7.0, so offline replica rebuilding has been removed.

### Block-type Disk Supports SPDK AIO, NVMe and VirtIO Bdev Drivers 

Before Longhorn v1.7.0, Longhorn block-type disks only supported the SPDK AIO bdev driver, which introduced extra performance penalties. Since v1.7.0, block devices can be directly managed by SPDK NVMe or VirtIO bdev drivers, improving IO performance through a kernel bypass scheme. For more information, see this [link](https://github.com/longhorn/longhorn/issues/7672).

### Introduction of Filesystem Trim

Filesystem trim is supported since Longhorn v1.7.0. If a disk is managed by the SPDK AIO bdev driver, the Trim (UNMAP) operation is not recommended in a production environment (ref). It is recommended to manage a block-type disk with an NVMe bdev driver.

### Linux Kernel on Longhorn Nodes

Host machines with Linux kernel 5.15 may unexpectedly reboot when volume-related IO errors occur. To prevent this, update the Linux kernel on Longhorn nodes to version 5.19 or later. For more information, see [Prerequisites](../../v2-data-engine/prerequisites/). Version 6.7 or later is recommended for improved system stability.

### Snapshot Creation Time as shown in the UI occasionally changes

Snapshots created before Longhorn v1.7.0 may change occasionally. This issue arises because the engine randomly selects a replica and its snapshot map each time the UI requests snapshot information or when a replica is rebuilt with a random healthy replica. This can lead to potential time gaps between snapshots among different replicas. Although this bug was fixed in v1.7.0, snapshots created before this version may still encounter the issue. For more information, see this [link](https://github.com/longhorn/longhorn/issues/7641).

### Unable to Revert a Volume to a Snapshot Created before Longhorn v1.7.0

Reverting a volume to a snapshot created before Longhorn v1.7.0 is not supported due to an incorrect UserCreated flag set on the snapshot. The workaround is to back up the existing snapshots before upgrading to Longhorn v1.7.0 and restore them if needed. The bug is fixed in v1.7.0, and more information can be found [here](https://github.com/longhorn/longhorn/issues/9054).




