---
title: Terminology
weight: 4
---

- [Attach/Reattach](#attachreattach)
- [Backup](#backup)
- [Backupstore](#backupstore)
- [Backup target](#backup-target)
- [Backup volume](#backup-volume)
- [Block storage](#block-storage)
- [CSI Driver](#csi-driver)
- [Disaster recovery volumes (DR volumes)](#disaster-recovery-volumes-dr-volume)
- [ext4](#ext4)
- [Frontend expansion](#frontend-expansion)
- [Instance manager](#instance-manager)
- [Longhorn volume](#longhorn-volume)
- [Mount](#mount)
- [NFS](#nfs)
- [Object storage](#object-storage)
- [Offline expansion](#offline-expansion)
- [Overprovisioning](#overprovisioning)
- [PersistentVolume](#persistentvolume)
- [PersistentVolumeClaim](#persistentvolumeclaim)
- [Primary backups](#primary-backups)
- [Remount](#remount)
- [Replica](#replica)
- [S3](#s3)
- [Salvage a volume](#salvage-a-volume)
- [Secondary backups](#secondary-backups)
- [Snapshot](#snapshot)
- [Stable identity](#stable-identity)
- [StatefulSet](#statefulset)
- [StorageClass](#storageclass)
- [Thin provisioning](#thin-provisioning)
- [Umount](#umount)
- [Volume (Kubernetes concept)](#volume-kubernetes-concept)
- [XFS](#xfs)

### Attach/Reattach

To attach a block device is to make it appear on the Linux node, e.g. `/dev/longhorn/testvol`

If the volume engine dies unexpectedly, Longhorn will reattach the volume.

### Backup

A backup is an object in the backupstore. The backupstore contains backup volumes, and each backup volume may contain multiple backups for the same original volume.

Backups can be created from snapshots. They contain the state of the volume at the time the snapshot was created, but they don't contain snapshots, so they do not contain the history of changes to the volume data. While backups are made of 2 MB files, snapshots can be terabytes.

Backups are made of 2 MB blocks in an object store.

For a longer explanation of how snapshots and backups work, refer to the [conceptual documentation.](../concepts/#241-how-snapshots-work)

### Backupstore

Longhorn backups are saved to the backupstore, which is external to the Kubernetes cluster. The backupstore can be either NFS shares or an S3 compatible server.

Longhorn accesses the backupstore at the endpoint configured in the backuptarget.

### Backup target 

A backup target is the endpoint used to access a backupstore in Longhorn.

### Backup volume

A backup volume is the backup that maps to one original volume, and it is located in the backupstore. Backup volumes can be viewed on the **Backup** page in the Longhorn UI. The backup volume will contain multiple backups for the same volume.

### Block storage

An approach to storage in which data stored in fixed-size blocks. Each block is distinguished based on a memory address.

### CRD

A Kubernetes [custom resource definition.](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/)

### CSI Driver

The Longhorn CSI Driver is a [container storage interface](https://kubernetes-csi.github.io/docs/drivers.html) that can be used with Kubernetes. The CSI driver for Longhorn volumes is named `driver.longhorn.io`.

### Disaster Recovery Volumes (DR volume)

A DR volume is a special volume that stores data in a backup cluster in case the whole main cluster goes down. DR volumes are used to increase the resiliency of Longhorn volumes.

Each backup volume in the backupstore maps to one original volume in the Kubernetes cluster. Likewise, each DR volume maps to a backup volume in the backupstore.

DR volumes can be created to accurately reflect backups of a Longhorn volume, but they cannot be used as a normal Longhorn volume until they are activated.

### ext4

A file system for Linux. Longhorn supports ext4 for storage.

### Frontend expansion

The frontend here is referring to the block device exposed by the Longhorn volume.

### Instance Manager

The Longhorn component for controller/replica instance lifecycle management.

### Longhorn volume

A Longhorn volume is a Kubernetes volume that is replicated and managed by the Longhorn Manager. For each volume, the Longhorn Manager also creates:

- An instance of the Longhorn Engine
- Replicas of the volume, where each replica consists of a series of snapshots of the volume

Each replica contains a chain of snapshots, which record the changes in the volume's history. Three replicas are created by default, and they are usually stored on separate nodes for high availability.

### Mount

A Linux command to mount the block device to a certain directory on the node, e.g. `mount /dev/longhorn/testvol /mnt`

### NFS

A [distributed file system protocol](https://en.wikipedia.org/wiki/Network_File_System) that allows you to access files over a computer network, similar to the way that local storage is accessed. Longhorn supports using NFS as a backupstore for secondary storage.

### Object storage

Data storage architecture that manages data as objects. Each object typically includes the data itself, a variable amount of metadata, and a globally unique identifier.  Longhorn volumes can be backed up to S3 compatible object storage.

### Offline expansion

In an offline volume expansion, the volume is detached.

### Overprovisioning

Overprovisioning allows a server to view more storage capacity than has been physically reserved. That means we can schedule a total of 750 GiB Longhorn volumes on a 200 GiB disk with 50G reserved for the root file system. The **Storage Over Provisioning Percentage** can be configured in the Longhorn [settings.](../references/settings)

### PersistentVolume

A PersistentVolume (PV) is a Kubernetes resource that represents piece of storage in the cluster that has been provisioned by an administrator or dynamically provisioned using Storage Classes. It is a cluster-level resource, and is required for pods to use persistent storage that is independent of the lifecycle of any individual pod. For more information, see the official [Kubernetes documentation about persistent volumes.](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)

### PersistentVolumeClaim

A PersistentVolumeClaim (PVC) is a request for storage by a user. Pods can request specific levels of resources (CPU and Memory) by using a PVC for storage. Claims can request specific sizes and access modes (e.g., they can be mounted once read/write or many times read-only).

For more information, see the official [Kubernetes documentation.](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)

### Primary backups

The replicas of each Longhorn volume on a Kubernetes cluster can be considered primary backups.

### Remount

In a remount, Longhorn will detect and mount the filesystem for the volume after the reattachment.

### Replica

A replica consists of a chain of snapshots, showing a history of the changes in the data within a volume.

### S3

[Amazon S3](https://aws.amazon.com/s3/) is an object storage service.

### Salvage a volume

The salvage operation is needed when all replicas become faulty, e.g. due to a network disconnection.

When salvaging a volume, Longhorn will try to figure out which replica(s) are usable, then use them to recover the volume.

### Secondary backups

Backups external to the Kubernetes cluster, on S3 or NFS.

### Snapshot

A snapshot in Longhorn captures the state of a volume at the time the snapshot is created. Each snapshot only captures changes that overwrite data from earlier snapshots, so a sequence of snapshots is needed to fully represent the full state of the volume. Volumes can be restored from a snapshot. For a longer explanation of snapshots, refer to the [conceptual documentation.](../concepts)

### Stable identity

[StatefulSets](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/) have a stable identity, which means that Kubernetes won't force delete the Pod for the user.

### StatefulSet

A [Kubernetes resource](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/) used for managing stateful applications.

### StorageClass

A Kubernetes resource that can be used to automatically provision a PersistentVolume for a pod. For more information, refer to the [Kubernetes documentation.](https://kubernetes.io/docs/concepts/storage/storage-classes/#the-storageclass-resource)

### Thin provisioning

Longhorn is a thin-provisioned storage system. That means a Longhorn volume will only take the space it needs at the moment. For example, if you allocated a 20 GB volume but only use 1 GB of it, the actual data size on your disk would be 1GB. 

### Umount

A [Linux command](https://linux.die.net/man/8/umount) that detaches the file system from the file hierarchy.

### Volume (Kubernetes concept)

A volume in Kubernetes allows a pod to store files during the lifetime of the pod.

These files will still be available after a container crashes, but they will not be available past the lifetime of a pod. To get storage that is still available after the lifetime of a pod, a Kubernetes [PersistentVolume (PV)](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistent-volumes) is required.

For more information, see the Kubernetes documentation on [volumes.](https://kubernetes.io/docs/concepts/storage/volumes/)

### XFS
A [file system](https://en.wikipedia.org/wiki/XFS) supported by most Linux distributions. Longhorn supports XFS for storage.