---
title: Longhorn PVC Ownership and Permission
weight: 1
---

Kubernetes supports the 2 [volume modes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#volume-mode) for PVC: Filesystem and Block.
When a pod defines the security context and requests a Longhorn PVC, Kubernetes will handle the ownership and permission modification for the PVC differently based on the volume mode.

### Longhorn PVC with Filesystem Volume Mode

Because the Longhorn CSI driver `csiDriver.spec.fsGroupPolicy` is set to `ReadWriteOnceWithFSType`, the Kubelet attempts to change the ownership and permission of a Longhorn PVC in the following manner:
1. Check `pod.spec.securityContext.fsGroup`.
   * If non-empty, continue to the next step.
   * If empty, the Kubelet doesn't attempt to change the ownership and permission for the volume.
1. Check `fsType` of the PV and `accessModes` of the PVC.
   * If the PV's `fsType` is defined and the PVC's `accessModes` list contains `ReadWriteOnly`, continue to the next step.
   * Otherwise, the Kubelet doesn't attempt to change the ownership and permission for the volume.
1. Check `pod.spec.securityContext.fsGroupChangePolicy`.
   * If the `pod.spec.securityContext.fsGroupChangePolicy` is set to `always` or empty, the kubelet performs the following actions:
     * Ensures that all processes of the containers inside the pod are part of the supplementary group id `pod.spec.securityContext.fsGroup`
     * Ensures that any new files created in the volume will be in group id `pod.spec.securityContext.fsGroup`
     * Recursively changes permission and ownership of the volume to have the same group id as `pod.spec.securityContext.fsGroup` every time the volume is mounted
   * If the `pod.spec.securityContext.fsGroupChangePolicy` is set to `OnRootMismatch`:
     * If the root of the volume already has the correct permissions (i.e., belongs to the group id as `pod.spec.securityContext.fsGroup`) , the recursive permission and ownership change will be skipped.
     * Otherwise, Kubelet recursively changes permission and ownership of the volume to have the same group id as `pod.spec.securityContext.fsGroup`

For more information, see:
* https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#configure-volume-permission-and-ownership-change-policy-for-pods
* https://github.com/longhorn/longhorn/issues/2131#issuecomment-778897129

### Longhorn PVC with Block Volume Mode

For PVC with Block volume mode, Kubelet never attempts to change the permission and ownership of the block device when making it available inside the container.
You must set the correct group ID in the `pod.spec.securityContext` for the pod to be able to read and write to the block device or run the container as root.

By default, Longhorn puts the block device into group id 6, which is typically associated with the "disk" group.
Therefore, pods that use Longhorn PVC with Block volume mode must either set the group id 6 in the `pod.spec.securityContext`, or run as root.
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
1. Pod that runs as root
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
