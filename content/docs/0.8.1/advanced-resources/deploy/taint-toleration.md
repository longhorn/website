---
title: Taints and Tolerations
weight: 3
---

It can be useful to add taints and tolerations to the nodes in the Kubernetes cluster where Longhorn is installed, if you would like to dedicate nodes for Longhorn only.

You might want to dedicate nodes to Longhorn if you want to have nodes with large storage spaces and/or CPU resources to store replica data, and reject other general workloads from running on these nodes.

In such a situation, the Longhorn nodes should be tainted and tolerations should be added for Longhorn components. Then Longhorn can be deployed on those nodes.

Note that the taint/tolerations settings for one workload will not prevent it from being scheduled to the nodes that don't contain the corresponding taints.

For more information about how taints and tolerations work, refer to the [official Kubernetes documentation.](https://kubernetes.io/docs/concepts/configuration/taint-and-toleration/)

### Setting up Tolerations During Longhorn Installation

To set the initial taintTolerations for Longhorn components, refer to the section about [customizing default settings.](../customizing-default-settings)

### Setting up Tolerations After Longhorn Installation

The tolerations for Longhorn components can be updated in the **Settings** tab in the Longhorn UI.

Changing the tolerations from the Longhorn settings will result in all of the Longhorn system components to be recreated. Therefore, the Longhorn system will be unavailable temporarily.

> **Prerequisite:** Before modifying the toleration settings, make sure all Longhorn volumes are detached. If Longhorn volumes are running in the system, the Longhorn system cannot restart its components and the request will be rejected.

To change the taint/toleration settings for Longhorn,

1. In the Longhorn UI, click the **Setting** tab.
2. In the **Kubernetes Taint Toleration** field, enter new tolerations, or modify existing tolerations. Multiple tolerations can be set here, and these tolerations are separated by semicolon. For example, "key1=value1:NoSchedule; key2:NoExecute". Note that "kubernetes.io" is used as the key of all Kubernetes default tolerations, so this substring should not be included in your tolerations.


**Result:** The Longhorn components are restarted with the added or modified tolerations.

Don't operate the Longhorn system while toleration settings are updated and Longhorn components are being restarted.

## History
[Original feature request](https://github.com/longhorn/longhorn/issues/584)

Available since v0.6.0