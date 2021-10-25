---
title: Install as a Rancher Catalog App
description: Run Longhorn on Kubernetes with Rancher 2.x
weight: 7
---

One benefit of installing Longhorn through Rancher catalog is that Rancher provides authentication to the Longhorn UI.

If there is a new version of Longhorn available, you will see an `Upgrade Available` sign on the `Apps & Marketplace` screen. You can click `Upgrade` button to upgrade Longhorn manager. See more about upgrade [here](../../upgrade).

## Prerequisites

Each node in the Kubernetes cluster where Longhorn is installed must fulfill [these requirements.](../#installation-requirements)

[This script](https://github.com/longhorn/longhorn/blob/v{{< current-version >}}/scripts/environment_check.sh) can be used to check the Longhorn environment for potential issues.
    
## Installation

1. Optional: If Rancher version is 2.5.9 or before, we recommend creating a new project for Longhorn, for example, `Storage`.
2. Navigate to the cluster where you will install Longhorn. 
    {{< figure src="/img/screenshots/install/rancher-2.6/select-project.png" >}}
3. Navigate to the `Apps & Marketplace` screen.
    {{< figure src="/img/screenshots/install/rancher-2.6/apps-launch.png" >}}
4. Find the Longhorn item in the charts and click it.
    {{< figure src="/img/screenshots/install/rancher-2.6/longhorn.png" >}}
5. Click **Install**.
    {{< figure src="/img/screenshots/install/rancher-2.6/longhorn-chart.png" >}}
6. Optional: Select the project where you want to install Longhorn.
7. Optional: Customize the default settings.
    {{< figure src="/img/screenshots/install/rancher-2.6/launch-longhorn.png" >}}
8. Click Next. Longhorn will be installed in the longhorn-system namespace.    
    {{< figure src="/img/screenshots/install/rancher-2.6/installed-longhorn.png" >}}
9. Click the Longhorn App Icon to navigate to the Longhorn dashboard.
    {{< figure src="/img/screenshots/install/rancher-2.6/dashboard.png" >}}

After Longhorn has been successfully installed, you can access the Longhorn UI by navigating to the `Longhorn` option from Rancher left panel.
