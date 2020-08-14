---
  title: Volume Expansion
  weight: 4
---

Volumes are expanded in two stages. First, Longhorn expands the frontend (the block device), then it expands the filesystem.

To prevent the frontend expansion from being interfered by unexpected data R/W, Longhorn supports offline expansion only.  The `detached` volume will be automatically attached to a random node with [maintenance mode.](../../concepts/#22-reverting-volumes-in-maintenance-mode)

Rebuilding and adding replicas is not allowed during the expansion, and expansion is not allowed while replicas are rebuilding or being added.

If the volume was not expanded though CSI interface (e.g. for Kubernetes older than v1.16), the capacity of corresponding PVC and PV won't change.

## Prerequisite:
1. Longhorn version v0.8.0 or higher.
2. The volume to be expanded is state `detached`.

## Expand a Longhorn volume
There are two ways to expand a Longhorn volume: with a PersistentVolumeClaim (PVC) and with the Longhorn UI.

If you are using Kubernetes v1.14 or v1.15, the volume can only be expanded using the Longhorn UI.

#### Via PVC
This method is applied only if:

1. Kubernetes version v1.16 or higher.
2. The PVC is dynamically provisioned by the Kubernetes with Longhorn StorageClass.
3. The field `allowVolumeExpansion` should be `true` in the related StorageClass.

This method is recommended if it's applicable. Since the PVC and PV will be updated automatically and everything keeps consistent after expansion.

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
If your Kubernetes version is v1.14 or v1.15, this method is the only choice for Longhorn volume expansion. 

Usage: On the volume page of Longhorn UI, click `Expand` for the volume.



## Filesystem expansion

Longhorn will try to expand the file system only if:

1. The expanded size should be greater than the current size.
2. There is a Linux filesystem in the Longhorn volume. 
3. The filesystem used in the Longhorn volume is one of the followings:
    1. ext4
    2. XFS
4. The Longhorn volume is using block device frontend. 

#### Handling Volume Revert
If users revert a volume to a snapshot with smaller size, the frontend of the volume is still holding the expanded size. But the filesystem size will be the same as that of the reverted snapshot. In this case, users need to handle the filesystem manually:

1. Attach the volume to a random nodes.
2. Log into the corresponding node, expand the filesystem.

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

3. If the filesystem is `xfs`, users can directly mount then expand the filesystem.

    ```
    mount /dev/longhorn/<volume name> <arbitrary mount directory>
    xfs_growfs <the mount directory>
    umount /dev/longhorn/<volume name>
    ```