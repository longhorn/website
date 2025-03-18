---
title: Priority Class
weight: 6
---
The Priority Class setting can be used to set a higher priority on Longhorn workloads in the cluster, preventing them from being the first to be evicted during node pressure situations.

For more information on how pod priority works, refer to the [official Kubernetes documentation](https://kubernetes.io/docs/concepts/configuration/pod-priority-preemption/).

# Setting Priority Class

Longhorn consists of user-deployed components (for example, Longhorn Manager, Longhorn Driver, and Longhorn UI) and system-managed components (for example, Instance Manager, CSI Driver, and Engine images).
You need to set Priority Class for both types of components. See more details below.

### Setting Priority Class During Longhorn Installation

Longhorn creates a Priority Class `longhorn-critical` and sets it as default for its user deployed or system managed components if the following actions are not taken.

1. Set taint Priority Class for system managed components: follow the [Customize default settings](../customizing-default-settings/) to set Priority Class by changing the value for the `priority-class` default setting
1. Set taint Priority Class for user deployed components: modify the Helm chart or deployment YAML file depending on how you deploy Longhorn.

> **Warning:** Longhorn will not start if the Priority Class setting is invalid (such as the Priority Class not existing).
> You can see if this is the case by checking the status of the longhorn-manager DaemonSet with `kubectl -n longhorn-system describe daemonset.apps/longhorn-manager`.
> You will need to uninstall Longhorn and restart the installation if this is the case.

### Setting Priority Class After Longhorn Installation

1. Set taint Priority Class for system managed components: The Priority Class setting can be found in the Longhorn UI by clicking **Setting > General > Priority Class.**
1. Set taint Priority Class for user deployed components: modify the Helm chart or deployment YAML file depending on how you deploy Longhorn.

Users can update or remove the Priority Class here, but note that this will result in recreation of all the Longhorn system components.
The Priority Class setting will reject values that appear to be invalid Priority Classes.

# Usage

To ensure that your preferred Priority Class settings are immediately applied, stop all workloads and detach all Longhorn volumes before configuring the settings.

Longhorn temporarily becomes unavailable when all components are restarted.
Don't operate the Longhorn system after modifying the Priority Class setting, as the Longhorn components will be restarting.

When all Longhorn volumes are detached, the customized setting is immediately applied to the system-managed components.
When one or more Longhorn volumes are still attached, the customized setting is applied to the Instance Manager only when no engines and replica instances are running. You are required to reconfigure the setting after detaching the remaining volumes. Alternatively, you can wait for the next setting synchronization, which will occur in an hour.

Do not delete the Priority Class in use by Longhorn, as this can cause new Longhorn workloads to fail to come online.

## History

[Original Feature Request](https://github.com/longhorn/longhorn/issues/1487)

Available since v1.0.1
