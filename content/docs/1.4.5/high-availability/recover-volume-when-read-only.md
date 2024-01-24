---
title: Recover Volume When It Becomes Read Only
weight: 1
---

The state of a volume can change to read-only when IO errors occur. IO errors can be caused by a variety of issues, including the following:
- Network disconnection: Interrupted connection between the engine and replicas
- High disk latency: Significant delay in the transfer of data between a replica and the corresponding disk

Longhorn periodically checks the volume state and automatically deletes the workload pod if the pod is managed by a controller (for example, Deployment, StatefulSet, or DaemonSet) when the state changes to read-only. Once the workload pod is deleted, the controller restarts the pod and Kubernetes handles volume reattachment and remounting.

To prevent Longhorn from automatically deleting the workload pod, you can disable the setting on the Longhorn UI. For more information, see [Automatically Delete Workload Pod When the Volume Is Detached Unexpectedly](../../references/settings#automatically-delete-workload-pod-when-the-volume-is-detached-unexpectedly).

Longhorn does not delete pods without a controller because such pods cannot be restarted after deletion. To recover read-only volumes, you must manually delete and restart the pods that are not managed by a controller.
