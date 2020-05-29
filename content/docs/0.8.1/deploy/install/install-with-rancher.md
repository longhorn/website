---
title: Install as a Rancher Catalog App
description: Run Longhorn on Kubernetes with Rancher 2.x
weight: 7
---

One benefit of installing Longhorn through Rancher catalog is that Rancher provides authentication to the Longhorn UI.

If there is a new version of Longhorn available, you will see an `Upgrade Available` sign on the `Catalog Apps` screen. You can click `Upgrade` button to upgrade Longhorn manager. See more about upgrade [here](../../upgrade).

## Prerequisites

Each node in the Kubernetes cluster where Longhorn is installed must fulfill [these requirements.](../#installation-requirements)

[This script](https://github.com/longhorn/longhorn/blob/master/scripts/environment_check.sh) can be used to check the Longhorn environment for potential issues.
    
## Installation

1. Optional: We recommend creating a new project for Longhorn, for example, `Storage`.
2. Navigate to the cluster and project where you will install Longhorn. 
    {{< figure src="/img/screenshots/install/select-project.png" >}}
3. Navigate to the `Catalog Apps` screen.
    {{< figure src="/img/screenshots/install/apps-launch.png" >}}
4. Find the Longhorn item in the catalog and click it.
    {{< figure src="/img/screenshots/install/longhorn.png" >}}
5. Optional: Customize the default settings. 
6. Click **Launch.** Longhorn will be installed in the `longhorn-system` namespace.
    {{< figure src="/img/screenshots/install/launch-longhorn.png" >}}
    Longhorn is now installed.
    {{< figure src="/img/screenshots/install/installed-longhorn.png" >}}
7. Click the `index.html` link to navigate to the Longhorn dashboard.
    {{< figure src="/img/screenshots/install/dashboard.png" >}}

After Longhorn has been successfully installed, you can access the Longhorn UI by navigating to the `Catalog Apps` screen.
