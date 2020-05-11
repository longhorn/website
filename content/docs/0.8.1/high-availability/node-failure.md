---
title: Handling Node Failures
weight: 2
---

This section is aimed to inform users of what happens during a node failure and what is expected during the recovery.

## Node Status During Failures

After **one minute**, `kubectl get nodes` will report `NotReady` for the failure node.

After about **five minutes**, the states of all the Pods on the `NotReady` node will change to either `Unknown` or `NodeLost`.

## Deletion of StatefulSet Pods

If you're deploying using a [StatefulSet](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/) or [Deployment,](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/) you'll need to decide is if it's safe to force deletion the Pod of the workload running on the lost node.

To allow Longhorn volumes to be released and reused after a node failure, you will have to force-delete the pods that Kubernetes automatically evicted from the lost node.

### Limitations of Automatic Pod Evictions

StatefulSets have a stable identity, so Kubernetes won't force-delete the Pod for you.

Deployments don't have a stable identity, but Longhorn is a Read-Write-Once type of storage, which means it can only be attached to one node. So the new Pod created by Kubernetes won't be able to start because the Longhorn volume is still attached to the old Pod, on the lost node.

In both cases, Kubernetes will automatically evict the Pod (set deletion timestamp for the Pod) on the lost node, then try to recreate a new Pod with the old volumes. However, the evicted Pod gets stuck in the `Terminating` state and the attached Longhorn volumes cannot be released or reused. The new Pod will get stuck in the `ContainerCreating` state. 

Therefore, you will need to decide if it is safe to force-delete the Pods. 

### Deleting Pods Manually

If you decide to delete the Pod manually (and forcefully), Kubernetes will take about another **six minutes** to delete the VolumeAttachment object associated with the Pod, then finally detach the Longhorn volume from the lost node and allow it to be used by the new Pod.

This six-minute period is [hard-coded in Kubernetes](https://github.com/kubernetes/kubernetes/blob/5e31799701123c50025567b8534e1a62dbc0e9f6/pkg/controller/volume/attachdetach/attach_detach_controller.go#L95): If the Pod on the lost node is force-deleted, the related volumes won't be unmounted correctly. Then Kubernetes will wait for this fixed timeout to directly clean up the VolumeAttachment object.

For more information about about forcing the deletion of a StatefulSet, see the [official Kubernetes documentation](https://kubernetes.io/docs/tasks/run-application/force-delete-stateful-set-pod/).

## What to Expect when Recovering a Failed Kubernetes Node

If the node is back online within 5 - 6 minutes of the failure, Kubernetes will restart the Pods. Then it will attempt to unmount and remount volumes without volume reattachment, and clean up VolumeAttachments.

Because the volume engines would be down after the node is down, this direct remount won’t work, since the device no longer exists on the node. In this case, Longhorn will detach and re-attach the volumes to recover the volume engines, so that the Pods can remount and reuse the volumes safely. 

If the node is not back online within 5-6 minutes of the failure, Kubernetes will try to delete all unreachable Pods based on the Pod eviction mechanism and these Pods will be in a `Terminating` state. See [Pod eviction timeout](https://kubernetes.io/docs/concepts/architecture/nodes/#condition) for details. 

Then if the failed node is recovered later, Kubernetes will restart those terminating Pods, detach the volumes, wait for the old VolumeAttachment cleanup, and reuse (reattach and remount) the volumes. Typically these steps may take 1 ~ 7 minutes.

In this case, detaching and reattaching operations are already included in the Kubernetes recovery procedures. Hence no extra operation is needed and the Longhorn volumes will be available after the above steps. 

For all above recovery scenarios, Longhorn will handle those steps automatically with the association of Kubernetes.