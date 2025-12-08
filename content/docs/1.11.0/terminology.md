---
title: Terminology
weight: 3
---

- [Attach/Reattach](#attachreattach)
- [Backup](#backup)
- [Backupstore](#backupstore)
- [Backup Target](#backup-target)
- [Backup Volume](#backup-volume)
- [Block Storage](#block-storage)
- [block-type Disks](#block-type-disks)
- [CRD](#crd)
- [Cross-Cluster Disaster Recovery](#cross-cluster-disaster-recovery)
- [CSI Driver](#csi-driver)
- [Disaster Recovery Volumes (DR volume)](#disaster-recovery-volumes-dr-volume)
- [ext4](#ext4)
- [Frontend Expansion](#frontend-expansion)
- [Instance Manager](#instance-manager)
- [Longhorn Engine](#longhorn-engine)
- [Longhorn Manager](#longhorn-manager)
- [Longhorn Volume](#longhorn-volume)
- [Maintenance Mode](#maintenance-mode)
- [Mount](#mount)
- [NFS](#nfs)
- [Object Storage](#object-storage)
- [Offline Expansion](#offline-expansion)
- [Overprovisioning](#overprovisioning)
- [PersistentVolume](#persistentvolume)
- [PersistentVolumeClaim](#persistentvolumeclaim)
- [Primary Backups](#primary-backups)
- [Read Index](#read-index)
- [Recurring Snapshots](#recurring-snapshots)
- [Remount](#remount)
- [Replica](#replica)
- [S3](#s3)
- [Salvage a Volume](#salvage-a-volume)
- [Secondary Backups](#secondary-backups)
- [SMB/CIFS](#smbcifs)
- [Snapshot](#snapshot)
- [Snapshot Data Integrity](#snapshot-data-integrity)
- [Stable Identity](#stable-identity)
- [StatefulSet](#statefulset)
- [StorageClass](#storageclass)
- [System Backup](#system-backup)
- [Thin Provisioning](#thin-provisioning)
- [Umount](#umount)
- [V2 Data Engine](#v2-data-engine)
- [Volumes (Kubernetes Concept)](#volumes-kubernetes-concept)
- [XFS](#xfs)

### Attach/Reattach

To attach a block device is to make it appear on the Linux node (for example, `/dev/longhorn/testvol`).  
If the volume engine dies unexpectedly, Longhorn will automatically reattach the volume.

### Backup

A backup is an object stored in the backupstore. The backupstore may contain both volume backups and system backups.

### Backupstore

The backupstore is the external storage location where Longhorn backups are saved.  
It can be either an NFS share or an S3-compatible object store.  
Longhorn connects to the backupstore through the configured backup target.

### Backup Target

The backup target is the endpoint used to access a backupstore in Longhorn.

### Backup Volume

A backup volume represents all backups associated with a single original Longhorn volume.  
It is stored in the backupstore and visible in the **Backup** page of the Longhorn UI.

Backup volumes contain multiple backups for the same volume.  
Backups are created from snapshots and capture the state of the volume at the time the snapshot was taken.  
They do not include the snapshot chain or history of changes.

Backups are stored as 2 MiB blocks in object storage.

For more details on how snapshots and backups work, see the [concepts documentation](../concepts/#241-how-snapshots-work).

### Block Storage

A storage approach in which data is stored in fixed-size blocks, each identified by a memory address.

### block-type Disks

A block-type disk is required for Longhorn’s V2 Data Engine volumes, as opposed to the filesystem-type disks used for V1 volumes.

### CRD

A Kubernetes [custom resource definition](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/).

### Cross-Cluster Disaster Recovery

Cross-cluster disaster recovery allows data from a primary Kubernetes cluster to be quickly recovered in a second, separate cluster using backups.

### CSI Driver

The Longhorn CSI Driver implements the Kubernetes [Container Storage Interface](https://kubernetes-csi.github.io/docs/drivers.html).

The CSI driver name for Longhorn volumes is `driver.longhorn.io`.

### Disaster Recovery Volumes (DR volume)

A Disaster Recovery (DR) volume is a special volume used to maintain a copy of data in a backup cluster so the workload can recover if the primary cluster becomes unavailable. DR volumes are used to increase the resiliency of Longhorn volumes.

Each backup volume in the backupstore corresponds to one original volume, and each DR volume corresponds to a backup volume. Similarly, each DR volume maps to a backup volume in the backupstore.

DR volumes can be created to accurately reflect backups of a Longhorn volume but cannot function as normal Longhorn volumes until they are activated.

### ext4

A Linux file system supported by Longhorn for storage.

### Frontend Expansion

“Frontend” refers to the block device exposed by a Longhorn volume.

### Instance Manager

The Longhorn component responsible for managing the lifecycle of controller and replica instances.

### Longhorn Engine

The Longhorn Engine is a data plane component of Longhorn. It is a dedicated storage controller that runs for each volume, synchronously replicating data to its replicas.

### Longhorn Manager

The Longhorn Manager is the control plane component of Longhorn. It is a Kubernetes DaemonSet responsible for managing volumes, handling API calls, and orchestrating Longhorn Engines.

### Longhorn Volume

A Longhorn volume is a Kubernetes volume managed and replicated by Longhorn.

For each volume, Longhorn Manager creates:
- a Longhorn Engine instance  
- multiple replicas, each containing a snapshot chain representing the volume’s history

Each replica contains a chain of snapshots which record the changes in the volume’s history.
By default, three replicas are created and distributed across different nodes to ensure high availability.

### Maintenance Mode

A volume attachment mode that attaches the volume without enabling the frontend (block device or iSCSI), primarily used to revert a volume from a snapshot.

### Mount

A Linux command used to attach a block device to a directory on the node (for example, `mount /dev/longhorn/testvol /mnt`).

### NFS

A [distributed file system protocol](https://en.wikipedia.org/wiki/Network_File_System) that allows network-based file access.  
Longhorn supports using NFS as a backupstore for secondary storage.

### Object Storage

A data storage architecture that manages data as objects, each containing the data, a variable amount of metadata and a global unique identifier.  
Longhorn supports backing up volumes to S3-compatible object stores.

### Offline Expansion

A volume expansion performed while the volume is detached.

### Overprovisioning

Overprovisioning allows more logical storage to be allocated than the physical capacity available.

For example, a node with 200 GiB of disk space (with 50 GiB reserved for the OS) could provision 750 GiB of Longhorn volumes.  

The **Storage Over Provisioning Percentage** is configurable in Longhorn [settings](../references/settings).

### PersistentVolume

A PersistentVolume (PV) is a Kubernetes resource that represents a piece of storage in the cluster. It may be provisioned manually or dynamically using StorageClasses.

It is a cluster-level resource and is required for pods to use persistent storage that is independent of the pod lifecycle.

For more information, see the Kubernetes documentation on [persistent volumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/).

### PersistentVolumeClaim

A PersistentVolumeClaim (PVC) is a user request for storage. Pods can request specific levels of resources (CPU and Memory) by using a PVC for storage. 
Claims specify desired size and access modes (for example, ReadWriteOnce or ReadOnlyMany).  
Pods use PVCs to obtain persistent storage.

See the official [Kubernetes documentation](https://kubernetes.io/docs/concepts/storage/persistent-volumes/).

### Primary Backups

The replicas of a Longhorn volume within the Kubernetes cluster can be considered primary backups.

### Read Index

The read index is an in-memory data structure used by each replica to improve read performance.  
It records which differencing disk (snapshot) contains the valid data for each 4K block.

### Recurring Snapshots

Recurring snapshots allow Longhorn to automatically create and retain snapshots at a specified frequency (for example, hourly or daily).

### Remount

After reattachment, Longhorn automatically detects and mounts the filesystem of the volume.

### Replica

A replica is a copy of a Longhorn volume, consisting of a snapshot chain that records the history of changes.

### S3

[Amazon S3](https://aws.amazon.com/s3/) is an object storage service.

### Salvage a Volume

Salvage operation is required when all replicas become faulty (for example, due to network disconnection).  
During salvage, Longhorn tries to identify any usable replicas and then uses them to recover the volume.

### Secondary Backups

Backups stored external to the Kubernetes cluster, on S3 or NFS.

### SMB/CIFS

A [network file-sharing protocol](https://en.wikipedia.org/wiki/Network_File_System) that provides remote file access similar to local storage.  
Longhorn supports using SMB/CIFS as a backupstore for secondary storage.

### Snapshot

A snapshot captures the state of a volume at the time the snapshot is created. 
Each snapshot stores only the changes that overwrite earlier data, so a chain of snapshots is required to represent the full state.

Volumes can be restored from snapshots.

See the [concepts documentation](../concepts) for more details.

### Snapshot Data Integrity

Snapshot Data Integrity is a Longhorn feature that hashes snapshot disk files and periodically checks their integrity to detect filesystem-unaware corruption, such as bit rot.

### Stable Identity

[StatefulSets](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/) have a stable identity, meaning Kubernetes will not force-delete the pod for the user.

### StatefulSet

A [Kubernetes resource](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/) used for managing stateful applications.

### StorageClass

A [Kubernetes resource](https://kubernetes.io/docs/concepts/storage/storage-classes/#the-storageclass-resource) used to automatically provision PersistentVolumes for pods.

### System Backup

A system backup contains a bundle of Longhorn system resources and is stored in the backupstore.

See the [Longhorn System Backup Bundle](../advanced-resources/system-backup-restore/backup-longhorn-system/#longhorn-system-backup-bundle) for details.

### Thin Provisioning

Longhorn volumes are thin-provisioned: they consume only the storage used.  
For example, a 20 GiB volume that stores 1 GiB of data uses only 1 GiB of disk space.

### Umount

A [Linux command](https://linux.die.net/man/8/umount) that detaches a file system from the file hierarchy.

### V2 Data Engine

The V2 Data Engine is an experimental data plane implementation in Longhorn.  
It uses SPDK, requires huge pages, and uses block-type disks to achieve improved performance.

### Volumes (Kubernetes Concept)

A Kubernetes volume allows a pod to store files during its lifetime.  
These files persist across container restarts but not when the pod is deleted.

To preserve storage beyond the pod lifecycle, a [PersistentVolume (PV)](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistent-volumes) is required.

See the [Kubernetes documentation - Volumes](https://kubernetes.io/docs/concepts/storage/volumes/) for more details.

### XFS

A high-performance Linux [file system](https://en.wikipedia.org/wiki/XFS) supported by Longhorn for storage.
