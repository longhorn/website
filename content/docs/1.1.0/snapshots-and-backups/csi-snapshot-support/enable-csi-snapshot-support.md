---
title: Enable CSI snapshot support on your cluster
description: Enable CSI snapshot support for programmatic creation of Longhorn backups
weight: 1
---

> **Prerequisite:**
> CSI snapshot support is available for kubernetes versions >= **1.17**.
> It is the responsibility of the kubernetes distribution to deploy the snapshot controller as well as the related custom resource definitions.
> For more information, see [CSI Volume Snapshots](https://kubernetes.io/docs/concepts/storage/volume-snapshots/).

#### Add default `VolumeSnapshotClass`
Ensure availability of the Snapshot Beta CRDs, afterwards create a default `VolumeSnapshotClass`.
```yaml
kind: VolumeSnapshotClass
apiVersion: snapshot.storage.k8s.io/v1beta1
metadata:
  name: longhorn
driver: driver.longhorn.io
deletionPolicy: Delete
```

#### If you are updating from a previous Longhorn version in an **airgap** environment
- update `csi-provisioner` image to `longhornio/csi-provisioner:v1.6.0`
- add `csi-snapshotter` image for `longhornio/csi-snapshotter:v2.1.1`

#### If your Kubernetes distribution **does not bundle** the snapshot controller
you may manually install these components by executing the following steps.
Note that the snapshot controller YAML files mentioned below deploy into the `default` namespace.
For general use, update the snapshot controller YAMLs with an appropriate **namespace** prior to installing.
For example, on a Vanilla Kubernetes cluster update the namespace from `default` to `kube-system` prior to issuing the kubectl create command.

Install Snapshot Beta CRDs:
1. Download the files from https://github.com/kubernetes-csi/external-snapshotter/tree/master/client/config/crd
2. kubectl create -f client/config/crd
3. Do this once per cluster

Install Common Snapshot Controller:
1. Download the files from https://github.com/kubernetes-csi/external-snapshotter/tree/master/deploy/kubernetes/snapshot-controller
2. Update the namespace to an appropriate value for your environment (e.g. kube-system)
3. kubectl create -f deploy/kubernetes/snapshot-controller
4. Do this once per cluster

See the [Usage](https://github.com/kubernetes-csi/external-snapshotter#usage) section from the kubernetes
external-snapshotter git repo for additional information.
