---
title: V2 Volume Expansion
weight: 20
aliases:
- /spdk/features/volume-expansion.md
---

Starting with v1.10.0, Longhorn supports online expansion for v2 data engine volumes that use the NVMe frontend. This feature allows users to expand a volume to the requested size while keeping the workload running.

During the expansion process, Longhorn automatically resizes all replicas to match the user-requested size. This eliminates the need to stop or detach the application from the volume, ensuring a seamless and non-disruptive scaling of storage.

This capability significantly improves flexibility in storage management by enabling volumes to be scaled without any downtime.

## How to use

### When creating the v2 volume from UI

1. Select a volume with `Block Device` or `NVMf` as the frontend.
2. Navigate to the Volumes page in the Longhorn UI.
3. Click **Expand Volume** from the volume operations menu.
4. Enter the new desired size and confirm. The expansion will begin automatically.

### When creating the v2 volume from manifest

1. Create a StorageClass for the v2 data engine. Make sure `allowVolumeExpansion` is set to `true`. For example:
    ```yaml
    kind: StorageClass
    apiVersion: storage.k8s.io/v1
    metadata:
        name: longhorn-v2-data-engine
    provisioner: driver.longhorn.io
    allowVolumeExpansion: true
    reclaimPolicy: Delete
    volumeBindingMode: Immediate
    parameters:
      numberOfReplicas: "3"
      staleReplicaTimeout: "2880"
      fsType: "ext4"
      dataEngine: "v2"
    ```

2. Create a PersistentVolumeClaim (PVC) that references this StorageClass:
    ```yaml
    apiVersion: v1
    kind: PersistentVolumeClaim
    metadata:
      name: longhorn-volv-pvc
      namespace: default
    spec:
      accessModes:
        - ReadWriteOnce
      storageClassName: longhorn-v2-data-engine
      resources:
        requests:
          storage: 2Gi
    ```

3. To expand the volume, edit the PVC manifest to increase the storage request to a larger size, then apply the updated manifest.
    ```yaml
      resources:
        requests:
          storage: 3Gi
    ```

## Known Limitations

The `UBLK` frontend is not supported for online expansion as of v1.10.0. Attempting to expand a volume using the UBLK frontend will not be allowed.

## Reference

For more information, see [[FEATURE] v2 supports volume expansion](https://github.com/longhorn/longhorn/issues/8022).