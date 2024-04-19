---
  title: Volume Recovery
  weight: 1
---

Longhorn provides two mechanisms for maintaining volume functionality in a variety of situations.

## Automatic Workload Pod Deletion

This recovery mechanism is enabled by the setting [*Automatically Delete Workload Pod when The Volume Is Detached Unexpectedly*](../../references/settings#automatically-delete-workload-pod-when-the-volume-is-detached-unexpectedly).

When one of the following situations occurs, Longhorn automatically attempts to delete workload pods that are managed by a controller (for example, Deployment, StatefulSet, or DaemonSet). After deletion, the controller restarts the workload pod and Kubernetes handles volume reattachment and remounting.

1. A volume was unexpectedly detached, possibly because of a [Kubernetes upgrade](https://github.com/longhorn/longhorn/issues/703), [container runtime reboot](https://github.com/longhorn/longhorn/issues/686), network connectivity issue, or volume engine crash.
2. A volume was automatically salvaged after all replicas became faulty, possibly because of a network connectivity issue. Longhorn attempts to identify the usable replicas and uses them for the volume.
3. An error occurred on a Share Manager pod that uses an RWX volume.

If you want to prevent Longhorn from automatically deleting workload pods, disable the setting [*Automatically Delete Workload Pod when The Volume Is Detached Unexpectedly*](../../references/settings#automatically-delete-workload-pod-when-the-volume-is-detached-unexpectedly) on the Longhorn UI.

Longhorn does not delete pods without a controller because such pods cannot be restarted after deletion. To recover volumes that are unexpectedly detached, you must manually delete and restart the pods without a controller.

## Automatic Volume Remounting

This recovery mechanism is not controlled by any specific setting.

The state of a volume can change to read-only when IO errors occur. IO errors can be caused by a variety of issues, including the following:
- Network disconnection: Interrupted connection between the engine and replicas.
- High disk latency: Significant delay in the transfer of data between a replica and the corresponding disk.

Longhorn checks the state of the volume's global mount point every 10 seconds. When the volume's filesystem changes to read-only, Longhorn updates the condition to the volume's data engine. Longhorn then automatically attempts to remount the global mount point on the host to change the state back to read-write. Upon successful remounting, the workload pods continue functioning without disruption.

> **Note:**
> This mechanism might not work in some situations. For example, when the volume's data engine crashes, Longhorn automatically detaches and reattaches the volume. The filesystem changes to read-only in this case. Longhorn will detect the read-only mode and update the state, but [Automatic Volume Remounting](#automatic-volume-remounting) cannot change it back to read-write because the device is now write-protected. In this case, you can only rely on the [Automatic Workload Pod Deletion](#automatic-workload-pod-deletion) mechanism, which enables volume remounting after the workload pod is recreated.


## Summary

[Automatic Workload Pod Deletion](#automatic-workload-pod-deletion) is triggered when unexpected failures happen. The controller deletes and then restarts the workload pod, and Kubernetes handles volume reattachment and remounting. The process may cause interruptions to the workload. If you want to prevent Longhorn from automatically deleting workload pods, disable the setting [*Automatically Delete Workload Pod when The Volume Is Detached Unexpectedly*](../../references/settings#automatically-delete-workload-pod-when-the-volume-is-detached-unexpectedly) on the Longhorn UI.

[Automatic Volume Remounting](#automatic-volume-remounting) is triggered when the volume's filesystem changes to read-only. Longhorn remounts the global mount point on the host to change the state back to read-write.