---
  title: Recover Volume after Unexpected Detachment
  weight: 1
---

When an unexpected detachment happens, which can happen during a [Kubernetes upgrade](https://github.com/longhorn/longhorn/issues/703), a [Docker reboot](https://github.com/longhorn/longhorn/issues/686), or a network disconnection,
Longhorn automatically deletes the workload pod if the pod is managed by a controller (e.g. deployment, statefulset, daemonset, etc...).
By deleting the pod, its controller restarts the pod and Kubernetes handles volume reattachment and remount.

If you don't want Longhorn to automatically delete the workload pod, you can set it in the setting `Automatically Delete Workload Pod when The Volume Is Detached Unexpectedly` in Longhorn UI.

For the pods that don't have a controller, Longhorn doesn't delete them because if Longhorn does, no one will restart them.
To recover unexpectedly detached volumes, you would have to manually delete and recreate the pods that don't have a controller.
