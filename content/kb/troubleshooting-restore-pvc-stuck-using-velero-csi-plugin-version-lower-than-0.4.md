---
title: "Troubleshooting: Velero restores Longhorn PersistentVolumeClaim stuck in the Pending state when using the Velero CSI Plugin version before v0.4.0"
author: Ray Chang
draft: false
date: 2022-12-15
categories:
  - "restore"
---

## Applicable versions

All Longhorn versions.

## Symptoms

PersistentVolumeClaim is stuck in the `Pending` state when restoring Longhorn with Velero with Velero CSI Plugin version before v0.4.0.

## Reason

For Longhorn versions using `longhornio/csi-provisioner:v2.1.2`, when it processes a PVC to provision the volume, Longhorn CSI provisioner will only recognize the `volume.beta.kubernetes.io/storage-provisioner` annotation which will be tagged together with `volume.kubernetes.io/storage-provisioner` to each PVC via Kubernetes after determining the storage provisioner. The PVC with these annotations will be backed up together via Velero.

After restoring the PVC via Velero with its CSI plugin (< 0.4), it will only remove the `volume.beta.kubernetes.io/storage-provisioner` but keep the `volume.kubernetes.io/storage-provisioner` annotation intact from the PVC, because the plugin doesn't respect the general available `volume.kubernetes.io/storage-provisioner` annotation. Because Kubernetes will not add `volume.kubernetes.io/storage-provisioner` to the PVC which already has the beta annotation, it will cause the restoring PVC will be failed to be processed by the built-in Longhorn CSI provisioner and be stuck in the `Pending` state.

This compatibility issue is caused by the Velero CSI plugin and it has been fixed in the following versions, so since the 0.4 version, all annotations will be respected to ensure the corresponding volume provision is correct.

## Solution

It is recommended to use the Velero CSI plugin version >= 0.4 for PVC backup and restore because it is compatible with different storage-provisioner annotations supported by different versions of CSI Provisioner. 

## Related information

* Related Longhorn comment: https://github.com/longhorn/longhorn/issues/4189#issuecomment-1192877753
* https://kubernetes.io/docs/reference/labels-annotations-taints/#volume-kubernetes-io-storage-provisioner
* https://kubernetes.io/docs/reference/labels-annotations-taints/#volume-beta-kubernetes-io-storage-provisioner-deprecated
