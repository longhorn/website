---
title: Selective V2 Data Engine Activation
weight: 20
---

Starting with v1.6.0, Longhorn allows you to enable or disable the V2 Data Engine on specific cluster nodes. You can choose to enable the V2 Data Engine only on powerful nodes in a cluster with varied power states. This is not possible in v1.5.0, which enables the V2 Data Engine on all nodes.

## Disabling the V2 Data Engine on Specific Nodes

1. Identify the nodes that should not run the V2 Data Engine.

1. Add the label `node.longhorn.io/disable-v2-data-engine: "true"` to the selected nodes.

1. Enable the global setting `v2-data-engine`.

As a result, the following occur only on *nodes without the label*:
- Instance Manager pods for the V2 Data Engine are spawned.
- V2 Data Engine functionality remains available.

## Notice

Please be aware that V2 volumes can only be created on nodes that enable the V2 Data Engine. Ensure to schedule workloads using v2 volumes on the nodes where V2 Data Engine is enabled.

## Reference

For more information, see [[FEATURE] Selective V2 Data Engine Activation](https://github.com/longhorn/longhorn/issues/7015).
