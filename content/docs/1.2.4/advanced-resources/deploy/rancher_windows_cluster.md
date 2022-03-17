---
title: Rancher Windows Cluster
weight: 5
---

In this document, you will learn about how to install Longhorn in a Rancher Windows cluster.

## The characteristic of Rancher Windows Cluster
Rancher has the ability to provision a cluster that has a mix of Linux worker nodes and Windows worker nodes.
For more information about Rancher Windows cluster, please refer to the [official Rancher documentation.](https://rancher.com/docs/rancher/v2.x/en/cluster-provisioning/rke-clusters/windows-clusters/)

In a Rancher Windows cluster, all Linux worker nodes are tainted with the taint `cattle.io/os=linux:NoSchedule` and have the label `kubernetes.io/os:linux`

## Steps to install Longhorn in a Rancher Windows Cluster
1. Since Longhorn components can only run on Linux nodes,
   you need to set node selector `kubernetes.io/os:linux` for Longhorn to select the Linux nodes.
   Please follow the instruction at [Node Selector](../node-selector) to set node selector for Longhorn.

1. Since all Linux worker nodes in Rancher Windows cluster are tainted with the taint `cattle.io/os=linux:NoSchedule`,
   You need to set the toleration `cattle.io/os=linux:NoSchedule` for Longhorn to be able to run on those nodes.
   Please follow the instruction at [Taint Toleration](../taint-toleration) to set toleration for Longhorn.

> **Note**: After Longhorn is deployed, you can launch workloads that use Longhorn volumes only on Linux nodes.
