---
title: Evicting Replicas on Disabled Disks or Nodes
weight: 5
---

Longhorn supports auto eviction for evicting the replicas on the selected disabled disks or nodes to other suitable disks and nodes. Meanwhile the same level of high availability is maintained during the eviction.

> **Note:** This eviction feature can only be enabled when the selected disks or nodes have scheduling disabled. And during the eviction time, the selected disks or nodes cannot be re-enabled for scheduling.

> **Note:** This eviction feature works for volumes that are `Attached` and `Detached`. If the volume is 'Detached', Longhorn will automatically attach it before the eviction and automatically detach it once eviction is done.

By default, `Eviction Requested` for disks or nodes is `false`. And to keep the same level of high availability during the eviction, Longhorn only evicts a replica per volume after the replica rebuild for this volume is a success.

## Select Disks or Nodes for Eviction

To evict disks for a node,

1. Head to the `Node` tab, select one of the nodes, and select `Edit Node and Disks` in the dropdown menu.
1. Make sure the disk is disabled for scheduling and set `Scheduling` to `Disable`.
2. Set `Eviction Requested` to `true` and save.

To evict a node,

1. Head to the `Node` tab, select one or more nodes, and click `Edit Node`.
1. Make sure the node is disabled for scheduling and set `Scheduling` to `Disable`.
2. Set `Eviction Requested` to `true`, and save.

## Cancel Disks or Nodes Eviction

To cancel the eviction for a disk or a node, set the corresponding `Eviction Requested` setting to `false`.

## Check Eviction Status

The `Replicas` number on the selected disks or nodes should be reduced to 0 once the eviction is a success.

If you click on the `Replicas` number, it will show the replica name on this disk. When you click on the replica name, the Longhorn UI will redirect the webpage to the corresponding volume page, and it will display the volume status. If there is any error, e.g. no space, or couldn't find another schedulable disk (schedule failure), the error will be shown. All of the errors will be logged in the Event log.

If any error happened during the eviction, the eviction will be suspended until new space has been cleared or it will be cancelled. And if the eviction is cancelled, the remaining replicas on the selected disks or nodes will remain on the disks or nodes.
