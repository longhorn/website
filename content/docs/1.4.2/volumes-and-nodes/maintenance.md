---
title: Node Maintenance and Kubernetes Upgrade Guide
weight: 6
---

This section describes how to handle planned node maintenance or upgrading Kubernetes version for the cluster.

- [Updating the Node OS or Container Runtime](#updating-the-node-os-or-container-runtime)
- [Removing a Disk](#removing-a-disk)
  - [Reusing the Node Name](#reusing-the-node-name)
- [Removing a Node](#removing-a-node)
- [Upgrading Kubernetes](#upgrading-kubernetes)
  - [In-place Upgrade](#in-place-upgrade)
  - [Managed Kubernetes](#managed-kubernetes)

## Updating the Node OS or Container Runtime

1. Cordon the node. Longhorn will automatically disable the node scheduling when a Kubernetes node is cordoned.

1. Drain the node to move the workload to somewhere else.

   You will need to use `--ignore-daemonsets` to drain the node.
   The `--ignore-daemonsets` is needed because Longhorn deployed some daemonsets such as `Longhorn manager`, `Longhorn CSI plugin`, `engine image`.

   The running replicas on the node will be stopped at this stage. They will be shown as `Failed`.

   > **Note:**
   > By default, if there is one last healthy replica for a volume on
   > the node, Longhorn will prevent the node from completing the drain
   > operation, to protect the last replica and prevent the disruption of the
   > workload. You can control this behavior in the setting [Node Drain Policy](../../references/settings#node-drain-policy), or [evict
   > the replica to other nodes before draining](../disks-or-nodes-eviction).

   The engine processes on the node will be migrated with the Pod to other nodes.
   > **Note:** For volumes that are not attached through the CSI flow on the node (for example, manually attached using UI),
   > they will not be automatically attached to new nodes by Kubernetes during the draining.
   > Therefore, Longhorn will prevent the node from completing the drain operation.
   > User would need to handle detachment for these volumes to unblock the draining.

   After the `drain` is completed, there should be no engine or replica process running on the node. Two instance managers will still be running on the node, but they're stateless and won't cause interruption to the existing workload.

   > **Note:** Normally you don't need to evict the replicas before the drain
   > operation, as long as you have healthy replicas on other nodes. The replicas
   > can be reused later, once the node back online and uncordoned.

1. Perform the necessary maintenance, including shutting down or rebooting the node.
1. Uncordon the node. Longhorn will automatically re-enable the node scheduling.
   If there are existing replicas on the node, Longhorn might use those
   replicas to speed up the rebuilding process. You can set the [Replica
   Replenishment Wait Interval](../../references/settings#replica-replenishment-wait-interval) setting to customize how long Longhorn should
   wait for potentially reusable replica to be available.

## Removing a Disk
To remove a disk:
1. Disable the disk scheduling.
1. Evict all the replicas on the disk.
1. Delete the disk.

### Reusing the Node Name

These steps also apply if you've replaced a node using the same node name. Longhorn will recognize that the disks are different once the new node is up. You will need to remove the original disks first and add them back for the new node if it uses the same name as the previous node.

## Removing a Node
To remove a node:
1. Disable the disk scheduling.
1. Evict all the replicas on the node.
1. Detach all the volumes on the node.

   If the node has been drained, all the workloads should be migrated to another node already.

   If there are any other volumes remaining attached, detach them before continuing.

1. Remove the node from Longhorn using the `Delete` in the `Node` tab.

   Or, remove the node from Kubernetes, using:

        kubectl delete node <node-name>

1. Longhorn will automatically remove the node from the cluster.

## Upgrading Kubernetes

### In-place Upgrade
In-place upgrade is upgrading method in which nodes are upgraded without being removed from the cluster.
Some example solutions that use this upgrade methods are [k3s automated upgrades](https://docs.k3s.io/upgrades/automated), [Rancher's Kubernetes upgrade guide](https://rancher.com/docs/rancher/v2.x/en/cluster-admin/upgrading-kubernetes/#upgrading-the-kubernetes-version),
[Kubeadm upgrade](https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-upgrade/), etc...

With the assumption that node and disks are not being deleted/removed, the recommended upgrading guide is:
1. You should cordon and drain a node before upgrading Kubernetes components on a node.
   Draining instruction is similar to the drain instruction at [Updating the Node OS or Container Runtime](#updating-the-node-os-or-container-runtime)
2. The drain `--timeout` should be big enough so that replica rebuildings on healthy node can finish.
   The more Longhorn replicas you have on the draining node, the more time it takes for the Longhorn replicas to be rebuilt on other healthy nodes.
   We recommending you to test and select a big enough value or set it to 0 (aka never timeout).
3. The number of nodes doing upgrade at a time should be smaller than the number of Longhorn replicas for each volume.
   This is so that a running Longhorn volume has at least one healthy replica running at a time.
4. Set the setting [Node Drain Policy](../../references/settings#node-drain-policy) to `allow-if-replica-is-stopped` so that the drain is not blocked by the last healthy replica of a detached volume.


### Managed Kubernetes
See the instruction at [Support Managed Kubernetes Service](../../advanced-resources/support-managed-k8s-service)


