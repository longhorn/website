---
title: Node Selector
weight: 4
---

If you want to restrict Longhorn components to only run on a particular set of nodes, you can set node selector for all Longhorn components.
For example, you want to install Longhorn in a cluster that has both Linux nodes and Windows nodes but Longhorn cannot run on Windows nodes.
In this case, you can set the node selector to restrict Longhorn to only run on Linux nodes.

For more information about how node selector work, refer to the [official Kubernetes documentation.](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#nodeselector)

# Setting up Node Selector for Longhorn
Longhorn consists of user-deployed components (for example, Longhorn Manager, Longhorn Driver, and Longhorn UI) and system-managed components (for example, Instance Manager, Backing Image Manager, Share Manager, CSI Driver, and Engine Image).
You need to set node selector for both types of components. See more details below.

### Setting up Node Selector During installing Longhorn
1. Set the node selector for user-deployed components (for example, Longhorn Manager, Longhorn Driver, and Longhorn UI).
   * If you install Longhorn through Rancher, you must copy and paste the following parameters into the YAML on the Rancher UI (click **Edit as YAML** during the installation) to apply the value to all user-deployed components.
      ```yaml
        global:
          nodeSelector:
            label-key1: "label-value1"
      ```
   * You can also specify the node selector for each user-deployed component and it will orverride the global setting.
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
   * If you install Longhorn by using `kubectl` to apply [the deployment YAML](https://raw.githubusercontent.com/longhorn/longhorn/v{{< current-version >}}/deploy/longhorn.yaml), you need to modify the node selector section for Longhorn Manager, Longhorn UI, and Longhorn Driver Deployer.
    Then apply the YAMl files.
   * If you install Longhorn using Helm, you can change the Helm values for `global.nodeSelector`, `longhornManager.nodeSelector`, `longhornUI.nodeSelector`, `longhornDriver.nodeSelector` in the `values.yaml` file before installing the chart.

2. Set the node selector for system-managed components (for example, Instance Manager, Backing Image Manager, Share Manager, CSI Driver, and Engine Image).

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
> * When all Longhorn volumes are detached, the customized settings are immediately applied to the system-managed components (for example, Instance manager, CSI driver and Engine images).
> * When one or more Longhorn volumes are still attached, the customized setting is applied to the Instance Manager only when no engines and replica instances are running. You are required to reconfigure the setting after detaching the remaining volumes. Alternatively, you can wait for the next setting synchronization, which will occur in an hour.
> * Don't operate the Longhorn system while node selector settings are updated and Longhorn components are being restarted.

1. Prepare
   * To ensure that your preferred settings are immediately applied, stop all workloads and detach all Longhorn volumes before applying it.

2. Set the node selector for user-deployed components (for example, Longhorn Manager, Longhorn Driver, and Longhorn UI).
   * If you install Longhorn through Rancher, you must copy and paste the following parameters into the YAML on the Rancher UI (click **Edit as YAML** during the upgrade) to apply the value to all user-deployed components.
        ```yaml
        global:
          nodeSelector:
            label-key1: "label-value1"
        ```
    * You can also specify the node selector for each user-deployed component and it will override the global setting.
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
    * If you install Longhorn by using `kubectl` to apply [the deployment YAML](https://raw.githubusercontent.com/longhorn/longhorn/v{{< current-version >}}/deploy/longhorn.yaml), you need to modify the node selector section for Longhorn Manager, Longhorn UI, and Longhorn Driver Deployer.
      Then reapply the YAMl files.
    * If you install Longhorn using Helm, you can change the Helm values for `global.nodeSelector`, `longhornManager.nodeSelector`, `longhornUI.nodeSelector`, `longhornDriverDeployer.nodeSelector` in the `values.yaml` file, and then run `helm upgrade` to upgrade to the new version of the chart.

3. Set the node selector for system-managed components (for example, Instance Manager, Backing Image Manager, Share Manager, CSI Driver, and Engine Image).

   The node selector setting can be found at Longhorn UI under **Setting > General > System Managed Components Node Selector.**

4. Clean up

   If you are changing node selector in a way so that Longhorn cannot run on some nodes that Longhorn is currently running on,
   those nodes will become `down` state after this process. Verify that there is no replica left on those nodes.
   Disable scheduling for those nodes, and delete them in Longhorn UI

## History
Available since v1.1.1
* [Original feature request](https://github.com/longhorn/longhorn/issues/2199)
