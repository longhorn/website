---
title: Install Longhorn with the Rancher UI
description: Run Longhorn on Kubernetes with Rancher 2.x
weight: 7
---

One benefit of installing Longhorn through Rancher catalog is Rancher provides authentication to Longhorn UI.

If there is a new version of Longhorn available, you will see an `Upgrade Available` sign on the `Catalog Apps` screen. You can click `Upgrade` button to upgrade Longhorn manager. See more about upgrade [here](../upgrades).

## Prerequisites

1. Rancher v2.1+
2. A container runtime compatible with Kubernetes (Docker v1.13+, containerd v1.3.7+, etc.)
3. Kubernetes v1.14+ cluster with 1 or more nodes and Mount Propagation feature enabled. If your Kubernetes cluster was provisioned by Rancher v2.0.7+ or later, MountPropagation feature is enabled by default. [Check your Kubernetes environment now](https://github.com/longhorn/longhorn/#environment-check-script). If MountPropagation is disabled, the Base Image feature will be disabled.
4. Make sure `curl`, `findmnt`, `grep`, `awk` and `blkid` has been installed in all nodes of the Kubernetes cluster.
5.  `open-iscsi` has been installed on all the nodes of the Kubernetes cluster, and `iscsid` daemon is running on all the nodes.
    1. For GKE, recommended Ubuntu as guest OS image since it contains open-iscsi already.
    2. For Debian/Ubuntu, use `apt-get install open-iscsi` to install.
    3. For RHEL/CentOS, use `yum install iscsi-initiator-utils` to install.
    4. For EKS with `EKS Kubernetes Worker AMI with AmazonLinux2 image`, 
       use `yum install iscsi-initiator-utils` to install. You may need to edit cluster security group to allow ssh access.
6. A host filesystem supports `file extents` feature on the nodes to store the data. Currently we support:
    1. ext4
    2. XFS
    
## Installation

1. Navigate to the Cluster and Project where you will install Longhorn. We recommended to create a new project e.g. `Storage` for Longhorn.
{{< figure src="/img/screenshots/install/select-project.png" >}}
2. Navigate to the `Catalog Apps` screen.
{{< figure src="/img/screenshots/install/apps-launch.png" >}}
4. Find the Longhorn item in the catalog and click it.
{{< figure src="/img/screenshots/install/longhorn.png" >}}
5. You can leave the defaults for now.
6. Click Launch. Longhorn will be installed in the `longhorn-system` namespace.
{{< figure src="/img/screenshots/install/launch-longhorn.png" >}}
7. Longhorn is now installed.
{{< figure src="/img/screenshots/install/installed-longhorn.png" >}}
8. Click the index.html link to navigate to the Longhorn dashboard.
{{< figure src="/img/screenshots/install/dashboard.png" >}}

After Longhorn has been successfully installed, you can access the Longhorn UI by navigating to the `Catalog Apps` screen.
