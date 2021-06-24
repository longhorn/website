---
title: "Drain node stuck forever with pod's disruption budget"
draft: true
weight: 1
---

<!-- TOC -->

- [Relate Issues](#relate-issues)
- [Issue Description](#issue-description)
- [Known Scenarios and solutions](#known-scenarios-and-solutions)
  - [Scenario 1: Storage class has `numberOfReplicas` of `1`](#scenario-1-storage-class-has-numberofreplicas-of-1)
  - [Scenario 2: PersistentVolumeClaim/PersistentVolume/LonghornVolume is created through Longhorn UI and attached to a host node](#scenario-2-persistentvolumeclaimpersistentvolumelonghornvolume-is-created-through-longhorn-ui-and-attached-to-a-host-node)
  - [Scenario 3: ReadWriteOnce volume with last healthy replica](#scenario-3-readwriteonce-volume-with-last-healthy-replica)
  - [Scenario 4: ReadWriteMany volume attached to a node](#scenario-4-readwritemany-volume-attached-to-a-node)
  - [Scenario 5: Size of Node is 1](#scenario-5-size-of-node-is-1)
  - [Scenario 6: PersistentVolumeClaim/PersistentVolume/LonghornVolume is created through Longhorn UI, but has not yet attached and replicated](#scenario-6-persistentvolumeclaimpersistentvolumelonghornvolume-is-created-through-longhorn-ui-but-has-not-yet-attached-and-replicated)
  <!-- /TOC -->

## Relate Issues

- [[BUG] kubectl drain node gets stuck forever #2673](https://github.com/longhorn/longhorn/issues/2673)
- [[Question] Single node cluster, node drain/reboot issue. #2385](https://github.com/longhorn/longhorn/issues/2385)
- [[BUG] Improve Kubernetes node drain support #1631](https://github.com/longhorn/longhorn/issues/1631)
- [Interaction with Kubernetes Drain and Cordon operation #1278](https://github.com/longhorn/longhorn/issues/1278)
- [[BUG] Drain action fails on the nodes in a cluster when longhorn is deployed. #1286](https://github.com/longhorn/longhorn/issues/1286)
- [[BUG] Worker node cordoned does not change the state of nodes in Longhorn #1287](https://github.com/longhorn/longhorn/issues/1287)

## Issue Description

During Kubernetes upgrade, administrators need to perform [drain nodes](https://kubernetes.io/docs/tasks/administer-cluster/safely-drain-node/) to safely evict all of pods from a node before performing maintenance on the node. In practice, the kubectl drain command should only be issued to a single node at a time. However, execute Kubernetes drain command:

```bash
NODE=xxx-worker-0
kubectl cordon ${NODE}
kubectl drain --force --ignore-daemonsets --delete-emptydir-data --grace-period=10 ${NODE}
```

Longhorn sometime encounters the error message:

```log
evicting pod longhorn-system/instance-manager-r-xxxxxxxx
error when evicting pods/"instance-manager-r-xxxxxxxx" -n "longhorn-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
```

It may caused by following scenarios.

## Known Scenarios and solutions

### Scenario 1: Storage class has `numberOfReplicas` of `1`

- If volume storageclass `numberOfReplicas` is `1`, it needs to increase the number to `2` or more. Otherwise, drain node will encounter pod's disruption budget errors and upgrade will time out.

### Scenario 2: PersistentVolumeClaim/PersistentVolume/LonghornVolume is created through Longhorn UI and attached to a host node

- Volume need to detach from node then node can be drain successfully.

### Scenario 3: ReadWriteOnce volume with last healthy replica

- When set setting `allow-node-drain-with-last-healthy-replica` to `true`, node with last healthy replica of ReadWriteOnce volume can able to drain successfully. Please be careful with using this setting. If workload volume `reclaimPolicy` is not set as `retained`, volume will be deleted and data will be loss completely.

### Scenario 4: ReadWriteMany volume attached to a node

- If node with ReadWriteMany volume attached, workload need to scale down then node can be drain successfully.

### Scenario 5: Size of Node is 1

- Set setting `allow-node-drain-with-last-healthy-replica` to `true`, and scale down all workload with volume to zero then node can be drain successfully.

### Scenario 6: PersistentVolumeClaim/PersistentVolume/LonghornVolume is created through Longhorn UI, but has not yet attached and replicated

- After volume is attached, replicate, and detached, the nodes with volume replicas can be drained successfully.
- This issue does not seem to be an issue if volume create through PersistentVolumeClaim using manifest.
