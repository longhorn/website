---
title: Welcome Longhorn 1.2
author: David Ko
draft: false
date: 2021-10-11
categories:
  - "announcement"
---

# Welcome Longhorn 1.2

Hi community users!

After ten months, I am so glad and excited to announce Longhorn 1.2 was released! Actually, the latest patch version is 1.2.2 which fixes some important fixes to ensure 1.2 getting better and stable.

What's actually new in 1.2? In this post, I would like to declare the major theme of Longhorn 1.2, then explore a bit the major features introduced in 1.2 to get more understanding.

Before 1.2, Longhorn mainly focus on providing different data access ways via volume (RWO/RWX), CSI compatible volume functions (snapshot/restore), data services (longhorn snapshot, replication, backup/restore, DR volume), automatic easy operations (live upgrade longhorn engine of volume, node maintenance support, managed workload recovering) and system monitoring (control plane like manager/instance manager, volume/node/disk), and it actually establishes a stable fundament for Longhorn actively adopted by the community users.

# What's new in Longhorn 1.2

For 1.2, besides continuing stabilizing the existing features in above-mentioned important areas, Longhorn extends its capabilities to the following new domains.

- Volume cloning
- Enhanced backing images management for virtual machine volume support
- Backing image from volume
- Encryption: volume and backup
- Automatic replica rebalancing based on soft Node/Zone anti-affinity
- Asynchronous backup operations
- New Recurring job and groups
- Low-performance environment support for Longhorn data plane

