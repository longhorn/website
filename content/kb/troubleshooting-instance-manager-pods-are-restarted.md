---
title: "Troubleshooting: Instance Manager Pods Are Restarted"
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

The Instance Manager pods are restarted, which causes a large number of iSCSI connection errors. Longhorn Engines are disconnected from the replicas, making the volume unstable.

Example of iSCSI errors in the kernel log:
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

Example of messages displayed when the Instance Manager container is suddenly terminated:
```
time="2024-11-21T06:12:20.651526777Z" level=info msg="shim disconnected" id=548c02c5bc17426da586373f902e8d5811d5efe4e45d5fbd0495920626d014d9 namespace=k8s.io
time="2024-11-21T06:12:20.651603253Z" level=warning msg="cleaning up after shim disconnected" id=548c02c5bc17426da586373f902e8d5811d5efe4e45d5fbd0495920626d014d9 namespace=k8s.io
time="2024-11-21T06:12:21.819863412Z" level=info msg="Container to stop \"548c02c5bc17426da586373f902e8d5811d5efe4e45d5fbd0495920626d014d9\" must be in running or unknown state, current state \"CONTAINER_EXITED\""
```

## Root Cause

The Instance Manager pod is a critical component that is responsible for managing the engine and replica processes of the volume. If the Instance Manager pod becomes unstable and then crashes or restarts unexpectedly, the volumes also become unstable.

An Instance Manager pod can be restarted or deleted for various reasons, including the following:

### High CPU Loading

The Instance Manager pod has a liveness probe that periodically checks the health of servers in the pod. An excessive number of running replica or engine processes may overload the servers and prevent them from responding to the liveness probe in a timely manner. The delayed response may cause the liveness probe to fail, prompting Kubernetes to either restart the container or terminate the pod.

The solution is to monitor CPU, memory, and network usage in the Kubernetes cluster. When resource usage is high, consider adding nodes or increasing the CPU and memory resources of existing nodes in the cluster. You can also use the [Replica Auto Balance](https://longhorn.io/docs/1.7.2/references/settings/#replica-auto-balance) settings to better balance the load across nodes.

### Old Instance Manager Pod Terminated

When you upgrade Longhorn, a new Instance Manager with an updated image and engine image is created. However, Longhorn does not delete the old Instance Manager pod until all volumes are upgraded to the new engine image, and all replica and engine processes are stopped. In this case, termination of the Instance Manager is expected.

For more information about upgrading volumes and how the transition process works, see [Upgrade](https://longhorn.io/docs/1.7.2/deploy/upgrade/).


### Danger Zone Settings Updated

Changes to certain settings in the [Danger Zone](https://longhorn.io/docs/1.7.2/references/settings/#danger-zone) are applied only after the system-managed components (for example, Instance Manager, CSI Driver, and engine images) are restarted.

Longhorn waits until all volumes detached before restarting Instance Manager pods.

## Related Information

* Longhorn issue: [#9851](https://github.com/longhorn/longhorn/issues/9851)
