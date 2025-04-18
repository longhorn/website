---
title: UBLK Frontend Support
weight: 20
aliases:
- /spdk/features/ublk-frontend-support.md
---

Starting with v1.9.0, Longhorn supports UBLK frontend for v2 data engine volume.
This feature exposes v2 data engine volume as a block device by using [UBLK SPDK framework](https://spdk.io/doc/ublk.html).
In a very high-spec environment (for example machine with fast SSD with million of IOPs capacity and 32 cores of CPU), the UBLK frontend might have better performance than the default NVMe-oF frontend of v2 data engine volume.
See reference [Longhorn-Performance-Investigation](https://github.com/longhorn/longhorn/wiki/Longhorn-Performance-Investigation).
However, UBLK frontend is less mature than the default NVMe-oF frontend (see the known limitations below).
UBLK frontend also has more restriction as mentioned below.


## Prerequisites

1. The nodes' kernel version must be >= v6.0. UBLK kernel driver is only available in kernel version > v6.0
2. Must load kernel module `ublk_drv` on each node. For example, manually load module on each node as `modprobe ublk_drv`

## How to use

### When creating the v2 volume from UI
Just select `UBLK` as the frontend

### When creating the v2 volume from manifest
1. Create a StorageClass specifies UBLK frontend. For example,
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
1. Create a PVC from the StorageClass. For example:
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
2. Longhorn will provision a v2 volume with UBLK frontend

## Known Limitations

When instance manager pod crashes, it might leave the orphan UBLK devices.
Currently, it is difficult to remove these orphan UBLK devices and sometimes a reboot is needed.
We are investigating this more at this ticket https://github.com/longhorn/longhorn/issues/10738


## Reference

Original GitHub ticket https://github.com/longhorn/longhorn/issues/9456
