---
title: What is Longhorn?
weight: 1
---
Longhorn is a lightweight, reliable and easy-to-use distributed block storage system for Kubernetes.

Longhorn supports the following architectures:
1. AMD64
2. ARM64 (experimental)

Longhorn is free, open source software. Originally developed by Rancher Labs, it is now being developed as a sandbox project of the Cloud Native Computing Foundation.

With Longhorn, you can:

- Use Longhorn volumes as persistent storage for the distributed stateful applications in your Kubernetes cluster
- Partition your block storage into Longhorn volumes so that you can use Kubernetes volumes with or without a cloud provider
- Replicate block storage across multiple nodes and data centers to increase availability
- Store backup data in external storage such as NFS or AWS S3
- Create cross-cluster disaster recovery volumes so that data from a primary Kubernetes cluster can be quickly recovered from backup in a second Kubernetes cluster
- Schedule recurring snapshots of a volume, and schedule recurring backups to NFS or S3-compatible secondary storage
- Restore volumes from backup
- Upgrade Longhorn without disrupting persistent volumes

Longhorn comes with a standalone UI, and can be installed using Helm, kubectl, or the Rancher app catalog.

### Simplifying Distributed Block Storage with Microservices

Because modern cloud environments require tens of thousands to millions of distributed block storage volumes, some storage controllers have become highly complex distributed systems. By contrast, Longhorn can simplify the storage system by partitioning a large block storage controller into a number of smaller storage controllers, as long as those volumes can still be built from a common pool of disks. By using one storage controller per volume, Longhorn turns each volume into a microservice. The controller is called the Longhorn Engine.

The Longhorn Manager component orchestrates the Longhorn Engines, so they work together coherently.

### Use Persistent Storage in Kubernetes without Relying on a Cloud Provider

Pods can reference storage directly, but this is not recommended because it doesn't allow the Pod or container to be portable. Instead, the workloads' storage requirements should be defined in Kubernetes Persistent Volumes (PVs) and Persistent Volume Claims (PVCs). With Longhorn, you can specify the size of the volume, IOPS requirements, and the number of synchronous replicas you want across the hosts that supply the storage resource for the volume. Then your Kubernetes resources can use the PVC and corresponding PV for each Longhorn volume, or use a Longhorn storage class to automatically create a PV for a workload.

Replicas are thin-provisioned on the underlying disks or network storage.

### Schedule Multiple Replicas across Multiple Compute or Storage Hosts

To increase availability, Longhorn creates replicas of each volume. Replicas contain a chain of snapshots of the volume, with each snapshot storing the change from a previous snapshot. Each replica of a volume also runs in a container, so a volume with three replicas results in four containers. 

The number of replicas for each volume is configurable in Longhorn, as well as the nodes where replicas will be scheduled. Longhorn monitors the health of each replica and performs repairs, rebuilding the replica when necessary.

### Assign Multiple Storage Frontends for Each Volume

Common front-ends include a Linux kernel device (mapped under /dev/longhorn) and an iSCSI target.

### Specify Schedules for Recurring Snapshot and Backup Operations

Specify the frequency of these operations (hourly, daily, weekly, monthly, and yearly), the exact time at which these operations are performed (e.g., 3:00am every Sunday), and how many recurring snapshots and backup sets are kept.
