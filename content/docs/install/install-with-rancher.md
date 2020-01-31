---
title: Install Longhorn with the Rancher UI
description: Run Longhorn on Kubernetes with Rancher 2.x
weight: 7
---

## Prerequisites

1. Rancher v2.1+
2. Docker v1.13+
3. Kubernetes v1.8+ cluster with 1 or more nodes and Mount Propagation feature enabled. If your Kubernetes cluster was provisioned by Rancher v2.0.7+ or later, MountPropagation feature is enabled by default. [Check your Kubernetes environment now](https://github.com/rancher/longhorn#environment-check-script). If MountPropagation is disabled, the Kubernetes Flexvolume driver will be deployed instead of the default CSI driver. Base Image feature will also be disabled if MountPropagation is disabled.
4. Make sure `curl`, `findmnt`, `grep`, `awk` and `blkid` has been installed in all nodes of the Kubernetes cluster.
5. Make sure `open-iscsi` has been installed in all nodes of the Kubernetes cluster. For GKE, recommended Ubuntu as guest OS image since it contains `open-iscsi` already.

## Installation

1. Navigate to the Cluster and Project where you will install Longhorn
{{< figure src="/img/screenshots/install/select-project.png" >}}
2. Navigate to Apps
3. Click the Launch Button
{{< figure src="/img/screenshots/install/apps-launch.png" >}}
4. Find the Longhorn item in the catalog and click it.
{{< figure src="/img/screenshots/install/longhorn.png" >}}
5. You can leave the defaults for now.
6. Click Launch 
{{< figure src="/img/screenshots/install/launch-longhorn.png" >}}
7. Longhorn is now installed.
{{< figure src="/img/screenshots/install/installed-longhorn.png" >}}
8. Click the index.html link to navigate to the Longhorn dashboard.
{{< figure src="/img/screenshots/install/dashboard.png" >}}
