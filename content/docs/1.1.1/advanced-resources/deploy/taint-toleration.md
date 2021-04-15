---
title: Taints and Tolerations
weight: 3
---

If users want to create nodes with large storage spaces and/or CPU resources for Longhorn only (to store replica data) and reject other general workloads, they can taint those nodes and add tolerations for Longhorn components. Then Longhorn can be deployed on those nodes.

Notice that the taint tolerations setting for one workload will not prevent it from being scheduled to the nodes that don't contain the corresponding taints.

For more information about how taints and tolerations work, refer to the [official Kubernetes documentation.](https://kubernetes.io/docs/concepts/configuration/taint-and-toleration/)

# Setting up Taints and Tolerations
Longhorn system contains user deployed components (e.g, Manager, Driver Deployer, UI) and system managed components (e.g, Instance Manager, Engine Image, CSI Driver, etc.)
You need to set tolerations for both types of components. See more details below.

### Setting up Taints and Tolerations During installing Longhorn
1. Set taint tolerations for user deployed components (Manager, UI, Driver Deployer)
   * If you install Longhorn by Rancher 2.5.x, you need to click `Edit as YAML` in Rancher UI and copy this values into the YAML:
     ```yaml
       longhornManager:
         tolerations:
         - key: "key"
           operator: "Equal"
           value: "value"
           effect: "NoSchedule"
       longhornDriver:
         tolerations:
         - key: "key"
           operator: "Equal"
           value: "value"
           effect: "NoSchedule"
       longhornUI:
         tolerations:
         - key: "key"
           operator: "Equal"
           value: "value"
           effect: "NoSchedule"
     ```
   * If you install Longhorn by using `kubectl` to apply [the deployment YAML](https://raw.githubusercontent.com/longhorn/longhorn/v1.1.1/deploy/longhorn.yaml), you need to modify the taint tolerations section for Longhorn Manager, Longhorn UI, and Longhorn Driver Deployer.
    Then apply the YAMl files.
   * If you install Longhorn using Helm, you can change the Helm values for `longhornManager.tolerations`, `longhornUI.tolerations`, `longhornDriver.tolerations` in the `values.yaml` file.
    Then install the chart

2. Set taint tolerations for system managed components

   Follow the [Customize default settings](../customizing-default-settings/) to set taint tolerations by changing the value for the `taint-toleratio` default setting
   > Note: Because of the limitation of Rancher 2.5.x, if you are using Rancher UI to install Longhorn, you need to click `Edit As Yaml` and add setting `taintToleration` to `defaultSettings`.
   >
   > For example:
   > ```yaml
   > defaultSettings:
   >   taintToleration: "key=value:NoSchedule"
   >  ```

### Setting up Taints and Tolerations After Longhorn has been installed

> **Warning**:
>
> Before modifying the toleration settings, users should make sure all Longhorn volumes are `detached`.
>
> Since all Longhorn components will be restarted, the Longhorn system is unavailable temporarily.
> If there are running Longhorn volumes in the system, this means the Longhorn system cannot restart its components and the request will be rejected.
>
> Don't operate the Longhorn system while toleration settings are updated and Longhorn components are being restarted.

1. Prepare

   Stop all workloads and detach all Longhorn volumes. Make sure all Longhorn volumes are `detached`.

2. Set taint tolerations for user deployed components (Manager, UI, Driver Deployer)
   * If you install Longhorn by Rancher 2.5.x, you need to click `Edit as YAML` in Rancher UI and copy this values into the YAML:
     ```yaml
       longhornManager:
         tolerations:
         - key: "key"
           operator: "Equal"
           value: "value"
           effect: "NoSchedule"
       longhornDriver:
         tolerations:
         - key: "key"
           operator: "Equal"
           value: "value"
           effect: "NoSchedule"
       longhornUI:
         tolerations:
         - key: "key"
           operator: "Equal"
           value: "value"
           effect: "NoSchedule"
     ```
   * If you install Longhorn by using `kubectl` to apply [the deployment YAML](https://raw.githubusercontent.com/longhorn/longhorn/v1.1.1/deploy/longhorn.yaml), you need to modify the taint tolerations section for Longhorn Manager, Longhorn UI, and Longhorn Driver Deployer.
  Then reapply the YAMl files.
   * If you install Longhorn using Helm, you can change the Helm values for `longhornManager.tolerations`, `longhornUI.tolerations`, `longhornDriver.tolerations` in the `values.yaml` file.
  Then do Helm upgrade the chart.

3. Set taint tolerations for system managed components

   The taint toleration setting can be found at Longhorn UI under **Setting > General > Kubernetes Taint Toleration.**


## History
Available since v0.6.0
* [Original feature request](https://github.com/longhorn/longhorn/issues/584)
* [Resolve the problem with GitOps](https://github.com/longhorn/longhorn/issues/2120)