In addition, as you probably know, after Kubernetes 1.22 was introduced, Longhorn 1.1 is unable to support due to the [storage.k8s.io/v1beta1](http://storage.k8s.io/v1beta1) API version of CSIDriver, CSINode, StorageClass, and VolumeAttachment no longer served as of v1.22. This is already resolved in Longhorn 1.2 and we also update the minimum supported version of Kubernetes to v1.18 and bump the version of CSI components.

## Volume cloning

Finally, you can clone a volume from a source volume via CSI volume cloning. Just create a new PVC as the below example to copy the volume data from a source volume with the correct resources requests information.

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: cloned-pvc
spec:
  storageClassName: longhorn
  dataSource:
    name: source-pvc
    kind: PersistentVolumeClaim
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
```

## Enhanced backing images management for virtual machine volume support

The virtual machine volume support was introduced from Longhorn 1.1.1 with the below functions already.

- Virtual machine volume creation by backing image
- Backing image management support without any 3rd-party image repository
- Virtual machine live migration support by Longhorn migratable RWO volume
- Ability to use as a volume storage service by virtualization orchestration solutions like [Harvester](https://harvesterhci.io/)

In Longhorn 1.2, you can upload backing images from Longhorn UI instead of only downloading from external links, also the integrity check is added to secure the uploaded/downloaded images correct.

## Backing image from volume

Besides adding backing images from external via download/upload, users are able to create images from volumes. Actually, the implementation behind is based on the volume cloning mechanism.

![Untitled](/img/blogs/longhorn-v1.2/create-backing-img-from-volume.png)

## Encryption: volume and backup

Longhorn supports encrypted volumes by utilizing a Linux kernel-based disk encryption solution (LUKS, Linux Unified Key Setup), so please make sure **dm_crypt** module is loaded and **cryptsetup** installed on your worker nodes.

Longhorn uses the Kubernetes secret mechanism for key storage for now, but it could be imaged to extend for different key management as per the community requests in the future. Also, you need to specify the secret as part of the parameters of a storage class. This mechanism is provided by Kubernetes and allows the usage of some template parameters that will be resolved as part of volume creation.

An encrypted volume results in your data being encrypted while in transit as well as at rest, this also means that any backups taken from that volume are also encrypted.

1. Create a secret for encrypting/decrypting volumes

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: longhorn-crypto
  namespace: longhorn-system
stringData:
  CRYPTO_KEY_VALUE: "Your encryption passphrase"
  CRYPTO_KEY_PROVIDER: "secret"
```

2. Create a storage class w/ the secret global for all volumes

```yaml
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: longhorn-crypto-global
provisioner: driver.longhorn.io
allowVolumeExpansion: true
parameters:
  numberOfReplicas: "3"
  staleReplicaTimeout: "2880" # 48 hours in minutes
  fromBackup: ""
  encrypted: "true"
  # global secret that contains the encryption key that will be used for all volumes
  csi.storage.k8s.io/provisioner-secret-name: "longhorn-crypto"
  csi.storage.k8s.io/provisioner-secret-namespace: "longhorn-system"
  csi.storage.k8s.io/node-publish-secret-name: "longhorn-crypto"
  csi.storage.k8s.io/node-publish-secret-namespace: "longhorn-system"
  csi.storage.k8s.io/node-stage-secret-name: "longhorn-crypto"
  csi.storage.k8s.io/node-stage-secret-namespace: "longhorn-system"
```

or a key for an individual volume, not globally

```yaml
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: longhorn-crypto-per-volume
provisioner: driver.longhorn.io
allowVolumeExpansion: true
parameters:
  numberOfReplicas: "3"
  staleReplicaTimeout: "2880" # 48 hours in minutes
  fromBackup: ""
  encrypted: "true"
  # per volume secret which utilizes the `pvc.name` and `pvc.namespace` template parameters
  csi.storage.k8s.io/provisioner-secret-name: ${pvc.name}
  csi.storage.k8s.io/provisioner-secret-namespace: ${pvc.namespace}
  csi.storage.k8s.io/node-publish-secret-name: ${pvc.name}
  csi.storage.k8s.io/node-publish-secret-namespace: ${pvc.namespace}
  csi.storage.k8s.io/node-stage-secret-name: ${pvc.name}
  csi.storage.k8s.io/node-stage-secret-namespace: ${pvc.namespace}
```

For the detailed explanation, please go check [here](https://longhorn.io/docs/1.2.2/advanced-resources/volume-encryption/).

## Automatic replica rebalancing based on soft Node/Zone anti-affinity

Longhorn supports automatically replica rebalancing when node status changes (on/off) based on node/zone soft anti-affinity. When replicas are scheduled unevenly on nodes or zones, the **Longhorn Replica Auto Balance** setting enables the replicas for automatic balancing when a new node is available to the cluster.

3 options are supported globally or per volume:

- **disabled**
  - This is the default option, no replica auto-balance will be done.
- **least-effort**
  - This option instructs Longhorn to balance replicas for minimal redundancy. For example, after adding node-2, a volume with 4 off-balanced replicas will only rebalance 1 replica.
- **best-effort**
  - This option instructs Longhorn to try balancing replicas for even redundancy. For example, after adding node-2, a volume with 4 off-balanced replicas will rebalance 2 replicas.

## Asynchronous backup operations

Longhorn supports asynchronous backup operations by introducing backup target, backup volume, and backup custom resources and controllers to improve the performance issues of backup operations in previous versions. Besides improving the performance of backup retrieving latency, this is also the phased step to move all operations based on de-facto custom resource pattern instead of self-designed API interfaces or protocols and there will be more changes in the future like snapshot.

## New Recurring job and groups

Longhorn supports the concept of recurring jobs and groups by introducing the recurring job custom resource and controller. Users can create/reuse recurring jobs and organize their jobs in groups to apply to volumes. There is a migration for you when upgrading from the previous Longhorn versions. The same as above backup custom resources introduced, this is also a custom resource-based design different from the previous arbitrary recurring jobs setting in the storage class or not shareable volume-based setting.

1. Create a recurring job w/ groups

```yaml
apiVersion: longhorn.io/v1beta1
kind: RecurringJob
metadata:
  name: snapshot-1
  namespace: longhorn-system
spec:
  cron: "* * * * *"
  task: "snapshot"
  groups:
  - default
  - group1
  retain: 1
  concurrency: 2
  labels:
    label/1: a
    label/2: b
```

2. Add a default recurring job or group to volumes by labels

> Longhorn will automatically add the volume to the default group when the volume has no recurring job
>

```bash
kubectl -n longhorn-system label volume/pvc-8b9cd514-4572-4eb2-836a-ed311e804d2f recurring-job-group.longhorn.io/default=enabled
```

```bash
kubectl -n longhorn-system label volume/pvc-8b9cd514-4572-4eb2-836a-ed311e804d2f recurring-job.longhorn.io/backup1=enabled
```

or by a storage class.

```bash
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: longhorn
provisioner: driver.longhorn.io
parameters:
  numberOfReplicas: "3"
  staleReplicaTimeout: "30"
  fromBackup: ""
  recurringJobSelector: '[
    {
      "name":"snap",
      "isGroup":true,
    },
    {
      "name":"backup",
      "isGroup":false,
    }
  ]'
```

For the detailed, please check [here](https://longhorn.io/docs/1.2.2/snapshots-and-backups/scheduling-backups-and-snapshots/).

## Low performance environment support for Longhorn data plane

Enhance Longhorn data plane on low-performance environment to better support based on different resource factors. In 1.2, the improvement especially focuses on the possible timeout happening in the data path between the Longhorn engine and replicas when using slow disks.

To avoid Longhorn engine (tgt frontend) possibly overwhelming the replicas running on slow disks via managing thread pools in the engine for reactive traffic trotting. Also, the timeout will actually occur when no response to any of the pending read or write operations from replicas instead of just a hard-limited timeout to avoid timeout happen in slow devices.

# Try & feedback!

There are still lots of things in 1.2 not just above, and I would sincerely suggest you walk through the release note! I know it's quite an exciting moment for Longhorn 1.2 and the community, and sorry for keeping you wait for a while for this new feature release.

Please go ahead try and feedback, find the upgrade instructions [here](https://longhorn.io/docs/1.2.2/deploy/upgrade/). Any feedback from the community users will help Longhorn keep improving and enhancing to develop into a solid storage solution in the cloud-native world.

Enjoy the release!
