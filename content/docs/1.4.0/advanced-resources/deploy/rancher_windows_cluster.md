---
title: Rancher Windows Cluster
weight: 5
---

Rancher can provision a Windows cluster with combination of Linux worker nodes and Windows worker nodes.
For more information on the Rancher Windows cluster, see the official [Rancher documentation](https://rancher.com/docs/rancher/v2.x/en/cluster-provisioning/rke-clusters/windows-clusters/).

In a Rancher Windows cluster, all Linux worker nodes are:
- Tainted with the taint `cattle.io/os=linux:NoSchedule`
- Labeled with `kubernetes.io/os:linux`

Follow the below [Deploy Longhorn With Supported Helm Chart](#deploy-longhorn-with-supported-helm-chart) or [Setup Longhorn Components For Existing Longhorn](#setup-longhorn-components-for-existing-longhorn) to know how to deploy or setup Longhorn on a Rancher Windows cluster.

> **Note**: After Longhorn is deployed, you can launch workloads that use Longhorn volumes only on Linux nodes.

## Deploy Longhorn With Supported Helm Chart
You can update the Helm value `global.cattle.windowsCluster.enabled` to allow Longhorn installation on the Rancher Windows cluster.

When this value is set to `true`, Longhorn will recognize the Rancher Windows cluster then deploy Longhorn components with the correct node selector and tolerations so that all Longhorn workloads can be launched on Linux nodes only.

On the Rancher marketplace, the setting can be customized in `customize Helm options` before installation: \
`Edit Options` > `Other Settings` > `Rancher Windows Cluster`

Also in: \
`Edit YAML`
```
global:
  cattle:
    systemDefaultRegistry: ""
    windowsCluster:
      # Enable this to allow Longhorn to run on the Rancher deployed Windows cluster
      enabled: true
```

## Setup Longhorn Components For Existing Longhorn
You can setup the existing Longhorn when its not deployed with the supported Helm chart.

1. Since Longhorn components can only run on Linux nodes,
   you need to set node selector `kubernetes.io/os:linux` for Longhorn to select the Linux nodes.
   Please follow the instruction at [Node Selector](../node-selector) to set node selector for Longhorn.

1. Since all Linux worker nodes in Rancher Windows cluster are tainted with the taint `cattle.io/os=linux:NoSchedule`,
   You need to set the toleration `cattle.io/os=linux:NoSchedule` for Longhorn to be able to run on those nodes.
   Please follow the instruction at [Taint Toleration](../taint-toleration) to set toleration for Longhorn.
