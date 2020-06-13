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

Volumes in Longhorn are Kubernetes Volumes, they are created and managed as the Longhorn Manager.

### Disaster Recovery Volumes

A disaster recovery volume is a special volume that stores data in a backup cluster in case the whole main cluster goes down. Disaster recovery volumes are used to increase the resiliency of Longhorn volumes.

### Snapshots

A **snapshot** in Longhorn is the state of a volume at a given time that is stored in the same location as the volume data on the host's physical disk. Snapshots are created instantly in Longhorn.