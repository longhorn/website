---
title: Node Maintenance Guide
weight: 6
---

This section describes how to handle planned maintenance of nodes.

- [Updating Node OS or Container Runtime](#updating-the-node-os-or-container-runtime)
- [Updating Kubernetes](#updating-kubernetes)
- [Removing a Disk](#removing-a-disk)
- [Removing a Node](#removing-a-node)

## Updating the Node OS or Container Runtime

Currently, it's recommended to shut down the workloads with Longhorn volume before performing the node maintenance. Otherwise, it might cause unnecessary replica failure during the node down period.

If shutting down the workloads is not possible, follow the steps below to minimize the impact for node maintenance:

1. Set **Replica Concurrent Rebuild Limit** to 0 in the settings to stop any new replicas from rebuilding.

1. Cordon the node. Longhorn will automatically disable the node scheduling when a Kubernetes node is cordoned.

1. Drain the node to move the workload to somewhere else.

    You will need to use `--ignore-daemonsets` and `--force` options to drain the node.

    The replica processes on the node will be stopped at this stage. Since the rebuild is not allowed, new replicas will not be created or rebuilt.
        
    > **Upcoming feature:** After adding the support of `Replica eviction`, you will be able to evict the replicas on the node gracefully.
    
    The engine processes on the node will be migrated with the Pod to other nodes.

    After the `drain` is completed, there should be no engine or replica process running on the node. Two instance managers will still be running on the node, but they're stateless and won't cause interruption to the existing workload.
1. Perform the necessary maintenance, including shutting down or rebooting the node.
1. Uncordon the node. Longhorn will automatically re-enable the node scheduling.
1. Set `Replica Concurrent Rebuild Limit` back to the desired number, e.g. `10`.
    
    > **Upcoming feature:** After adding the support of the **Reuse existing replica data for rebuild** feature, the replica rebuild will be faster and take less space.

If the maintenance are performed on multiple nodes, we suggest keeping `Replica Concurrent Rebuild Limit` at 0 until all the maintenance work was done.

## Updating Kubernetes

If Longhorn is installed as a Rancher catalog app, follow [Rancher's Kubernetes upgrade guide](https://rancher.com/docs/rancher/v2.x/en/cluster-admin/upgrading-kubernetes/#upgrading-the-kubernetes-version) to upgrade Kubernetes.

Otherwise, follow the official [Kubernetes upgrade documentation.](https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-upgrade/)

We recommend not to `drain` the node if possible.

## Removing a Disk
To remove a disk:
1. Disable the disk scheduling.
1. Delete all the replicas on the disk.

    It's recommended to do it one by one since this step will trigger the replicas to rebuild.

    > **Upcoming feature:** The replica eviction feature can also help here.
1. Once all the replicas are deleted, delete the disk.

## Removing a Node
To remove a node:
1. Disable the disk scheduling.
1. Delete all the replicas on the node.

    It's recommended to do it one by one since this step will trigger the replicas to rebuild.

    > **Upcoming feature:** The replica eviction feature can also help here.
1. Once all the replicas are deleted, remove the node from Kubernetes, using:

        kubectl delete node <node-name>
1. Once the node removed from Kubernetes, delete the node in Longhorn.