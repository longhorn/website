---
title: Important Notes
weight: 1
---

This page lists important notes for Longhorn v{{< current-version >}}.
Please see [here](https://github.com/longhorn/longhorn/releases/tag/v{{< current-version >}}) for the full release note.

- [Deprecation](#deprecation)
  - [Environment Check Script](#environment-check-script)
- [General](#general)
  - [Pod Security Policies Disabled \& Pod Security Admission Introduction](#pod-security-policies-disabled--pod-security-admission-introduction)
  - [Command Line Tool](#command-line-tool)
  - [Minimum XFS Filesystem Size](#minimum-xfs-filesystem-size)
  - [Longhorn PVC with Block Volume Mode](#longhorn-pvc-with-block-volume-mode)
  - [Container-Optimized OS Support](#container-optimized-os-support)
  - [Upgrade Check Events](#upgrade-check-events)
  - [Install/Upgrade with Helm Controller](#installupgrade-with-helm-controller)
  - [Automatic Expansion of RWX Volumes](#automatic-expansion-of-rwx-volumes)
- [Resilience](#resilience)
  - [RWX Volumes Fast Failover](#rwx-volumes-fast-failover)
  - [Timeout Configuration for Replica Rebuilding and Snapshot Cloning](#timeout-configuration-for-replica-rebuilding-and-snapshot-cloning)
  - [Change in Engine Replica Timeout Behavior](#change-in-engine-replica-timeout-behavior)
- [Data Integrity and Reliability](#data-integrity-and-reliability)
  - [Support Periodic and On-Demand Full Backups to Enhance Backup Reliability](#support-periodic-and-on-demand-full-backups-to-enhance-backup-reliability)
  - [High Availability of Backing Images](#high-availability-of-backing-images)
- [Scheduling](#scheduling)
  - [Auto-Balance Pressured Disks](#auto-balance-pressured-disks)
- [Networking](#networking)
  - [Storage Network Support for Read-Write-Many (RWX) Volumes](#storage-network-support-for-read-write-many-rwx-volumes)
- [OS Distro Specific](#os-distro-specific)
  - [Talos Linux](#talos-linux)
- [Backup](#backup)
  - [Backup Data On The Remote Backup Server Might Be Deleted](#backup-data-on-the-remote-backup-server-might-be-deleted)
- [System Backup And Restore](#system-backup-and-restore)
  - [Volume Backup Policy](#volume-backup-policy)
- [V2 Data Engine](#v2-data-engine)
  - [Longhorn System Upgrade](#longhorn-system-upgrade)
  - [Enable Both `vfio_pci` and `uio_pci_generic` Kernel Modules](#enable-both-vfio_pci-and-uio_pci_generic-kernel-modules)
  - [Online Replica Rebuilding](#online-replica-rebuilding)
  - [Block-type Disk Supports SPDK AIO, NVMe and VirtIO Bdev Drivers](#block-type-disk-supports-spdk-aio-nvme-and-virtio-bdev-drivers)
  - [Filesystem Trim](#filesystem-trim)
  - [Linux Kernel on Longhorn Nodes](#linux-kernel-on-longhorn-nodes)
  - [Snapshot Creation Time As Shown in the UI Occasionally Changes](#snapshot-creation-time-as-shown-in-the-ui-occasionally-changes)
  - [Unable To Revert a Volume to a Snapshot Created Before Longhorn v1.7.0](#unable-to-revert-a-volume-to-a-snapshot-created-before-longhorn-v170)
  - [Disaster Recovery Volumes](#disaster-recovery-volumes)
  - [Auto-salvage Volumes](#auto-salvage-volumes)

## Deprecation

### Environment Check Script

The functionality of the [environment check script](https://github.com/longhorn/longhorn/blob/master/scripts/environment_check.sh) (`environment_check.sh`) overlaps with that of the Longhorn CLI, which is available starting with v1.7.0. Because of this, the script is deprecated in v1.7.0 and is scheduled for removal in v1.8.0.

## General

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

### Command Line Tool

The Longhorn CLI (binary name: `longhornctl`), which is the official Longhorn command line tool, was introduced in v1.7.0. This tool interacts with Longhorn by creating Kubernetes custom resources (CRs) and executing commands inside a dedicated pod for in-cluster and host operations. Usage scenarios include installation, operations such as exporting replicas, and troubleshooting. For more information, see [Command Line Tool (longhornctl)](../advanced-resources/longhornctl/).

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
From this version, you need to add group id 6 to the security context or run container as root. For more information, see [Longhorn PVC ownership and permission](../nodes-and-volumes/volumes/pvc-ownership-and-permission)

### Container-Optimized OS Support

Starting with Longhorn v1.7.0, Longhorn supports Container-Optimized OS (COS), providing robust and efficient persistent storage solutions for Kubernetes clusters running on COS. For more information, see [Container-Optimized OS (COS) Support](../advanced-resources/os-distro-specific/container-optimized-os-support/).  

### Upgrade Check Events
Longhorn performs a pre-upgrade check when upgrading with Helm or Rancher App Marketplace.  If a check fails, the upgrade will stop and the reason for the check's failure will be recorded in an event.  For more detail, see [Upgrading Longhorn Manager](../deploy/upgrade/longhorn-manager).

### Install/Upgrade with Helm Controller
Longhorn also supports installation or upgrade via the HelmChart controller built into RKE2 and K3s.  It allows management in a CRD YAML chart of most of the options that would normally be passed to the `helm` command-line tool. For more details on how it works, see [Install with Helm Controller](../deploy/install/install-with-helm-controller).

### Automatic Expansion of RWX Volumes
In v1.8.0, Longhorn supports fully automatic online expansion of RWX volumes.  There is no need to scale down the workload or apply manual commands.  Full details are in [RWX Volume](../nodes-and-volumes/volumes/expansion/#rwx-volume)

## Resilience

### RWX Volumes Fast Failover

RWX Volumes fast failover is introduced in Longhorn v1.7.0 to improve resilience to share-manager pod failures. This failover mechanism quickly detects and responds to share-manager pod failures independently of the Kubernetes node failure sequence and timing. For details, see [RWX Volume Fast Failover](../high-availability/rwx-volume-fast-failover).

> **Note:**  In rare circumstances, it is possible for the failover to become deadlocked. This happens if the NFS server pod creation is blocked by a recovery action that is itself blocked by the failover-in-process state.  If the feature is enabled, and a failover takes more than a minute or two, it is probably stuck in this situation.  There is an explanation and a workaround in [RWX Volume Fast Failover](../high-availability/rwx-volume-fast-failover).

### Timeout Configuration for Replica Rebuilding and Snapshot Cloning

Starting with v1.7.0, Longhorn supports configuration of timeouts for replica rebuilding and snapshot cloning. Before v1.7.0, the replica rebuilding timeout was capped at 24 hours, which could cause failures for large volumes in slow bandwidth environments. The default timeout is still 24 hours but you can adjust it to accommodate different environments. For more information, see [Long gRPC Timeout](../references/settings/#long-grpc-timeout).

### Change in Engine Replica Timeout Behavior

In versions earlier than v1.8.0, the [Engine Replica Timeout](../references/settings#engine-replica-timeout) setting
was equally applied to all V1 volume replicas. In v1.8.0, a V1 engine marks the last active replica as failed only after
twice the configured number of seconds (timeout value x 2) have passed.

## Data Integrity and Reliability

### Support Periodic and On-Demand Full Backups to Enhance Backup Reliability

Since Longhorn v1.7.0, periodic and on-demand full backups have been supported to enhance backup reliability. Prior to v1.7.0, the initial backup was a full backup, with subsequent backups being incremental. If any block became corrupted, all backup revisions relying on that block would also be corrupted. To address this issue, Longhorn now supports performing a full backup after every N incremental backups, as well as on-demand full backups. This approach decreases the likelihood of backup corruption and enhances the overall reliability of the backup process. For more information, see [Recurring Snapshots and Backups](../snapshots-and-backups/scheduling-backups-and-snapshots/) and [Create a Backup](../snapshots-and-backups/backup-and-restore/create-a-backup/).

### High Availability of Backing Images

To address the single point of failure (SPOF) issue with backing images, high availability for backing images was introduced in Longhorn v1.7.0. For more information, please see [Backing Image](../advanced-resources/backing-image/backing-image/#number-of-copies).

## Scheduling

### Auto-Balance Pressured Disks

The replica auto-balancing feature was enhanced in Longhorn v1.7.0 to address disk space pressure from growing volumes. A new setting, called `replica-auto-balance-disk-pressure-percentage`, allows you to set a threshold for automatic actions. The enhancements reduce the need for manual intervention by automatically rebalancing replicas during disk pressure, and improve performance by enabling faster replica rebuilding using local file copying. For more information, see [`replica-auto-balance-disk-pressure-percentage`](../references/settings#replica-auto-balance-disk-pressure-threshold-) and [Issue #4105](https://github.com/longhorn/longhorn/issues/4105).

## Networking

### Storage Network Support for Read-Write-Many (RWX) Volumes

Starting with Longhorn v1.7.0, the [storage network](../advanced-resources/deploy/storage-network/) supports RWX volumes. However, the network's reliance on Multus results in a significant restriction.

Multus networks operate within the Kubernetes network namespace, so Longhorn can mount NFS endpoints only within the CSI plugin pod container network namespace. Consequently, NFS mount connections to the Share Manager pod become unresponsive when the CSI plugin pod restarts. This occurs because the namespace in which the connection was established is no longer available.

Longhorn circumvents this restriction by providing the following settings:
- [Storage Network For RWX Volume Enabled](../references/settings#storage-network-for-rwx-volume-enabled): When this setting is disabled, the storage network applies only to RWO volumes. The NFS client for RWX volumes is mounted over the cluster network in the host network namespace. This means that restarting the CSI plugin pod does not affect the NFS mount connections
- [Automatically Delete Workload Pod when The Volume Is Detached Unexpectedly](../references/settings#automatically-delete-workload-pod-when-the-volume-is-detached-unexpectedly): When the RWX volumes are created over the storage network, this setting actively deletes RWX volume workload pods when the CSI plugin pod restarts. This allows the pods to be remounted and prevents dangling mount entries.

You can upgrade clusters with pre-existing RWX volume workloads to Longhorn v1.7.0. During and after the upgrade, the workload pod must not be interrupted because the NFS share connection uses the cluster IP, which remains valid in the host network namespace.

To apply the storage network to existing RWX volumes, you must detach the volumes, enable the [Storage Network For RWX Volume Enabled](../references/settings#storage-network-for-rwx-volume-enabled) setting, and then reattach the volumes.

For more information, see [Issue #8184](https://github.com/longhorn/longhorn/issues/8184).

## OS Distro Specific

### Talos Linux

Longhorn v1.8.0 and later versions support usage of V2 volumes in Talos Linux clusters. To use V2 volumes, ensure that all nodes meet the V2 Data Engine prerequisites. For more information, see [Talos Linux Support: V2 Data Engine](../advanced-resources/os-distro-specific/talos-linux-support#v2-data-engine).

## Backup

### Backup Data On The Remote Backup Server Might Be Deleted

Longhorn may unintentionally delete backup-related custom resources (such as `BackupVolume`, `BackupBackingImage`, `SystemBackup`, and `Backup`) and backup data on the remote backup server before Longhorn v{{< current-version >}} in the following scenarios:

- An empty response from the NFS server due to server downtime.
- A race condition could delete the remote backup volume and its corresponding backups when the backup target is reset within a short period.

Starting with v{{< current-version >}}, Longhorn handles backup-related custom resources in the following manner:

- If there are discrepancies between the backup information in the cluster and on the remote backup server, Longhorn deletes only the backup-related custom resources in the cluster.
- The backup-related custom resources in the cluster may be deleted unintentionally while the remote backup data remains safely stored. The deleted resources are resynchronized from the remote backup server during the next polling period (if the backup target is available).

For more information, see [#9530](https://github.com/longhorn/longhorn/issues/9530).

## System Backup And Restore

### Volume Backup Policy

Since Longhorn v1.8.0, the `if-not-present` volume backup policy now ensures the latest backup contains the most recent data. If the latest backup is outdated, Longhorn will create a new backup for the volume.

## V2 Data Engine

### Longhorn System Upgrade

Longhorn currently does not support live upgrading of V2 volumes. Ensure that all V2 volumes are detached before initiating the upgrade process.

### Enable Both `vfio_pci` and `uio_pci_generic` Kernel Modules

According to the [SPDK System Configuration User Guide](https://spdk.io/doc/system_configuration.html), neither `vfio_pci` nor `uio_pci_generic` is universally suitable for all devices and environments. Therefore, users can enable both `vfio_pci` and `uio_pci_generic` kernel modules. This allows Longhorn to automatically select the appropriate module. For more information, see this [link](https://github.com/longhorn/longhorn/issues/9182).

### Online Replica Rebuilding

Online replica rebuilding was introduced in Longhorn 1.7.0, so offline replica rebuilding has been removed.

### Block-type Disk Supports SPDK AIO, NVMe and VirtIO Bdev Drivers 

Before Longhorn v1.7.0, Longhorn block-type disks only supported the SPDK AIO bdev driver, which introduced extra performance penalties. Since v1.7.0, block devices can be directly managed by SPDK NVMe or VirtIO bdev drivers, improving IO performance through a kernel bypass scheme. For more information, see this [link](https://github.com/longhorn/longhorn/issues/7672).

### Filesystem Trim

Filesystem trim is supported since Longhorn v1.7.0. If a disk is managed by the SPDK AIO bdev driver, the Trim (UNMAP) operation is not recommended in a production environment (ref). It is recommended to manage a block-type disk with an NVMe bdev driver.

Starting with Longhorn v1.8.0, filesystem trim is blocked when the the targeting v2 volume is in a degraded state. This ensures the reliability of the volume head size during the [auto-salvage](#auto-salvage-volumes) operation.

### Linux Kernel on Longhorn Nodes

Host machines with Linux kernel 5.15 may unexpectedly reboot when volume-related IO errors occur. To prevent this, update the Linux kernel on Longhorn nodes to version 5.19 or later. For more information, see [Prerequisites](../v2-data-engine/prerequisites/). Version 6.7 or later is recommended for improved system stability.

### Snapshot Creation Time As Shown in the UI Occasionally Changes

Snapshots created before Longhorn v1.7.0 may change occasionally. This issue arises because the engine randomly selects a replica and its snapshot map each time the UI requests snapshot information or when a replica is rebuilt with a random healthy replica. This can lead to potential time gaps between snapshots among different replicas. Although this bug was fixed in v1.7.0, snapshots created before this version may still encounter the issue. For more information, see this [link](https://github.com/longhorn/longhorn/issues/7641).

### Unable To Revert a Volume to a Snapshot Created Before Longhorn v1.7.0

Reverting a volume to a snapshot created before Longhorn v1.7.0 is not supported due to an incorrect UserCreated flag set on the snapshot. The workaround is to back up the existing snapshots before upgrading to Longhorn v1.7.0 and restore them if needed. The bug is fixed in v1.7.0, and more information can be found [here](https://github.com/longhorn/longhorn/issues/9054).

### Disaster Recovery Volumes

Disaster recovery volumes are supported from Longhorn v1.8.0.

### Auto-salvage Volumes

Auto-salvage volumes are supported from Longhorn v1.8.0.
