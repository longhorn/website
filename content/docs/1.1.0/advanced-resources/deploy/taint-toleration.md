---
title: Taints and Tolerations
weight: 3
---

If users want to create nodes with large storage spaces and/or CPU resources for Longhorn only (to store replica data) and reject other general workloads, they can taint those nodes and add tolerations for Longhorn components. Then Longhorn can be deployed on those nodes.

Notice that the taint tolerations setting for one workload will not prevent it from being scheduled to the nodes that don't contain the corresponding taints.

For more information about how taints and tolerations work, refer to the [official Kubernetes documentation.](https://kubernetes.io/docs/concepts/configuration/taint-and-toleration/)

# Setting up Taints and Tolerations

### During installing Longhorn

Follow the instructions to set init taint tolerations: [Customize default settings](../customizing-default-settings/)

### After Longhorn has been installed

The taint toleration setting can be found at Longhorn UI under **Setting > General > Kubernetes Taint Toleration.**

Users can modify the existing tolerations or add more tolerations here, but noted that it will result in all the Longhorn system components to be recreated.

# Usage

Before modifying the toleration settings, users should make sure all Longhorn volumes are `detached`.

Since all Longhorn components will be restarted, the Longhorn system is unavailable temporarily. If there are running Longhorn volumes in the system, this means the Longhorn system cannot restart its components and the request will be rejected.

Don't operate the Longhorn system while toleration settings are updated and Longhorn components are being restarted.

When tolerations are set, the substring `kubernetes.io` shouldn't be contained in the setting. That substring is used as the key of Kubernetes default tolerations.

Multiple tolerations can be set here, and these tolerations are separated by the semicolon. For example: `key1=value1:NoSchedule; key2:NoExecute`.

## History
[Original feature request](https://github.com/longhorn/longhorn/issues/584)

Available since v0.6.0
