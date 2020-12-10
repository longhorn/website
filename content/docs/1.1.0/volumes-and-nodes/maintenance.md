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

1. Cordon the node. Longhorn will automatically disable the node scheduling when a Kubernetes node is cordoned.

1. Drain the node to move the workload to somewhere else.

    You will need to use `--ignore-daemonsets` options to drain the node because Longhorn deployed some daemonsets such as `Longhorn manager`, `Longhorn CSI plugin`, `engine image`.

    The replica processes on the node will be stopped at this stage. Replicas on
    the node will be shown as `Failed`.

        Note: By default, if there is one last healthy replica for a volume on
        the node, Longhorn will prevent the node from completing the drain
        operation, to protect the last replica and prevent the disruption of the
        workload. You can either override the behavior in the setting, or evict
        the replica to other nodes before draining.

    The engine processes on the node will be migrated with the Pod to other nodes.

        Note: If there are volumes not created by Kubernetes on the node,
        Lognhorn will prevent the node from completing the drain operation, to
        prevent the potential workload disruption.

    After the `drain` is completed, there should be no engine or replica process running on the node. Two instance managers will still be running on the node, but they're stateless and won't cause interruption to the existing workload.

        Note: Normally you don't need to evict the replicas before the drain
        operation, as long as you have healthy replicas on other nodes. The replicas
        can be reused later, once the node back online and uncordoned.

1. Perform the necessary maintenance, including shutting down or rebooting the node.
1. Uncordon the node. Longhorn will automatically re-enable the node scheduling.

    If there are existing replicas on the node, Longhorn might use those
    replicas to speed up the rebuilding process. You can set the `Replica
    Replenishment Wait Interval` setting to customize how long Longhorn should
    wait for potentially reusable replica to be available.

## Updating Kubernetes

Follow the official [Kubernetes upgrade documentation.](https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-upgrade/)

* If Longhorn is installed as a Rancher catalog app, follow [Rancher's Kubernetes upgrade guide](https://rancher.com/docs/rancher/v2.x/en/cluster-admin/upgrading-kubernetes/#upgrading-the-kubernetes-version) to upgrade Kubernetes.

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

1. Remove the node from Kubernetes, using:

        kubectl delete node <node-name>

1. Longhorn will automatically remove the node from the cluster.
