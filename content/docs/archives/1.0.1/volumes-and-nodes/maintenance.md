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

1. Cordon the node. Longhorn will automatically disable the node scheduling when a Kubernetes node is cordoned.

1. Drain the node to move the workload to somewhere else.

    You will need to use `--ignore-daemonsets` and `--force` options to drain the node.

    The replica processes on the node will be stopped at this stage. 
        
    > **Upcoming feature:** After adding the support of `Replica eviction`, you will be able to evict the replicas on the node gracefully.
    
    The engine processes on the node will be migrated with the Pod to other nodes.

    After the `drain` is completed, there should be no engine or replica process running on the node. Two instance managers will still be running on the node, but they're stateless and won't cause interruption to the existing workload.
1. Perform the necessary maintenance, including shutting down or rebooting the node.
1. Uncordon the node. Longhorn will automatically re-enable the node scheduling.
    
    > **Upcoming features:**
    >
    > - After adding the support of the **Reuse existing replica data for rebuild** feature, the replica rebuild will be faster and take less space.
    > - After adding the support of the **Disable replica rebuild** feature, there will not be an unnecessary replica rebuild caused by the node maintenance.

## Updating Kubernetes

If Longhorn is installed as a Rancher catalog app, follow [Rancher's Kubernetes upgrade guide](https://rancher.com/docs/rancher/v2.x/en/cluster-admin/upgrading-kubernetes/#upgrading-the-kubernetes-version) to upgrade Kubernetes.

Otherwise, follow the official [Kubernetes upgrade documentation.](https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-upgrade/)

### Avoid Node `drain` During Upgrades

We do not recommend draining the node for Kubernetes upgrades. It will cause an unnecessary burden to Longhorn since it will result in replica failure and rebuild in most cases.

## Removing a Disk
To remove a disk:
1. Disable the disk scheduling.
1. Delete all the replicas on the disk.

    It's recommended to do it one by one since this step will trigger the replicas to rebuild.

    > **Upcoming feature:** The replica eviction feature can also help here.
1. Delete the disk.

### Reusing the Node Name

These steps also apply if you've replaced a node using the same node name. Longhorn will recognize that the disks are different once the new node is up. You will need to remove the original disks first and add them back for the new node if it uses the same name as the previous node.

## Removing a Node
To remove a node:
1. Disable the disk scheduling.
1. Delete all the replicas on the node.

    It's recommended to delete replicas one by one since this step will trigger the replicas to rebuild.

    > **Upcoming feature:** The replica eviction feature can also help here.
1. Detach all the volumes on the node.
    
    If the node has been drained, all the workloads should be migrated to another node already.

    If there are any other volumes remaining attached, detach them before continuing.
1. Remove the node from Kubernetes, using:

        kubectl delete node <node-name>
1. Delete the node in Longhorn.
