---
title: Node Maintenance and Kubernetes Upgrade Guide
weight: 3
---

This section describes how to handle planned node maintenance or upgrading Kubernetes version for the cluster.

- [Updating the Node OS or Container Runtime](#updating-the-node-os-or-container-runtime)
- [Removing a Disk](#removing-a-disk)
  - [Reusing the Node Name](#reusing-the-node-name)
- [Removing a Node](#removing-a-node)
- [Upgrading Kubernetes](#upgrading-kubernetes)
  - [In-place Upgrade](#in-place-upgrade)
  - [Managed Kubernetes](#managed-kubernetes)
- [Node Drain Policy Recommendations](#node-drain-policy-recommendations)
  - [Important Notes](#important-notes)
  - [Block If Contains Last Replica](#block-if-contains-last-replica)
  - [Allow If Last Replica Is Stopped](#allow-if-last-replica-is-stopped)
  - [Always Allow](#always-allow)
  - [Block For Eviction](#block-for-eviction)
  - [Block For Eviction If Contains Last Replica](#block-for-eviction-if-contains-last-replica)

## Updating the Node OS or Container Runtime

1. Cordon the node. Longhorn will automatically disable the node scheduling when a Kubernetes node is cordoned.

1. Drain the node to move the workload to somewhere else.

   It is necessary to use `--ignore-daemonsets` to drain the node. The `--ignore-daemonsets` is needed because Longhorn
   deployed some daemonsets such as `Longhorn manager`, `Longhorn CSI plugin`, `engine image`.

   While the drain proceeds, engine processes on the node will be migrated with the workload pods to other nodes.

   > **Note:** Volumes that are not attached through the CSI flow on the node (for example, manually attached using
   > UI) will not be automatically attached to new nodes by Kubernetes during the draining. Therefore, Longhorn will
   > prevent the node from completing the drain operation. The user will need to detach these volumes manually to
   > unblock the draining.

   While the drain proceeds, replica processes on the node will either continue to run or eventually be evicted and
   stopped based on the [Node Drain Policy](#node-drain-policy-recommendations).

   > **Note:** By default, if there is one last healthy replica for a volume on the node, Longhorn will prevent the node
   > from completing the drain operation, to protect the last replica and prevent the disruption of the workload. You
   > can control this behavior with the setting [Node Drain Policy](../../references/settings#node-drain-policy), or
   > [evict the replica to other nodes before draining](../../nodes-and-volumes/nodes/disks-or-nodes-eviction). See [Node Drain Policy
   > Recommendations](#node-drain-policy-recommendations) for considerations when selecting a policy.

   After the drain is completed, there should be no engine or replica processes running on the node, as the
   instance-manager pod that was running them will be stopped. Depending on the [Node Drain
   Policy](#node-drain-policy-recommendations), replicas scheduled to the node will either appear as `Failed` or be
   removed in favor of replacements. Workloads using Longhorn volumes will function as expected and enough replicas will
   be running elsewhere to meet the requirements of the policy.

   > **Note:** Normally you don't need to evict the replicas before the drain operation, as long as you have healthy
   > replicas on other nodes. The replicas can be reused later, once the node back online and uncordoned. See [Node
   > Drain Policy](#node-drain-policy-recommendations) for further guidance.

1. Perform the necessary maintenance, including shutting down or rebooting the node.
1. Uncordon the node. Longhorn will automatically re-enable the node scheduling. If there are existing replicas on the
   node, Longhorn might use those replicas to speed up the rebuilding process. You can set the [Replica Replenishment
   Wait Interval](../../references/settings#replica-replenishment-wait-interval) setting to customize how long Longhorn
   should wait for potentially reusable replica to be available.

## Removing a Disk

To remove a disk:

1. Disable the disk scheduling.
1. Evict all the replicas on the disk.
1. Delete the disk.

### Reusing the Node Name

These steps also apply if you've replaced a node using the same node name. Longhorn will recognize that the disks are
different once the new node is up. You will need to remove the original disks first and add them back for the new node
if it uses the same name as the previous node.

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

In-place upgrade is upgrading method in which nodes are upgraded without being removed from the cluster. Some example
solutions that use this upgrade methods are [k3s automated upgrades](https://docs.k3s.io/upgrades/automated), [Rancher's
Kubernetes upgrade
guide](https://rancher.com/docs/rancher/v2.x/en/cluster-admin/upgrading-kubernetes/#upgrading-the-kubernetes-version),
[Kubeadm upgrade](https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-upgrade/), etc...

With the assumption that node and disks are not being deleted/removed, the recommended upgrading guide is:

1. Cordon and drain a node before upgrading Kubernetes components. Draining instructions are similar to the ones at
   [Updating the Node OS or Container Runtime](#updating-the-node-os-or-container-runtime).
2. The drain `--timeout` should be big enough so that replica rebuildings on healthy nodes can finish between node
   upgrades. The more Longhorn replicas you have on the draining node, the more time it takes for the Longhorn replicas
   to be rebuilt on other healthy nodes. We recommending you to test and select a big enough value or set it to 0 (aka
   never timeout).
3. The number of nodes upgrading at a time should be smaller than the number of Longhorn replicas for each volume.
   This is so that a running Longhorn volume has at least one healthy replica running at a time.
4. Consider setting the setting [Node Drain Policy](../../references/settings#node-drain-policy) to
   `allow-if-replica-is-stopped` so that the drain is not blocked by the last healthy replica of a detached volume. See
   [Node Drain Policy Recommendations](#node-drain-policy-recommendations) for considerations when selecting a policy.

### Managed Kubernetes

See the instruction at [Support Managed Kubernetes Service](../../advanced-resources/support-managed-k8s-service).

## Node Drain Policy Recommendations

There are currently five Node Drain Policies available for selection. Each has its own benefits and drawbacks. This
section provides general guidance on each and suggests situations in which each might be used.

### Important Notes

Node Drain Policy is intended to govern Longhorn behavior when a node is actively being drained. However, there is no
way for Longhorn to determine the difference between the cordoning and draining of a node, so, depending on the policy,
Longhorn may take action any time a node is cordoned, even if it is not being drained.

Node drain policy works to prevent the eviction of an instance-manager pod during a drain until certain conditions are
met. If the instance-manager pod cannot be evicted, the drain cannot complete. This prevents a user (or automated
process) from continuing to shut down or restart a node if it is not safe to do so. It may be tempting to ignore the
drain failure and proceed with maintenance operations if it seems to take too long, but this limits Longhorn's ability
to protect data. Always look at events and/or logs to try to determine WHY the drain is not progressing and take actions
to fix the underlying issue.

### Block If Contains Last Replica

This is the default policy. It is intended to provide a good balance between convenience and data protection. While it
is in effect, Longhorn will prevent the eviction of an instance-manager pod (and the completion of a drain) on a
cordoned node that contains the last healthy replica of a volume.

Benefits:

- Protects data by preventing the drain operation from completing until there is a healthy replica available for each
  volume available on another node.

Drawbacks:

- If there is only one replica for the volume, or if its other replicas are unhealthy, the user may need to manually
  (through the UI) request the eviction of replicas from the disk or node.
- Volumes may be degraded after the drain is complete. If the node is rebooted, redundancy is reduced until it is
  running again. If the node is removed, redundancy is reduced until another replica rebuilds.

### Allow If Last Replica Is Stopped

This policy is similar to `Block If Contains Last Replica`. It is inherently less safe, but can allow drains to complete
more quickly. It only prevents the eviction of an instance-manager pod (and the completion of a drain) on a node that
contains the last RUNNING healthy replica.

Benefits:

- Allows the drain operation to proceed in situations where the node being drained is expected to come back online
  (data will not be lost) and the replicas stored on the node's disks are not actively being used.

Drawbacks:

- Similar drawbacks to `Block If Contains Last Replica`.
- If, for some reason, the node never comes back, data is lost.

### Always Allow

This policy does not protect data in any way, but allows drains to immediately complete. It never prevents the eviction
of an instance-manager pod (and the completion of a drain). Do not use it in a production environment.

Benefits:

- The drain operation completes quickly without Longhorn getting in the way.

Drawbacks:

- There is no opportunity for Longhorn to protect data.

### Block For Eviction

This policy provides the maximum amount of data protection, but can lead to long drain times and unnecessary data
movement. It prevents the eviction of an instance-manager pod (and the completion of a drain) as long as any replicas
remain on a node. In addition, it takes action to automatically evict replicas from the node.

It is not recommended to leave this policy enabled under normal use, as it will trigger replica eviction any time a
node is cordoned. Only enable it during planned maintenance.

A primary use case for this policy is when automatically upgrading clusters in which volumes have no redundancy
(`numberOfReplicas == 1`). Other policies will prevent the drain until such replicas are manually evicted, which is
inconvenient for automation.

Benefits:

- Protects data by preventing the drain operation from completing until all replicas have been relocated.
- Automatically evicts replicas, so the user does not need to do it manually (through the UI).
- Maintains replica redundancy at all times.

Drawbacks:

- The drain operation is significantly slower than for other behaviors. Every replica must be rebuilt on another node
  before it can complete. Drain timeout must be adjusted as appropriate for the amount of data that will move during
  rebuilding.
- The drain operation is data-intensive, especially when replica auto balance is enabled, as evicted replicas may be
  moved back to the drained node when/if it comes back online.
- Like all of these policies, it triggers on cordon, not on drain. If a user regularly cordons nodes without draining
  them, replicas will be rebuilt pointlessly.

### Block For Eviction If Contains Last Replica

This policy provides the data protection of the default `Block If Contains Last Replica` with the added convenience of
automatic eviction. While it is in effect, Longhorn will prevent the eviction of an instance-manager pod (and the
completion of a drain) on a cordoned node that contains the last healthy replica of a volume. In addition, replicas that
meet this condition are automatically evicted from the node.

It is not recommended to leave this policy enabled under normal use, as it may trigger replica eviction any time a
node is cordoned. Only enable it during planned maintenance.

A primary use case for this policy is when automatically upgrading clusters in which volumes have no redundancy
(`numberOfReplicas == 1`). Other policies will prevent the drain until such replicas are manually evicted, which is
inconvenient for automation.

Benefits:

- Protects data by preventing the drain operation from completing until there is a healthy replica available for each
  volume available on another node.
- Automatically evicts replicas, so the user does not need to do it manually (through the UI).
- The drain operation is only as slow and data-intensive as is necessary to protect data.

Drawbacks:

- Volumes may be degraded after the drain is complete. If the node is rebooted, redundancy is reduced until it is
  running again. If the node is removed, redundancy is reduced until another replica rebuilds.
- Like all of these policies, it triggers on cordon, not on drain. If a user regularly cordons nodes without draining
  them, replicas will be rebuilt pointlessly.
