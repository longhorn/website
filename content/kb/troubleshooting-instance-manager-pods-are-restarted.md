---
title: "Troubleshooting: Instance manager pods are restarted"
authors:
- "Jack Lin"
draft: false
date: 2024-12-12
versions:
- "all"
categories:
- "instance manager"
---

## Applicable versions

All Longhorn versions.

## Symptoms

The instance manager pods are restarted which leads to a huge amount of iSCSI connection errors.
As the consequence, Longhorn engines lose the connection to the replicas and it makes the volume unstable.

You might find iSCSI errors in the Kernel log
```
Nov 21 00:54:02 node-xxx kernel:  connection438:0: detected conn error (1020)
Nov 21 00:54:02 node-xxx kernel:  connection437:0: detected conn error (1020)
Nov 21 00:54:02 node-xxx kernel:  connection436:0: detected conn error (1020)
Nov 21 00:54:02 node-xxx kernel:  connection435:0: detected conn error (1020)
Nov 21 00:54:02 node-xxx kernel:  connection434:0: detected conn error (1020)
Nov 21 00:54:02 node-xxx kernel:  connection433:0: detected conn error (1020)
Nov 21 00:54:02 node-xxx kernel:  connection432:0: detected conn error (1020)
....
Nov 21 00:54:02 node-xxx kernel:  connection275:0: detected conn error (1020) 
```

You might also find that the instance manager container suddenly terminates with logs
```
time="2024-11-21T06:12:20.651526777Z" level=info msg="shim disconnected" id=548c02c5bc17426da586373f902e8d5811d5efe4e45d5fbd0495920626d014d9 namespace=k8s.io
time="2024-11-21T06:12:20.651603253Z" level=warning msg="cleaning up after shim disconnected" id=548c02c5bc17426da586373f902e8d5811d5efe4e45d5fbd0495920626d014d9 namespace=k8s.io
time="2024-11-21T06:12:21.819863412Z" level=info msg="Container to stop \"548c02c5bc17426da586373f902e8d5811d5efe4e45d5fbd0495920626d014d9\" must be in running or unknown state, current state \"CONTAINER_EXITED\""
```

## Reason

The instance manager pod is a critical component responsible for managing the engine and replica processes of the volume. If the instance manager pod becomes unstable and crashes or restarts unexpectedly, the volumes will also become unstable.

Here are some common reasons reasons why an instance manager pod is restarted or deleted.

### High CPU Loading

The instance manager pod has a liveness probe configured to periodically check the health of the servers inside the pod.
One potential cause of instability is an excessive number of replica and engine processes running within the pod, which can overload the server and prevent it from responding to the liveness probe in time.
This may cause the liveness probe to fail, prompting Kubernetes to either restart the container or terminate the pod.

The solution is to monitor CPU, memory, and network usage in the Kubernetes cluster. When resource usage is too high, consider adding more computing resources, such as adding nodes or expanding the CPU and memory capacity of existing nodes in the cluster.

You can also refer to the [Replica Auto Balance](https://longhorn.io/docs/1.7.2/references/settings/#replica-auto-balance) setting to better balance the load across each node.

### Old Instance Manager Pod Terminated.

When you upgrade Longhorn to a new version, a new instance manager with an updated image and engine image will be created.
However, Longhorn waits until all volumes are upgraded to the new engine image and no replica or engine processes are running on the old instance manager pod before deleting it.

In this case, the terminating of the instance manager is expected.

You can refer to the [Upgrade](https://longhorn.io/docs/1.7.2/deploy/upgrade/) guide to learn how to upgrade volumes and understand how the transition process works.

### Danger Zone Setting Updated

There are several settings in [Danger Zone](https://longhorn.io/docs/1.7.2/references/settings/#danger-zone) which will need to restart the system-managed components (for example, Instance Manager, CSI Driver, and engine images) to apply the settings. 

Longhorn will not restart the instance manager pod while replicas and engines are still running. This means you must detach all volumes before the settings can be synchronized. If the settings are not applied, you will need to reconfigure them after detaching the remaining volumes."

## Related information

* Longhorn issue: https://github.com/longhorn/longhorn/issues/9851
