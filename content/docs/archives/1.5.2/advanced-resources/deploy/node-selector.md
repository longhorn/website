---
title: Node Selector
weight: 4
---

If you want to restrict Longhorn components to only run on a particular set of nodes, you can set node selector for all Longhorn components.
For example, you want to install Longhorn in a cluster that has both Linux nodes and Windows nodes but Longhorn cannot run on Windows nodes.
In this case, you can set the node selector to restrict Longhorn to only run on Linux nodes.

For more information about how node selector work, refer to the [official Kubernetes documentation.](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#nodeselector)

# Setting up Node Selector for Longhorn
Longhorn system contains user deployed components (e.g, Manager, Driver Deployer, UI) and system managed components (e.g, Instance Manager, Engine Image, CSI Driver, etc.)
You need to set node selector for both types of components. See more details below.

### Setting up Node Selector During installing Longhorn
1. Set node selector for user deployed components (Manager, UI, Driver Deployer)
   * If you install Longhorn by Rancher 2.5.x, you need to click `Edit as YAML` in Rancher UI and copy this values into the YAML:
      ```yaml
        longhornManager:
          nodeSelector:
            label-key1: "label-value1"
        longhornDriver:
          nodeSelector:
            label-key1: "label-value1"
        longhornUI:
          nodeSelector:
            label-key1: "label-value1"
      ```
   * If you install Longhorn by using `kubectl` to apply [the deployment YAML](https://raw.githubusercontent.com/longhorn/longhorn/v1.1.1/deploy/longhorn.yaml), you need to modify the node selector section for Longhorn Manager, Longhorn UI, and Longhorn Driver Deployer.
    Then apply the YAMl files.
   * If you install Longhorn using Helm, you can change the Helm values for `longhornManager.nodeSelector`, `longhornUI.nodeSelector`, `longhornDriver.nodeSelector` in the `values.yaml` file.
    Then install the chart

2. Set node selector for system managed components

   Follow the [Customize default settings](../customizing-default-settings/) to set node selector by changing the value for the `system-managed-components-node-selector` default setting
   > Note: Because of the limitation of Rancher 2.5.x, if you are using Rancher UI to install Longhorn, you need to click `Edit As Yaml` and add setting `systemManagedComponentsNodeSelector` to `defaultSettings`.
   >
   > For example:
   > ```yaml
   > defaultSettings:
   >   systemManagedComponentsNodeSelector: "label-key1:label-value1"
   >  ```


### Setting up Node Selector After Longhorn has been installed

> **Warning**:
> * Since all Longhorn components will be restarted, the Longhorn system is unavailable temporarily.
> * Make sure all Longhorn volumes are `detached`. If there are running Longhorn volumes in the system, this means the Longhorn system cannot restart its components and the request will be rejected.
> * Don't operate the Longhorn system while node selector settings are updated and Longhorn components are being restarted.

1. Prepare
   * If you are changing node selector in a way so that Longhorn cannot run on some nodes that Longhorn is currently running on,
     you will lose the volume replicas on those nodes.
     Therefore, It is recommended that you evict replicas and disable scheduling for those nodes before changing node selector.
     See [Evicting Replicas on Disabled Disks or Nodes](../../../volumes-and-nodes/disks-or-nodes-eviction) for more details about how to do this.
   * Stop all workloads and detach all Longhorn volumes. Make sure all Longhorn volumes are `detached`.

2. Set node selector for user deployed components
    * If you install Longhorn by Rancher UI, you need to click `Edit as YAML` and copy this values into the YAML then click upgrade:
        ```yaml
        longhornManager:
          nodeSelector:
            label-key1: "label-value1"
        longhornDriver:
          nodeSelector:
            label-key1: "label-value1"
        longhornUI:
          nodeSelector:
            label-key1: "label-value1"
        ```
    * If you install Longhorn by using `kubectl` to apply [the deployment YAML](https://raw.githubusercontent.com/longhorn/longhorn/v1.1.1/deploy/longhorn.yaml), you need to modify the node selector section for Longhorn Manager, Longhorn UI, and Longhorn Driver Deployer.
      Then reapply the YAMl files.
    * If you install Longhorn using Helm, you can change the Helm values for `longhornManager.nodeSelector`, `longhornUI.nodeSelector`, `longhornDriverDeployer.nodeSelector` in the `value.yaml` file.
      Then do Helm upgrade the chart.

3. Set node selector for system managed components

   The node selector setting can be found at Longhorn UI under **Setting > General > System Managed Components Node Selector.**

4. Clean up

   If you are changing node selector in a way so that Longhorn cannot run on some nodes that Longhorn is currently running on,
   those nodes will become `down` state after this process. Verify that there is no replica left on those nodes.
   Disable scheduling for those nodes, and delete them in Longhorn UI

## History
Available since v1.1.1
* [Original feature request](https://github.com/longhorn/longhorn/issues/2199)


