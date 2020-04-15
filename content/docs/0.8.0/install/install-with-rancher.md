---
title: Install Longhorn with the Rancher UI
description: Run Longhorn on Kubernetes with Rancher 2.x
weight: 7
---

## Prerequisites

1. Rancher v2.1+
2. Docker v1.13+
3. Kubernetes v1.14+ cluster with 1 or more nodes and Mount Propagation feature enabled. If your Kubernetes cluster was provisioned by Rancher v2.0.7+ or later, MountPropagation feature is enabled by default. [Check your Kubernetes environment now](https://github.com/rancher/longhorn#environment-check-script). If MountPropagation is disabled, the Kubernetes Flexvolume driver will be deployed instead of the default CSI driver. Base Image feature will also be disabled if MountPropagation is disabled.
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
