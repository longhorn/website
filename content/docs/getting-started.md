---
title: Getting started
description: Run Longhorn in your local environment
weight: 2
---

{{< requirement title="Requirements" >}}
To run Longhorn on [Kubernetes](https://kubernetes.io):

1. [Docker](https://docker.com) v1.13+
1. [Kubernetes](https://kubernetes.io) v1.14+
1. [open-iscsi](https://github.com/open-iscsi/open-iscsi) has been installed on all the nodes in the Kubernetes cluster
    1. For [Google Kubernetes Engine](https://cloud.google.com/kubernetes-engine/), we recommend Ubuntu as the guest OS image since it already contains open-iscsi
    1. For Debian and Ubuntu, use `apt-get install open-iscsi` to install
    1. For RHEL/CentOS, use `yum install iscsi-initiator-utils` to install
1. A host filesystem that supports the `file extents` feature on the nodes to store the data. We currently support the following fileystems:
    * ext4
    * XFS
{{< /requirement >}}

