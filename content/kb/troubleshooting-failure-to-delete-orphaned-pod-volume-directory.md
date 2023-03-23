---
title: "Troubleshooting: Failure to delete orphaned Pod volume directory"
author: Ray Chang
draft: false
date: 2023-07-20
categories:
  - "csi"
---

## Applicable versions

All Longhorn versions.

Kubernetes versions before `v1.28`. A backported PR to `v1.27` is awaiting merging.

## Symptoms

In the event of a worker node failure, while hosting active Pods, the Pods are gracefully evicted as the node undergoes downtime and awaits restoration. During this period, the kubelet, which is responsible for managing the node, will generate the following error messages at regular intervals of two seconds.
```
orphaned pod <pod-uid> found, but error not a directory occurred when trying to remove the volumes dir
```

## Reason

This situation occurs when a node goes through a downtime state and then takes some time before entering the recovery phase. During this process, the affected Pods are evicted and relocated to other nodes. However, due to the disruption, the connection between the kubelet and the longhorn-csi-plugin is severed. Therefore, the kubelet encountered difficulties when deleting the `vol_data.json` file. This process is used to perform self-housekeeping tasks to clean up orphan volume mount points associated with evicted Pods. The kubelet, while capable of removing directories, cannot delete individual files, resulting in incomplete cleanup in this specific situation. [(source code)](https://github.com/kubernetes/kubernetes/blob/8c1dc65da905d0c8435659424169846ba2fb2d63/pkg/kubelet/kubelet_volumes.go#L155-L162).

## Solution

Once the node and kubelet have been restored, the longhorn-csi-plugin will automatically restart, allowing the Pod to remount the volume and resume its running state.

However, in cases where the Pod and its associated volume are rescheduled to a different node, leaving behind a lingering `vol_data.json` file on the crashed node, manual intervention is required. You will need to manually delete the `vol_data.json` file located within the `/var/lib/kubelet/pods/<pod-uid>/volumes/kubernetes.io~csi/pvc_<pod-uid>/` directory.

Within the present Kubernetes master branch, the issue is addressed in version `1.28.x`, thereby ensuring that orphaned Pod volume mount points are properly cleaned up within the reconciliation loop. Moreover, a PR addressing the issue has been backported to version `1.27` and is presently awaiting the merging process.

## Related information

* Related Longhorn issue: https://github.com/longhorn/longhorn/issues/3207
* Related Kubernetes issues & PRs
   - https://github.com/kubernetes/kubernetes/issues/105536
   - https://github.com/kubernetes/kubernetes/issues/111933
   - master `v1.28.x`: https://github.com/kubernetes/kubernetes/pull/116134
   - backport `v1.27`: https://github.com/kubernetes/kubernetes/pull/117235
