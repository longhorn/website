---
title: UBLK Frontend Support
weight: 20
aliases:
- /spdk/features/ublk-frontend-support.md
---

Starting with v1.9.0, Longhorn supports the UBLK frontend for v2 data engine volumes.
This feature exposes v2 data engine volumes as a block device by using [UBLK SPDK framework](https://spdk.io/doc/ublk.html).
In certain high-specification environments (for example, machines with fast SSDs capable of millions of IOPS and 32 CPU cores), the UBLK frontend may offer better performance compared to the default NVMe-oF frontend for v2 data engine volumes.
See the reference [Longhorn-Performance-Investigation](https://github.com/longhorn/longhorn/wiki/Longhorn-Performance-Investigation).
However, the UBLK frontend is less mature than the default NVMe-oF frontend (see the known limitations below).
UBLK frontend also has more restriction as mentioned below.

## Prerequisites

1. The kernel version on nodes must be v6.0 or above. The UBLK kernel driver is only available starting from kernel v6.0.
2. The kernel module `ublk_drv` must be loaded on each node where UBLK volumes are attached. You can load it manually on each volume for testing using: `modprobe ublk_drv`

## How to use

### When creating the v2 volume from UI
Select `UBLK` as the volume frontend during volume creation.

### When creating the v2 volume from manifest
1. Create a StorageClass specifies UBLK frontend. For example:
    ```yaml
    kind: StorageClass
    apiVersion: storage.k8s.io/v1
    metadata:
      name: my-ublk-frontend-storageclass
    provisioner: driver.longhorn.io
    allowVolumeExpansion: true
    reclaimPolicy: Delete
    volumeBindingMode: Immediate
    parameters:
      numberOfReplicas: "1"
      staleReplicaTimeout: "2880"
      fsType: "ext4"
      dataEngine: "v2"
      frontend: "ublk"
    ```
1. Create a PVC referencing that StorageClass. For example:
    ```yaml
    apiVersion: v1
    kind: PersistentVolumeClaim
    metadata:
      name: my-ublk-frontend-pvc
      namespace: default
    spec:
      accessModes:
        - ReadWriteOnce
      storageClassName: my-ublk-frontend-storageclass
      resources:
        requests:
          storage: 1Gi
    ```
2. Longhorn will automatically provision a v2 volume using the UBLK frontend based on the PVC and StorageClass definition

## Known Limitations

When an instance-manager pod crashes, it may leave orphaned UBLK devices on the node.
Currently, removing these orphan devices manually can be difficult and may sometimes require a node reboot.
We are investigating this issue further in [GitHub Issue #10738](https://github.com/longhorn/longhorn/issues/10738).


## Reference

Original GitHub issue for UBLK frontend support: [GitHub Issue #9456](https://github.com/longhorn/longhorn/issues/9456)
