---
title: Scheduling
weight: 8
---

In this section, you'll learn how Longhorn schedules replicas based on multiple factors.

#### Scheduling Policy

Longhorn scheduling policy has two stages, only the previous stage gets satisfied, the scheduler will goto the next stage, otherwise the scheduling will fail. Also during selecting the node or the disk, they has to match the node tag and the disk tag if any tag has been set in order to be selected.

1. Node and Zone selection stage, Longhorn will filter the node and zone based on `Replica Node Level Soft Anti-Affinity` and `Replica Zone Level Soft Anti-Affinity`.
2. Disk selection stage, Longhorn will filter the disk which satisfied the first stage based on `Storage Minimal Available Percentage`, `Storage Over Provisioning Percentage` and other disk related factors like request disk space. 

##### Node and Zone Selection Stage

First, Longhorn will always try to schedule the new replica on a new node with a new zone if possible. At this time if both `Replica Node Level Soft Anti-Affinity` and `Replica Zone Level Soft Anti-Affinity` are un-checked. Longhorn will not schedule the replica if there is no new node with new zone.

Then, Longhorn will look for new node with existing zone. And it will schedule the new replica on the new node with existing zone if possible. At this time if `Replica Node Level Soft Anti-Affinity` is un-checked and `Replica Zone Level Soft Anti-Affinity` is checked. Longhorn will not schedule the replica if there is no new node with existing zone.

Last, Longhorn will looking for existing node with existing zone to schedule the new replica. At this time both `Replica Node Level Soft Anti-Affinity` and `Replica Zone Level Soft Anti-Affinity` should be checked.

##### Disk Selection Stage

Once the Node and Zone stage gets satisfied, Longhorn will check the avaiable disks on the selected node with matched tag and the total disk space and avaiable disk space to decide if it can schedule the replica on the disk of the node.

For example, after the Node and Zone stage, Longhorn finds `Node A` satisfied. Longhorn will check all the avaiable disk on this node. Assume this node has two disk: `Disk X` with avaliable space 1GB, and `Disk Y` with available space 2GB. And the replica Longhorn going to schedule needs 1GB. With default `Storage Minimal Available Percentage` 25, Longhorn can only schdule the replica on `Disk Y` if this `Disk Y` match the disk tag, otherwise Longhorn will return failure on this replica selection. But if the `Storage Minimal Available Percentage` is set to 0, and `Disk X` also matches the disk tag, Longhorn can schedule the replica on `Disk X`.


#### Settings

1. `Disable Scheduling On Cordoned Node`. Default is checked.

When this setting is checked. Longhorn manager will not schedule replicas on Kubernetes cordoned node.
When this setting is un-checked. Longhorn manager will schedule replicas on Kubernetes cordoned node.

2. `Replica Node Level Soft Anti-Affinity`. Default is un-checked.

When this setting is checked. Longhorn manager will allow scheduling on nodes with existing healthy replicas of the same volume.
When this setting is un-checked. Longhorn manager will not allow scheduling on nodes with existing healthy replicas of the same volume.

3. `Replica Zone Level Soft Anti-Affinity`. Default is checked.

When this setting is checked. Longhorn manager will allow scheduling new Replicas of Volume to the Nodes in the same Zone as existing healthy Replicas.
When this setting is un-checked. Longhorn manager will not allow scheduling new Replicas of Volume to the Nodes in the same Zone as existing healthy Replicas.

> **Note:** Nodes don't belong to any Zone will be treated as in the same Zone.

4. `Storage Minimal Available Percentage`. Default is 25.

With default 25 setting, Longhorn manager will allow scheduling new replicas only after the amount of disk space has been substracted from the available disk space(**Storage Available**) and the available disk space is still over 25% of actual disk capacity(**Storage Maximum**). Otherwise the disk becomes unschedulable until more space is freed up.

5. `Storage Over Provisioning Percentage`. Default is 200.

With default 200 setting, Longhorn manager will allow scheduling new replicas only after the amount of disk space has been added to the used disk space(**storage scheduled**), and the used disk space (**Storage Maximum** - **Storage Reserved**) is not over 200% of the actual usable disk capacity.
