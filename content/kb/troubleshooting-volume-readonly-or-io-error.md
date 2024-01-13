---
title: "Troubleshooting: `volume readonly or I/O error`"
author: Shuo Wu
draft: false
date: 2021-01-08
categories:
  - "HA"
---

## Applicable versions
All Longhorn versions.

## Symptoms
When an application writes data to existing files or creates files in the mount point of a Longhorn volume, the following message is shown:
```
/ # cd data
/data # echo test > test
sh: can't create test: I/O error
```

When running the `dmesg` in the related pod or the node host, the following message is shown:
```
......
[1586907.286218] EXT4-fs (sdc): mounted filesystem with ordered data mode. Opts: (null)
[1587396.152106] EXT4-fs warning (device sdc): ext4_end_bio:323: I/O error 10 writing to inode 12 (offset 0 size 4096 starting block 33026)
[1587403.789877] EXT4-fs error (device sdc): ext4_find_entry:1455: inode #2: comm sh: reading directory lblock 0
[1587404.353594] EXT4-fs warning (device sdc): htree_dirblock_to_tree:994: inode #2: lblock 0: comm ls: error -5 reading directory block
[1587404.353598] EXT4-fs error (device sdc): ext4_journal_check_start:61: Detected aborted journal
[1587404.355087] EXT4-fs (sdc): Remounting filesystem read-only
......
```

When checking the event using `kubectl -n longhorn-system get event | grep <volume name>`, an event like the following is shown:
```
2m26s       Warning   DetachedUnexpectedly       volume/pvc-342edde0-d3f4-47c6-abf6-bf8eeda3c32c               Engine of volume pvc-342edde0-d3f4-47c6-abf6-bf8eeda3c32c dead unexpectedly, reattach the volume
```

When checking for logs of the Longhorn manager pods on the node the workload is running on by running `kubectl -n longhorn-system logs <longhorn manager pod name> | grep <volume name>`, the following message is shown:

```
time="2021-01-05T11:20:46Z" level=debug msg="Instance handler updated instance pvc-342edde0-d3f4-47c6-abf6-bf8eeda3c32c-e-0fe2dac3 state, old state running, new state error"
time="2021-01-05T11:20:46Z" level=warning msg="Instance pvc-342edde0-d3f4-47c6-abf6-bf8eeda3c32c-e-0fe2dac3 crashed on Instance Manager instance-manager-e-a1fd54e4 at shuo-cluster-0-worker-3, try to get log"
......
time="2021-01-05T11:20:46Z" level=warning msg="Engine of volume dead unexpectedly, reattach the volume" accessMode=rwo controller=longhorn-volume frontend=blockdev node=shuo-cluster-0-worker-3 owner=shuo-cluster-0-worker-3 state=attached volume=pvc-342edde0-d3f4-47c6-abf6-bf8eeda3c32c
......
time="2021-01-05T11:20:46Z" level=info msg="Event(v1.ObjectReference{Kind:\"Volume\", Namespace:\"longhorn-system\", Name:\"pvc-342edde0-d3f4-47c6-abf6-bf8eeda3c32c\", UID:\"69bb0f94-da48-4d15-b861-add435f25d00\", APIVersion:\"longhorn.io/v1beta1\", ResourceVersion:\"7466467\", FieldPath:\"\"}): type: 'Warning' reason: 'DetachedUnexpectedly' Engine of volume pvc-342edde0-d3f4-47c6-abf6-bf8eeda3c32c dead unexpectedly, reattach the volume"
```

### Reason for failure

The mount point of the Longhorn volume becomes invalid once the Longhorn volume crashes unexpectedly. Then there is no way to read or write data in the Longhorn volume via the mount point.

### Root causes
An engine crash is normally contributed to by losing the connections to every single replica. Here are the possible reasons why that's happened:

1. CPU utilization is too high on the node. If the Longhorn engine doesn't have enough CPU resources to handle the request, the request might time out, result in losing the connection to a replica. You can refer to [this doc](https://longhorn.io/docs/1.1.0/best-practices/#guaranteed-engine-cpu) to see how to reserve the proper amount of CPU resources for Longhorn instance manager pods.
2. The network bandwidth is not sufficient. Normally 1Gbps network will only able to serve 3 volumes if all of those volumes are running a high intensive workload.
3. The network latency is relatively high. If there are multiple volumes r/w simultaneously on a node, it's better to guarantee that the latency is less than 20ms.
4. Network interruption. It can result in all replicas disconnecting, then an engine crash.
5. The performance of the disk is too low to finish the request in time. We don't recommend using a low IOPS disks (e.g. spinning disks) in the Longhorn system.

### Automatic recovery
For Longhorn versions earlier than v1.1.0, Longhorn will try to remount the volume automatically, but the scenarios it can handle are limited.

Since Longhorn version v1.1.0, a new setting [`Automatically Delete Workload Pod when The Volume Is Detached Unexpectedly`](https://longhorn.io/docs/1.1.0/references/settings/#automatically-delete-workload-pod-when-the-volume-is-detached-unexpectedly) is introduced so that Longhorn will automatically delete the workload pod that is managed by a controller (e.g. deployment, statefulset, daemonset, etc...).

#### Manual recovery
If the workload is a simple pod, you can delete and re-deploy the pod. Please make sure the related PVC or PV is not removed if the reclaim policy is not `Retain`. Otherwise, the Longhorn volume will be removed once the related PVC/PV is gone.

If the workload pod belongs to Deployment/StatefulSet, you can restart the pod by scaling down then scaling up the workload replica.

And for Longhorn v1.1.0 or higher version, you can enable the setting `Automatically Delete Workload Pod when The Volume Is Detached Unexpectedly`.

### Other reasons
Users accidentally or manually detach the Longhorn volume while the related workload is still using the volume.

## Related information
1. The minimal resource requirement investigation and the result: https://github.com/longhorn/longhorn/issues/1691
2. The discussing for setting `Automatically Delete Workload Pod when The Volume Is Detached Unexpectedly`: https://github.com/longhorn/longhorn/issues/1719.
