---
title: Longhorn PVC ownership and permission
weight: 1
---

In Kubernetes, there are 2 types of volume modes for PVC: Filesystem and Block ([link](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#volume-mode)).
When a pod defines the security context and requests a Longhorn PVC, Kubernetes will handle the ownership and permission modification for the PVC differently for each type of volume mode.

### Longhorn PVC with Filesystem volume mode

Because Longhorn CSI driver `csiDriver.spec.fsGroupPolicy` sets to `ReadWriteOnceWithFSType`, Kubelet attempts to change the ownership and permission for Longhorn PVC in the following flow:
1. If `pod.spec.securityContext.fsGroup` is non-empty, continue to the next step.
   Otherwise, Kubelet doesn't attempt to change the ownership and permission for the volume.
1. If the PV's `fsType` is defined and the PVC's `accessModes` list contains `ReadWriteOnly`, continue to the next step.
   Otherwise, Kubelet doesn't attempt to change the ownership and permission for the volume.
1. If the `pod.spec.securityContext.fsGroupChangePolicy` is set to `always` or empty:
   1. Make sure that all processes of the containers inside the pod are part of the supplementary group id `pod.spec.securityContext.fsGroup`
   1. Any new files created in the volume will be in group id `pod.spec.securityContext.fsGroup`
   1. Kubelet recursively changes permission and ownership of the volume to have the same group id as `pod.spec.securityContext.fsGroup` everytime when the volume is mounted
1. If the `pod.spec.securityContext.fsGroupChangePolicy` is set to `OnRootMismatch`:
   1. If the root of the volume already has the correct permissions (i.e., belongs to the group id as `pod.spec.securityContext.fsGroup`) , the recursive permission and ownership change will be skipped.
   1. Otherwise, Kubelet recursively changes permission and ownership of the volume to have the same group id as `pod.spec.securityContext.fsGroup`

More references at:
* https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#configure-volume-permission-and-ownership-change-policy-for-pods
* https://github.com/longhorn/longhorn/issues/2131#issuecomment-778897129

### Longhorn PVC with Block volume mode

For PVC with Block volume mode, Kubelet never attempts to change the permission and ownership of the block device when making it available inside the container.
Users must set the correct group id in the `pod.spec.securityContext` for the pod to be able to read/write to the block device or run the container as root.

By default, Longhorn puts the block device into group id 6 (which is typically associated with the "disk" group by unwritten convention).
Therefore, pods that use Longhorn PVC in block volume mode must set the group id 6 in the `pod.spec.securityContext` or run as root.
For example:
1. Pod that sets the group id 6 in the `pod.spec.securityContext`
    ```yaml
    apiVersion: v1
    kind: PersistentVolumeClaim
    metadata:
      name: longhorn-block-vol
    spec:
      accessModes:
        - ReadWriteOnce
      volumeMode: Block
      storageClassName: longhorn
      resources:
        requests:
          storage: 2Gi
    ---
    apiVersion: v1
    kind: Pod
    metadata:
      name: block-volume-test
      namespace: default
    spec:
      securityContext:
        runAsGroup: 1000
        runAsNonRoot: true
        runAsUser: 1000
        supplementalGroups:
        - 6
      containers:
        - name: block-volume-test
          image: ubuntu:20.04
          command: ["sleep", "360000"]
          imagePullPolicy: IfNotPresent
          volumeDevices:
            - devicePath: /dev/longhorn/testblk
              name: block-vol
      volumes:
        - name: block-vol
          persistentVolumeClaim:
            claimName: longhorn-block-vol
    ```
1. Pod that run as root
    ```yaml
    apiVersion: v1
    kind: PersistentVolumeClaim
    metadata:
      name: longhorn-block-vol
    spec:
      accessModes:
        - ReadWriteOnce
      volumeMode: Block
      storageClassName: longhorn
      resources:
        requests:
          storage: 2Gi
    ---
    apiVersion: v1
    kind: Pod
    metadata:
      name: block-volume-test
      namespace: default
    spec:
      containers:
        - name: block-volume-test
          image: ubuntu:20.04
          command: ["sleep", "360000"]
          imagePullPolicy: IfNotPresent
          volumeDevices:
            - devicePath: /dev/longhorn/testblk
              name: block-vol
      volumes:
        - name: block-vol
          persistentVolumeClaim:
            claimName: longhorn-block-vol
    ```
