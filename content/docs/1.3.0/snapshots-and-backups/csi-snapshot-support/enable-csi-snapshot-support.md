---
title: Enable CSI Snapshot Support on a Cluster
description: Enable CSI Snapshot Support for Programmatic Creation of Longhorn Snapshots/Backups
weight: 1
---

> **Prerequisite**
>
> It is the responsibility of the Kubernetes distribution to deploy the snapshot controller as well as the related custom resource definitions.
>
> For more information, see [CSI Volume Snapshots](https://kubernetes.io/docs/concepts/storage/volume-snapshots/).

#### If your Kubernetes Distribution Does Not Bundle the Snapshot Controller

You may manually install these components by executing the following steps.

Note that the snapshot controller YAML files mentioned below deploy into the `default` namespace.

> **Prerequisite**
>
> Please install the same release version of snapshot CRDs and snapshot controller to ensure that the CRD version is compatible with the snapshot controller.
>
> For general use, update the snapshot controller YAMLs with an appropriate **namespace** prior to installing.
>
> For example, on a vanilla Kubernetes cluster, update the namespace from `default` to `kube-system` prior to issuing the `kubectl create` command.

Install the Snapshot CRDs:
1. Download the files from https://github.com/kubernetes-csi/external-snapshotter/tree/release-4.0/client/config/crd
2. Run `kubectl create -f client/config/crd`.
3. Do this once per cluster.

Install the Common Snapshot Controller:
1. Download the files from https://github.com/kubernetes-csi/external-snapshotter/tree/release-4.0/deploy/kubernetes/snapshot-controller
2. Update the namespace to an appropriate value for your environment (e.g. `kube-system`)
3. Run `kubectl create -f deploy/kubernetes/snapshot-controller`.
3. Do this once per cluster.

See the [Usage](https://github.com/kubernetes-csi/external-snapshotter#usage) section from the kubernetes
external-snapshotter git repo for additional information.

#### Add a Default `VolumeSnapshotClass`
Ensure the availability of the Snapshot CRDs. Afterwards create a default `VolumeSnapshotClass`.
```yaml
# Use v1 as an example
kind: VolumeSnapshotClass
apiVersion: snapshot.storage.k8s.io/v1
metadata:
  name: longhorn
driver: driver.longhorn.io
deletionPolicy: Delete
```
