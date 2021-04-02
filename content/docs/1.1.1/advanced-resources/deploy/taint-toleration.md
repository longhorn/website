---
title: Taints and Tolerations
weight: 3
---

If users want to create nodes with large storage spaces and/or CPU resources for Longhorn only (to store replica data) and reject other general workloads, they can taint those nodes and add tolerations for Longhorn components. Then Longhorn can be deployed on those nodes.

Notice that the taint tolerations setting for one workload will not prevent it from being scheduled to the nodes that don't contain the corresponding taints.

For more information about how taints and tolerations work, refer to the [official Kubernetes documentation.](https://kubernetes.io/docs/concepts/configuration/taint-and-toleration/)

# Setting up Taints and Tolerations
Longhorn system contains user deployed components (e.g, Longhorn manager, Longhorn driver, Longhorn UI) and system managed components (e.g, instance manager, engine image, CSI driver, etc.)
You need to set tolerations for both types of components. See more details below.

### Setting up Taints and Tolerations During installing Longhorn

1. Set taint tolerations for system managed components: follow the [Customize default settings](../customizing-default-settings/) to set taint tolerations by changing the value for the `taint-toleration` default setting
1. Set taint tolerations for user deployed components: modify the Helm chart or deployment YAML file depending on how you deploy Longhorn.

### Setting up Taints and Tolerations After Longhorn has been installed

1. Set taint tolerations for system managed components:
   the taint toleration setting can be found at Longhorn UI under **Setting > General > Kubernetes Taint Toleration.**

1. Set taint tolerations for user deployed components:
   modify the Helm chart or deployment YAML file depending on how you deploy Longhorn.
   Then, do Helm upgrade or reapply the YAMl files.

# Usage

Before modifying the toleration settings, users should make sure all Longhorn volumes are `detached`.

Since all Longhorn components will be restarted, the Longhorn system is unavailable temporarily. If there are running Longhorn volumes in the system, this means the Longhorn system cannot restart its components and the request will be rejected.

Don't operate the Longhorn system while toleration settings are updated and Longhorn components are being restarted.

Multiple tolerations can be set here, and these tolerations are separated by the semicolon.
For example:
* `key1=value1:NoSchedule; key2:NoExecute`
* `:` this toleration tolerates everything because an empty key with operator `Exists` matches all keys, values and effects
* `key1=value1:`  this toleration has empty effect. It matches all effects with key `key1`
## History
Available since v0.6.0
* [Original feature request](https://github.com/longhorn/longhorn/issues/584)
* [Resolve the problem with GitOps](https://github.com/longhorn/longhorn/issues/2120)


