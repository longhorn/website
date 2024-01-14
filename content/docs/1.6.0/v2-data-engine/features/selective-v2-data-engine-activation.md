---
title: Selective V2 Data Engine Activation
weight: 20
---

Starting from version 1.6.0, Longhorn provides the capability to enable or disable the V2 Data Engine on specified nodes within a cluster, in contrast to version 1.5, which activates the V2 Data Engine on all nodes. This feature is beneficial for clusters with a mix of powerful and low-powered nodes, as it allows you to only run V2 Data Engine on the more powerful nodes.

## Configuration

To disable V2 Data Engine on the specified nodes, you can use the following steps:

1. Identify the nodes that you want to disable V2 Data Engine.

2. Add the label `node.longhorn.io/disable-v2-data-engine: "true"` to the chosen Kubernetes nodes.

3. Activate the `v2-data-engine` setting globally. Then,
   - Instance-manager pods for V2 Data Engine are only spawned on nodes without the aforementioned label.
   - V2 Data Engine functionality remains available exclusively on nodes lacking the label.

## Notice

Please be aware that V2 volumes can only be created on nodes that enable the V2 Data Engine. Ensure to schedule workloads using v2 volumes on the nodes where V2 Data Engine is enabled.

## Reference

Please refer to [[FEATURE] Selective V2 Data Engine Activation](https://github.com/longhorn/longhorn/issues/7015) for more information.
