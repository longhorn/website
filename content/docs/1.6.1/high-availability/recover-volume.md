---
  title: Recover Volume
  weight: 1
---

This section is aimed to inform users of what might leads to volume failure and how Longhorn recover the volume.

- [Automatically deletes the workload pod](#automatically-deletes-the-workload-pod)
- [Automatically remount the volume](#automatically-remount-the-volume)
- [Conclusion](#conclusion)

## Automatically deletes the workload pod

This recovery mechanism is enabled by the setting [*Automatically Delete Workload Pod when The Volume Is Detached Unexpectedly*](../../references/settings#automatically-delete-workload-pod-when-the-volume-is-detached-unexpectedly).

When one of the following situations occurs, Longhorn automatically attempts to delete workload pods that are managed by a controller (for example, Deployment, StatefulSet, or DaemonSet). After deletion, the controller restarts the workload pod and Kubernetes handles volume reattachment and remounting.

1. A volume was unexpectedly detached, possibly because of a [Kubernetes upgrade](https://github.com/longhorn/longhorn/issues/703), [container runtime reboot](https://github.com/longhorn/longhorn/issues/686), network connectivity issue, or volume engine crash.
2. A volume was automatically salvaged after all replicas became faulty, possibly because of a network connectivity issue. Longhorn attempts to identify the usable replicas and uses them for the volume.
3. An error occurred on a Share Manager pod that uses an RWX volume.

If you want to prevent Longhorn from automatically deleting workload pods, disable the setting [*Automatically Delete Workload Pod when The Volume Is Detached Unexpectedly*](../../references/settings#automatically-delete-workload-pod-when-the-volume-is-detached-unexpectedly) on the Longhorn UI.

Longhorn does not delete pods without a controller because such pods cannot be restarted after deletion. To recover volumes that are unexpectedly detached, you must manually delete and restart the pods without a controller.

## Automatically remount the volume

This recovery mechanism does not have setting to control it.

The state of a volume can change to read-only when IO errors occur. IO errors can be caused by a variety of issues, including the following:
- Network disconnection: Interrupted connection between the engine and replicas.
- High disk latency: Significant delay in the transfer of data between a replica and the corresponding disk.

Longhorn checks the volume global mount point state every 10 sec. When the filesystem of the volume changes to read-only, Longhorn updates the condition to the engine of the volume for users to check. Longhorn then automatically attempts to remount the global mount point on the host to change the state back to read-write. Upon successful remounting, the workload pods continue functioning without disruption.

Noted, this mechanism might not work for some cases. For example, when the engine of a volume crashes, Longhorn detaches and attaches the volume automatically. The filesystem will become read-only after reattaching and can not be remounted back to read-write. In this case, users still need to rely on [Automatically deletes the workload pod](#automatically-deletes-the-workload-pod) to request Kubernetes to remount the volume by recreating the pod.


## Conclusion

These two mechanisms co-exists in Longhorn to handle different situations and maintain volume functionality. 

[Automatically deletes the workload pod](#automatically-deletes-the-workload-pod) is triggered when unexpected failures happen. By deleting the workload pod, the controller restarts the workload pod and Kubernetes handles volume reattachment and remounting. This introduce some interruption to the workload. One can disable the function by disabling the setting 
[*Automatically Delete Workload Pod when The Volume Is Detached Unexpectedly*](../../references/settings#automatically-delete-workload-pod-when-the-volume-is-detached-unexpectedly) on the Longhorn UI.

[Automatically remount the volume](#automatically-remount-the-volume) is triggered when Longhorn finds the filesystem of the volume changes to read-only. Longhorn then remounts the global mount point on the host to change the state back to read-write.