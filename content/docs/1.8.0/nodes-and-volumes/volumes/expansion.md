---
title: Volume Expansion
weight: 6
---

Volumes are expanded in two stages. First, Longhorn resizes the block device, then it expands the filesystem.

Since v1.4.0, Longhorn supports online expansion. Most of the time Longhorn can directly expand an attached volumes without limitations, no matter if the volume is being R/W or rebuilding.

If the volume was not expanded though the CSI interface (e.g. for Kubernetes older than v1.16), the capacity of the corresponding PVC and PV won't change.

## Prerequisite

- For offline expansion, the Longhorn version must be v0.8.0 or higher.
- For online expansion, the Longhorn version must be v1.4.0 or higher.

## Expand a Longhorn volume

There are two ways to expand a Longhorn volume: with a PersistentVolumeClaim (PVC) and with the Longhorn UI.

#### Via PVC

This method is applied only if:

- The PVC is dynamically provisioned by the Kubernetes with Longhorn StorageClass.
- The field `allowVolumeExpansion` should be `true` in the related StorageClass.

This method is recommended if it's applicable, because the PVC and PV will be updated automatically and everything is kept consistent after expansion.

Usage: Find the corresponding PVC for Longhorn volume, then modify the requested `spec.resources.requests.storage` of the PVC:

```
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  annotations:
    kubectl.kubernetes.io/last-applied-configuration: |
      {"apiVersion":"v1","kind":"PersistentVolumeClaim","metadata":{"annotations":{},"name":"longhorn-simple-pvc","namespace":"default"},"spec":{"accessModes":["ReadWriteOnce"],"resources":{"requests":{"storage":"1Gi"}},"storageClassName":"longhorn"}}
    pv.kubernetes.io/bind-completed: "yes"
    pv.kubernetes.io/bound-by-controller: "yes"
    volume.beta.kubernetes.io/storage-provisioner: driver.longhorn.io
  creationTimestamp: "2019-12-21T01:36:16Z"
  finalizers:
  - kubernetes.io/pvc-protection
  name: longhorn-simple-pvc
  namespace: default
  resourceVersion: "162431"
  selfLink: /api/v1/namespaces/default/persistentvolumeclaims/longhorn-simple-pvc
  uid: 0467ae73-22a5-4eba-803e-464cc0b9d975
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  storageClassName: longhorn
  volumeMode: Filesystem
  volumeName: pvc-0467ae73-22a5-4eba-803e-464cc0b9d975
status:
  accessModes:
  - ReadWriteOnce
  capacity:
    storage: 1Gi
  phase: Bound
```

#### Via Longhorn UI

Usage: On the volume page of Longhorn UI, click `Expand` for the volume.

## Filesystem expansion

Longhorn will try to expand the file system only if:

- The expanded size should be greater than the current size.
- There is a Linux filesystem in the Longhorn volume.
- The filesystem used in the Longhorn volume is one of the following:
    - ext4
    - xfs
- The expanded size must be less than the maximum file size allowed by the file system (for example, 16TiB for `ext4`).
- The Longhorn volume is using the block device frontend.

## Corner cases

#### Handling Volume Revert

If a volume is reverted to a snapshot with smaller size, the frontend of the volume is still holding the expanded size. But the filesystem size will be the same as that of the reverted snapshot. In this case, you will need to handle the filesystem manually:

1. Attach the volume to a random node.
2. Log in to the corresponding node, and expand the filesystem.

    If the filesystem is `ext4`, the volume might need to be [mounted](https://linux.die.net/man/8/mount) and [umounted](https://linux.die.net/man/8/umount) once before resizing the filesystem manually. Otherwise, executing `resize2fs` might result in an error:

    ```
    resize2fs: Superblock checksum does not match superblock while trying to open ......
    Couldn't find valid filesystem superblock.
    ```

    Follow the steps below to resize the filesystem:

    ```
    mount /dev/longhorn/<volume name> <arbitrary mount directory>
    umount /dev/longhorn/<volume name>
    mount /dev/longhorn/<volume name> <arbitrary mount directory>
    resize2fs /dev/longhorn/<volume name>
    umount /dev/longhorn/<volume name>
    ```

3. If the filesystem is `xfs`, you can directly mount, then expand the filesystem.

    ```
    mount /dev/longhorn/<volume name> <arbitrary mount directory>
    xfs_growfs <the mount directory>
    umount /dev/longhorn/<volume name>
    ```

#### Encrypted volume

Due to [the upstream limitation](https://kubernetes.io/blog/2022/09/21/kubernetes-1-25-use-secrets-while-expanding-csi-volumes-on-node-alpha/), Longhorn cannot handle **online** expansion for encrypted volumes automatically unless you enable the feature gate `CSINodeExpandSecret`.

If you cannot enable it but still prefer to do online expansion, you can:
1. Login the node host the encrypted volume is attached to.
2. Execute `cryptsetup resize <volume name>`. The passphrase this command requires is the field `CRYPTO_KEY_VALUE` of the corresponding secret.
3. Expand the filesystem.

#### RWX volume

From v1.8.0, Longhorn supports fully automatic online expansion of the filesystem (NFS) for RWX volumes.  The feature requires the v1.8.0 versions of these components to be running:

- Longhorn-Manager
- CSI plugin
- Share Manager, which manages the NFS export

If you have upgraded from a previous version, the Share Manager pods (one for each RWX volume) are not upgraded automatically, to avoid disruption during the upgrade. 

After growing the block device, the CSI layer sends a resize command to the Share Manager to grow the filesystem within the block device.  With a down-rev share-manager, the command fails with an "unimplemented" error code and so no expansion happens.  To get the right image before the expansion, the simplest thing is to force a restart of the pod.  Identify the Share Manager pod of the RWX volume (typically named `share-manager-<volume name>`) and delete it:  

```shell
kubectl -n longhorn-system delete pod <the share manager pod>
```

The pod will automatically be recreated using the appropriate version, and the expansion completes.  Further expansions will not require any further intervention.

##### Offline

It's still possible to expand the RWX volume offline using these steps:

1. Detach the RWX volume by scaling down the workload to `replicas=0`. Ensure that the volume is fully detached.

1. After the scale command returns, run the following command and verify that the state is `detached`.
    ```shell
    kubectl -n longhorn-system get volume <volume-name>
    ```
1. Expand the block device using either the PVC or the Longhorn UI.

1. Scale up the workload.

The reattached volume will have the expanded size.  Furthermore, the Share Manager pod will be recreated with the current version.


