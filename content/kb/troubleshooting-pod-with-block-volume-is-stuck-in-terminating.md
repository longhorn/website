---
title: "Troubleshooting: Pod with `volumeMode: Block` is stuck in terminating"
author: Phan Le
draft: false
date: 2022-04-06
categories:
- "HA"
---

## Applicable versions
All Longhorn versions.

## Symptoms

User has a pod that uses a PVC with `volumeMode: Block` provisioned by Longhorn CSI driver.
After an unexpected crash of the Longhorn volume (due to network, CPU pressure, hardware problem, etc...), the user cannot delete the pod.
The pod would be stuck in terminating forever since Kubelet refuses to unmount the block volume.
This prevents the user from cleaning up the pod and spinning up a new replacement pod thus leading to a long service degradation.
For example, if the pod is part of a StatefulSet, the replacement pod cannot come up due to the old pod being stuck terminating.

Kubelet logs the following error message:
```
W0324 04:21:58.982588    1232 volume_path_handler_linux.go:61] couldn't find loopback device which takes file descriptor lock. Skip detaching device. device path: "/var/lib/kubelet/plugins/kubernetes.io/csi/volumeDevices/pvc-417a59df-2c2b-44a1-9350-07b108bf96ec/dev/7c5b2ecb-cda5-4e72-95db-4e133ba3a563"
I0324 04:21:58.982793    1232 mount_linux.go:197] Detected OS without systemd
E0324 04:21:58.987894    1232 nestedpendingoperations.go:301] Operation for "{volumeName:kubernetes.io/csi/driver.longhorn.io^pvc-417a59df-2c2b-44a1-9350-07b108bf96ec podName:7c5b2ecb-cda5-4e72-95db-4e133ba3a563 nodeName:}" failed. No retries permitted until 2022-03-24 04:21:59.487840694 +0000 UTC m=+1184606.200514039 (durationBeforeRetry 500ms). Error: "UnmapVolume.UnmapBlockVolume failed for volume \"test-bv-volume\" (UniqueName: \"kubernetes.io/csi/driver.longhorn.io^pvc-417a59df-2c2b-44a1-9350-07b108bf96ec\") pod \"7c5b2ecb-cda5-4e72-95db-4e133ba3a563\" (UID: \"7c5b2ecb-cda5-4e72-95db-4e133ba3a563\") : blkUtil.DetachFileDevice failed. globalUnmapPath:/var/lib/kubelet/plugins/kubernetes.io/csi/volumeDevices/pvc-417a59df-2c2b-44a1-9350-07b108bf96ec/dev, podUID: 7c5b2ecb-cda5-4e72-95db-4e133ba3a563, bindMount: true: failed to unmount linkPath /var/lib/kubelet/plugins/kubernetes.io/csi/volumeDevices/pvc-417a59df-2c2b-44a1-9350-07b108bf96ec/dev/7c5b2ecb-cda5-4e72-95db-4e133ba3a563: unmount failed: exit status 32\nUnmounting arguments: /var/lib/kubelet/plugins/kubernetes.io/csi/volumeDevices/pvc-417a59df-2c2b-44a1-9350-07b108bf96ec/dev/7c5b2ecb-cda5-4e72-95db-4e133ba3a563\nOutput: umount: /var/lib/kubelet/plugins/kubernetes.io/csi/volumeDevices/pvc-417a59df-2c2b-44a1-9350-07b108bf96ec/dev/7c5b2ecb-cda5-4e72-95db-4e133ba3a563: target is busy.\n"
```

## Reason

This is a Kubelet bug.
Kubelet doesn't detect and detach the deleted loopback device corresponding the PV.
More details are at https://github.com/kubernetes/kubernetes/issues/109132

#### Solution

The long-term solution is wait for the upstream PR to be merged: https://github.com/kubernetes/kubernetes/pull/109083

For the temporary workaround, users can follow the steps at https://github.com/longhorn/longhorn/issues/3778#issuecomment-1085219265

## Related information

* Related Longhorn issue: https://github.com/longhorn/longhorn/issues/3778
* Upstream Kubernetes issue: https://github.com/kubernetes/kubernetes/issues/109132
