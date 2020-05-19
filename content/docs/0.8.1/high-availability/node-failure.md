---
title: Node Failure Handling with Longhorn
weight: 2
---

## What to expect when a Kubernetes Node fails

This section is aimed to inform users of what happens during a node failure and what is expected during the recovery.

After **one minute**, `kubectl get nodes` will report `NotReady` for the failure node.

After about **five minutes**, the states of all the pods on the `NotReady` node will change to either `Unknown` or `NodeLost`.

If you're deploying using a [StatefulSet](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/) or [Deployment,](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/) you need to decide is if it's safe to force deletion the pod of the workload running on the lost node. See the [official Kubernetes documentation about forcing the deletion of a StatefulSet](https://kubernetes.io/docs/tasks/run-application/force-delete-stateful-set-pod/).

StatefulSets have a stable identity, so Kubernetes won't force delete the pod for the user.

Deployments don't have a stable identity, but Longhorn is a Read-Write-Once type of storage, which means it can only be attached to one node. So the new pod created by Kubernetes won't be able to start due to the Longhorn volume still attached to the old pod, on the lost node.

In both cases, Kubernetes will automatically evict the pod (set deletion timestamp for the pod) on the lost node, then try to **recreate a new one with old volumes**. Because the evicted pod gets stuck in `Terminating` state and the attached Longhorn volumes cannot be released/reused, the new pod will get stuck in `ContainerCreating` state. That's why you'll need to decide is if it's safe to force deleting the pod.

If you decide to delete the pod manually (and forcefully), Kubernetes will take about another **six minutes** to delete the VolumeAttachment object associated with the Pod, then finally detach the Longhorn volume from the lost Node and allow it to be used by the new pod.

This six-minute period is [hard-coded in Kubernetes](https://github.com/kubernetes/kubernetes/blob/5e31799701123c50025567b8534e1a62dbc0e9f6/pkg/controller/volume/attachdetach/attach_detach_controller.go#L95): If the pod on the lost node is forced deleting, the related volumes won't be unmounted correctly. Then Kubernetes will wait for this fixed timeout to directly clean up the VolumeAttachment object.

## What to expect when recovering a failed Kubernetes Node

If the node is back online within 5 - 6 minutes of the failure, Kubernetes will restart pods, unmount, and re-mount volumes without volume re-attaching and VolumeAttachment cleanup.

Because the volume engines would be down after the node is down, this direct remount won’t work since the device no longer exists on the node. 

In this case, Longhorn will detach and re-attach the volumes to recover the volume engines, so that the pods can remount/reuse the volumes safely. 

If the node is not back online within 5 - 6 minutes of the failure, Kubernetes will try to delete all unreachable pods based on the pod eviction mechanism and these pods will be in a `Terminating` state. See [pod eviction timeout](https://kubernetes.io/docs/concepts/architecture/nodes/#condition) for details. 

Then if the failed node is recovered later, Kubernetes will restart those terminating pods, detach the volumes, wait for the old VolumeAttachment cleanup, and reuse(re-attach & re-mount) the volumes. Typically these steps may take 1 ~ 7 minutes.

In this case, detaching and re-attaching operations are already included in the Kubernetes recovery procedures. Hence no extra operation is needed and the Longhorn volumes will be available after the above steps. 

For all above recovery scenarios, Longhorn will handle those steps automatically with the association of Kubernetes.