---
title: Node Failure Handling with Longhorn
weight: 2
---

## What to expect when a Kubernetes Node fails

This section is aimed to inform users of what happens during a node failure and what is expected during the recovery.

After **one minute**, `kubectl get nodes` will report `NotReady` for the failure node.

After about **five minutes**, the states of all the pods on the `NotReady` node will change to either `Unknown` or `NodeLost`.

StatefulSets have a stable identity, so Kubernetes won't force delete the pod for the user. See the [official Kubernetes documentation about forcing the deletion of a StatefulSet](https://kubernetes.io/docs/tasks/run-application/force-delete-stateful-set-pod/).

Deployments don't have a stable identity, but for the Read-Write-Once type of storage, since it cannot be attached to two nodes at the same time, the new pod created by Kubernetes won't be able to start due to the RWO volume still attached to the old pod, on the lost node.

In both cases, Kubernetes will automatically evict the pod (set deletion timestamp for the pod) on the lost node, then try to **recreate a new one with old volumes**. Because the evicted pod gets stuck in `Terminating` state and the attached volumes cannot be released/reused, the new pod will get stuck in `ContainerCreating` state, if there is no intervene from admin or storage software.

## Longhorn Pod Deletion Policy When Node is Down

Longhorn provides an option to help users automatically force delete terminating pods of StatefulSet/Deployment on the node that is down. After force deleting, Kubernetes will detach the Longhorn volume and spin up replacement pods on a new node.

You can find more detail about the setting options in the `Pod Deletion Policy When Node is Down` in the **Settings** tab in the Longhorn UI or [Settings reference](../../references/settings/#pod-deletion-policy-when-node-is-down)

### Volume Attachment recovery policy

If you decide to force delete the pod (either manually or with the help of Longhorn), Kubernetes will take about another **six minutes** to delete the VolumeAttachment object associated with the Pod, then finally detach the volume from the lost Node and allow it to be used by the new pod.

This six-minute period is [hard-coded in Kubernetes](https://github.com/kubernetes/kubernetes/blob/5e31799701123c50025567b8534e1a62dbc0e9f6/pkg/controller/volume/attachdetach/attach_detach_controller.go#L95): If the pod on the lost node is forced deleting, the related volumes won't be unmounted correctly. Then Kubernetes will wait for this fixed timeout to directly clean up the VolumeAttachment object.

To deal with this problem we provide 3 different Volume Attachment recovery policies.

##### Volume Attachment recovery policy `never` *(Kubernetes default)*
Longhorn will not recover the Volume Attachment from a failed node, which is consistent with the default Kubernetes behavior.
The user needs to force delete the terminating pods, at which point Longhorn will recover the Volume Attachment from the failed node.
Which then allows the pending replacement pods to start correctly with the requested volumes being available.

##### Volume Attachment recovery policy `wait` *(Longhorn default)*
Longhorn will wait to recover the Volume Attachment till all the terminating pods deletion grace period has passed.
Since the nodes `kubelet` is required to delete the pods by this point, and the pods are still available we can conclude that the failed nodes `Kubelet` is incapable of deleting the pods.
At this point Longhorn will recover the Volume Attachment from the failed node.
Which then allows the pending replacement pods to start correctly with the requested volumes being available.

##### Volume Attachment recovery policy `immediate`
Longhorn will recover the Volume Attachment from a failed node as soon as there are pending replacement pods available.
Which then allows the pending replacement pods to start correctly with the requested volumes being available.

## What to expect when a failed Kubernetes Node recovers

If the node is back online within 5 - 6 minutes of the failure, Kubernetes will restart pods, unmount, and re-mount volumes without volume re-attaching and VolumeAttachment cleanup.

Because the volume engines would be down after the node is down, this direct remount won’t work since the device no longer exists on the node.

In this case, Longhorn will detach and re-attach the volumes to recover the volume engines, so that the pods can remount/reuse the volumes safely.

If the node is not back online within 5 - 6 minutes of the failure, Kubernetes will try to delete all unreachable pods based on the pod eviction mechanism and these pods will be in a `Terminating` state. See [pod eviction timeout](https://kubernetes.io/docs/concepts/architecture/nodes/#condition) for details.

Then if the failed node is recovered later, Kubernetes will restart those terminating pods, detach the volumes, wait for the old VolumeAttachment cleanup, and reuse(re-attach & re-mount) the volumes. Typically these steps may take 1 ~ 7 minutes.

In this case, detaching and re-attaching operations are already included in the Kubernetes recovery procedures. Hence no extra operation is needed and the Longhorn volumes will be available after the above steps.

For all above recovery scenarios, Longhorn will handle those steps automatically with the association of Kubernetes.
