---
title: Architecture
description: Longhorn Architecture
weight: 2
---


Longhorn implements distributed block storage using containers and microservices. It creates a dedicated storage controller for each block device volume and synchronously replicates the volume across multiple replicas stored on multiple nodes. The storage controller and replicas are themselves orchestrated using [Kubernetes](https://kubernetes.io).

The Longhorn manager is responsible for creating and managing volumes in the Kubernetes cluster.

When the Longhorn manager is asked to create a volume, it creates engine processes on the node the volume is attached to, as well as the nodes where the replicas will be placed. Replicas should be placed on separate hosts to ensure maximum availability.

In the figure below, there are three Pods with Longhorn volumes. Each Volume has a dedicated engine, which runs as a process inside an Instance Manager Pod. Each engine has two replicas and each replica is a process inside an Instance Manager Pod. The arrows in the figure indicate the read/write data flow between the Kubernetes Volume, engine process, replica processes, and disks. By creating a separate engine for each volume, if one engine fails, the function of other volumes is not impacted.

{{< figure alt="read/write data flow between the Docker volume, controller container, replica containers, and disks" src="/img/diagrams/architecture/longhorn-controllers.png" >}}

For example, in a large-scale deployment with 100,000 Kubernetes Volumes, each with three replicas, there will be 100,000 engine processes and 300,000 replica processes. In order to schedule, monitor, coordinate, and repair all these engines and replicas, a storage orchestration system is needed.

## Replica Operations

Longhorn replicas are built using Linux sparse files, which support thin provisioning. We currently do not maintain additional metadata to indicate which blocks are used. The block size is 4K. When you take a snapshot, you create a differencing disk. As the number of snapshots grows, the differencing disk chain could get quite long. To improve read performance, Longhorn therefore maintains a read index that records which differencing disk holds valid data for each 4K block.

In the following figure, the volume has eight blocks. The read index has eight entries and is filled up lazily as read operations take place. A write operation resets the read index, causing it to point to the live data.

{{< figure src="/img/diagrams/architecture/read-index.png" >}}

The read index is kept in memory and consumes one byte for each 4K block. The byte-sized read index means you can take as many as 254 snapshots for each volume. The read index consumes a certain amount of in-memory data structure for each replica. A 1 TB volume, for example, consumes 256 MB of in-memory read index. We will potentially consider placing the read index in memory-mapped files in the future.

## Replica Rebuild

When the controller detects failures in one of its replicas, it marks the replica as being in an error state. The Longhorn manager is responsible for initiating and coordinating the process of rebuilding the faulty replica as follows:

- The Longhorn manager creates a blank replica and calls the engine to add the blank replica into its replica set.
- To add the blank replica, the engine performs the following operations:
  - Pauses all read and write operations.
  - Adds the blank replica in WO (write-only) mode.
  - Takes a snapshot of all existing replicas, which will now have a blank differencing disk at its head.
  - Unpauses all read the write operations. Only write operations will be dispatched to the newly added replica.
  - Starts a background process to sync all but the most recent differencing disk from a good replica to the blank replica.
  - After the sync completes, all replicas now have consistent data, and the volume manager sets the new replica to RW (read-write) mode.
- The Longhorn manager calls the engine to remove the faulty replica from its replica set.

## Backup and Restore

Snapshot and backup operations are performed separately. The backups are incremental, detecting and transmitting the changed blocks between snapshots. This is a relatively easy task since each snapshot is a differencing file and only stores the changes from the last snapshot. To avoid storing a very large number of small blocks, Longhorn performs backup operations using 2 MB blocks. That means that, if any 4K block in a 2 MB boundary is changed, it will have to backup the entire 2 MB block. This offers the right balance between manageability and efficiency.

In the following figure, Longhorn has backed up both snap2 and snap3. Each backup maintains its own set of 2 MB blocks, and the two backups share one green block and one blue block. Each 2 MB block is backed up only once. When the user deletes a backup from secondary storage, Longhorn does not delete all the blocks it uses. Instead, it performs garbage collection upon a backup deletion to clean up unused blocks from secondary storage.

{{< figure src="/img/diagrams/architecture/snapshot-backups.png" >}}

Longhorn stores all backups for a given volume under a common directory. The following figure depicts a somewhat simplified view of how Longhorn stores backups for a volume. Volume-level metadata is stored in `volume.cfg`.

Volume-level metadata is stored in `volume.cfg`. The metadata files for each backup (e.g., `snap2.cfg`) are relatively small because they only contain the offsets and check sums of all the 2 MB blocks in the backup. The 2 MB blocks for all backups belonging to the same volume are stored under a common directory and can therefore be shared across multiple backups. The 2 MB blocks (`.blk` files) are compressed. Because check sums are used to address the 2MB blocks, we achieve some degree of deduplication for the 2 MB blocks in the same volume.

{{< figure src="/img/diagrams/architecture/snapshot-backups.png" >}}

## CSI Plugin

Longhorn is managed in Kubernetes via a [CSI Plugin](https://kubernetes-csi.github.io/docs/).  This allows for easy installation of the Longhorn plugin.

Longhorn does leverage iSCSI, so extra configuration of the node may be required.  This may include the installation of `open-iscsi` or `iscsiadm`. Depending on the distribution.

## Kubernetes CSI Driver Images

* CSI Attacher:  `quay.io/k8scsi/csi-attacher:v2.0.0`
* CSI Provisioner:  `quay.io/k8scsi/csi-provisioner:v1.4.0`
* CSI Node Driver Registrar:  `quay.io/k8scsi/csi-node-driver-registrar:v1.2.0`
* CSI Resizer:  `quay.io/k8scsi/csi-resizer:v0.3.0`
