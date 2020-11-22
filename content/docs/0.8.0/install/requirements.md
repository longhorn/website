---
title: Installation Requirements
weight: 1
---

-  A container runtime compatible with Kubernetes (Docker v1.13+, containerd v1.3.7+, etc.)
-  Kubernetes v1.14+.
-  `open-iscsi` has been installed on all the nodes of the Kubernetes cluster, and `iscsid` daemon is running on all the nodes. This is necessary, since Longhorn relies on `iscsiadm` on the host to provide persistent volumes to Kubernetes.
    - For GKE, recommended Ubuntu as guest OS image since it contains open-iscsi already.
    - For Debian/Ubuntu, use `apt-get install open-iscsi` to install.
    - For RHEL/CentOS, use `yum install iscsi-initiator-utils` to install.
    - For EKS with `EKS Kubernetes Worker AMI with AmazonLinux2 image`,
       use `yum install iscsi-initiator-utils` to install. You may need to edit cluster security group to allow ssh access.
- A host filesystem supports `file extents` feature on the nodes to store the data. Currently we support:
    - ext4
    - XFS
