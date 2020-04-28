---
title: Terminology
weight: 4
---

- [Backupstores](#backupstores)
- [CSI Driver](#csi-driver)
- [Volumes](#volumes)
- [Disaster Recovery Volumes](#disaster-recovery-volumes)
- [Snapshots](#snapshots)

### Backupstores

Backupstores in Longhorn are either NFS shares or an S3 compatible server. They are represented by Backup Targets in Longhorn.

### CSI Driver

If you're using [Kubernetes](https://kubernetes.io), you can use Longhorn to provide persistent storage using the Longhorn Container Storage Interface (CSI) driver.


### Volumes

Volumes in Longhorn are Kubernetes Volumes, they are created and managed as the Longhorn Volume Manager.

### Disaster Recovery Volumes

A disaster recovery volume is a volume that stores data in a backup cluster in case the whole main cluster goes down. Disaster recovery volumes are used to increase the resiliency of Longhorn volumes.

A disaster recovery volume can be created from a volume's backup in the backup store. And Longhorn will monitor its original backup volume and incrementally restore from the latest backup. Once the original volume in the main cluster goes down and users decide to activate the disaster recovery volume in the backup cluster, the disaster recovery volume can be activated immediately in the most condition, so it will greatly reduced the time needed to restore the data from the backup store to the volume in the backup cluster.

### Snapshots

A **snapshot** in Longhorn is the state of a volume at a given time that is stored in the same location as the volume data on the host's physical disk. Snapshots are created instantly in Longhorn.

Users can revert to any previous snapshot using the Longhorn UI. Since Longhorn is a distributed block storage system, make sure that the Longhorn volume is umounted from the host when reverting to any previous snapshot. Otherwise, Longhorn will confuse the node filesystem and cause filesystem corruption.