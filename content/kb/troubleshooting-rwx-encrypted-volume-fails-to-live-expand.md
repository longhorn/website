---
title: "Troubleshooting: Encrypted RWX Volume Fails to Perform Live Expansion"
authors:
- "Raphanus Lo"
draft: false
date: 2025-07-01
versions:
- "v1.8.0 to v1.8.1"
- "v1.9.0"
categories:
- "RWX volume"
- "Encrypted volume"
---

## Applicable versions

- v1.8.0 to v1.8.2
- v1.9.0

## Symptoms

An **encrypted RWX volume** created from a PVC and mounted to a workload shows successful expansion in the UI. However, the actual volume inside the workload remains at the original (unexpanded) size.

The corresponding PVC is stuck in the `FileSystemResizePending` phase, with an outdated capacity:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
...
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: "73400320"
  storageClassName: longhorn-crypto-global
  volumeMode: Filesystem
  volumeName: pvc-a01aa079-b05d-40ea-a556-5ba691f9191e
status:
  accessModes:
    - ReadWriteMany
  capacity:
    storage: 50Mi
  conditions:
    - lastProbeTime: null
      lastTransitionTime: "2025-07-01T09:16:05Z"
      message: Waiting for user to (re-)start a pod to finish file system resize of
        volume on node.
      status: "True"
      type: FileSystemResizePending
  phase: Bound
```

Meanwhile, the corresponding Longhorn share manager logs repeatedly show errors like:

```
time="2025-07-01T09:29:42Z" level=error msg="Failed to resize mounted filesystem on volume" error="rpc error: code = InvalidArgument desc = unsupported disk encryption format ext4" filesystem=/export/pvc-a01aa079-b05d-40ea-a556-5ba691f9191e volume=pvc-a01aa079-b05d-40ea-a556-5ba691f9191e
time="2025-07-01T09:31:24Z" level=info msg="Resizing mounted volume" filesystem=/export/pvc-a01aa079-b05d-40ea-a556-5ba691f9191e volume=pvc-a01aa079-b05d-40ea-a556-5ba691f9191e
time="2025-07-01T09:31:24Z" level=info msg="Device /dev/mapper/pvc-a01aa079-b05d-40ea-a556-5ba691f9191e contains filesystem of format ext4" filesystem=/export/pvc-a01aa079-b05d-40ea-a556-5ba691f9191e volume=pvc-a01aa079-b05d-40ea-a556-5ba691f9191e
time="2025-07-01T09:31:24Z" level=error msg="Failed to resize mounted filesystem on volume" error="rpc error: code = InvalidArgument desc = unsupported disk encryption format ext4" filesystem=/export/pvc-a01aa079-b05d-40ea-a556-5ba691f9191e volume=pvc-a01aa079-b05d-40ea-a556-5ba691f9191e
time="2025-07-01T09:31:44Z" level=info msg="Resizing mounted volume" filesystem=/export/pvc-a01aa079-b05d-40ea-a556-5ba691f9191e volume=pvc-a01aa079-b05d-40ea-a556-5ba691f9191e
time="2025-07-01T09:31:44Z" level=info msg="Device /dev/mapper/pvc-a01aa079-b05d-40ea-a556-5ba691f9191e contains filesystem of format ext4" filesystem=/export/pvc-a01aa079-b05d-40ea-a556-5ba691f9191e volume=pvc-a01aa079-b05d-40ea-a556-5ba691f9191e
```

## Root Cause

During live volume expansion in Kubernetes, the CSI plugin's node server instructs the Longhorn share manager to resize the volume. The share manager checks whether the underlying device is LUKS-encrypted before resizing.

Theoretically, after the original device is expanded, Longhorn should check the disk format of the original device and get the result `crypto_LUKS`. However, it wrongly fetches that of the encrypted/mapped device with the result `ext4`. Then Longhorn can not continue resizing the encrypted device correctly. In the other hand, since the original device is expanded, the expansion appears complete in the UI.

## Mitigation

1. Upgrade to Longhorn v1.8.2, v1.9.1, v1.10.0, or newer.
2. Upgrade the share manager. There are two options to take effective on existing RWX volumes:
    - Option A: Scale down all workloads using the problematic volume. After the volume is detached, scale the workload back.
    - Option B: Non-disruptive mitigation, but introduce some I/O latency during the upgrade. Edit the share manager CR to update the image:
         ```
         kubectl -n longhorn-system edit sharemanager <volume_name>
         ```
         In the spec, update:
         ```
         apiVersion: longhorn.io/v1beta2
         kind: ShareManager
         ...
         spec:
           image: longhornio/longhorn-share-manager:v1.10.0
         ...
         ```
         Then, edit the Share Manager to update the image:
         ```
         kubectl -n longhorn-system edit pod share-manager-<volume_name>`
         ```
         In the spec, update:
         ```
         apiVersion: v1
         kind: Pod
         ...
         spec:
           containers:
           - image: longhornio/longhorn-share-manager:v1.10.0
         ...
         ```
         The volume I/O in the workload will be stuck for a while as the share manager pod restarts.

## Related information

- [Longhorn Issue #11149](https://github.com/longhorn/longhorn/issues/11120): Original issue documenting this failure.
