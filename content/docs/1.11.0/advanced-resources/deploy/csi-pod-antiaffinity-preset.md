---
title: CSI Component Pod Anti-Affinity
weight: 5
---

This document describes how to configure pod anti-affinity for Longhorn's CSI components. This feature enhances the resilience of the storage system, particularly in smaller clusters, by preventing multiple replicas of a CSI component from running on the same node and thereby avoiding a single point of failure.

For more information on pod anti-affinity, refer to the official Kubernetes documentation on [Inter-pod affinity and anti-affinity](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#inter-pod-affinity-and-anti-affinity).

## Configuring Pod Anti-Affinity for Longhorn CSI Components

You can configure the pod anti-affinity for the following Longhorn CSI components:

- `csi-attacher`
- `csi-provisioner`
- `csi-resizer`
- `csi-snapshotter`

The `podAntiAffinityPreset` setting has two available values:

- **`soft` (default)**: This is a "best-effort" rule using `preferredDuringSchedulingIgnoredDuringExecution`. The scheduler will try to prevent multiple CSI component replicas from running on the same node, but it is not guaranteed.
- **`hard`**: This is a "strict" rule using `requiredDuringSchedulingIgnoredDuringExecution`. The scheduler will not schedule a pod on a node if it violates the anti-affinity rule. This may result in pods remaining in a `Pending` state if no suitable nodes are available.

### During Longhorn Installation

You can set the pod anti-affinity for the CSI components during the initial installation of Longhorn using one of the following methods.

#### 1. Using Rancher

When installing Longhorn through Rancher, add the following parameters to the YAML on the Rancher UI (click Edit as YAML during the installation).

```yaml
csi:
    podAntiAffinityPreset: "hard"
```

#### 2. Using Helm

If installing with Helm, set the `csi.podAntiAffinityPreset` value in your `values.yaml` file, and then install the chart as usual.

#### 3. Using Kubectl

If installing Longhorn with `kubectl` and the deployment YAML, you must manually edit the `longhorn-driver-deployer` deployment. Add the following environment variable to the container specification:

```yaml
- name: CSI_POD_ANTIAFFINITY_PRESET
  value: hard
```

### After Longhorn has been installed

> **Warning**:
> * `longhorn-driver-deployer` and the CSI pods will be redeployed.

Manually edit the `longhorn-driver-deployer` deployment using `kubectl`. Add the following environment variable to the container specification:

```yaml
- name: CSI_POD_ANTIAFFINITY_PRESET
  value: hard
```

## History

-  [Original feature request](https://github.com/longhorn/longhorn/issues/11617)
