---
title: Disks or Nodes Eviction Support
weight: 5
---

Longhorn supports auto eviction for evicting the replicas on the selected disabled disks or nodes to other suitable disks and nodes. Meanwhile keep the same level of high availability during this eviction period of time.

> **Note:** This eviction feature can only be enabled when the selected disks or nodes are scheduling disabled. And during the eviction time, the selected disks or nodes can not be re-enabled for scheduling.

> **Note:** This eviction feature works for volumes that are `Attached` and `Detached`. If the volume is 'Detached', Longhorn will automatically attach it before the eviction and automatically detach it once eviction is done.

By default, `Eviction Requested` for disks or nodes are `false`. And to keep the same level of high availability during the eviction, Longhorn only evict a replica per volume after the replica rebuild on this volume is success.

## Select disks or nodes for eviction

To evict disks for a node, heading to `Node` tab, select one of the node, and select `Edit Node and Disks` in the drop down menu.

1. Make sure the disk is disabled for scheduling or set `Scheduling` to `Disable`.
2. Set `Eviction Requested` to `true`, and save.

To evict a node, heading to `Node` tab, select one or more nodes. And click `Edit Node`.
1. Make sure the node is disabled for scheduling or set `Scheduling` to `Disable`.
2. Set `Eviction Requested` to `true`, and save.

## Cancel disks or nodes eviction

To cancel the eviction for a disk or a node, set corresponding `Eviction Requested` to `false`.

## Check eviction status

On a positive case, the `Replicas` number on the selected disks or nodes should be reduced to 0 once the eviction is success.

Also click on the `Replicas` number, it will show the replica name on this disk and click on the replica name, Longhorn UI will redirect the webpage to the corresponding volume page, and it will display the volume status. If there is any error. E.g. no space or couldn't find other schedulable disk (schedule failure) will be shown. And all the errors will be logged in the `Event log`.

If any error happened during the eviction. E.g. no space or couldn't find schedulable disk for the new replica, the eviction will suspend until new space has been clear for or be cancelled. And if the eviction is cancelled, the remaining replicas on the selected disks or nodes will remain on the disks or nodes.
