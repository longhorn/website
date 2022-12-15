---
title: "Troubleshooting: Restore PVC stuck using Velero CSI plugin version < 0.4"
author: Ray Chang
draft: false
date: 2022-12-15
categories:
  - "restore"
---

## Applicable versions

All Longhorn versions.

## Symptoms

PersistentVolumeClaim (PVC) stuck in `Pending` state after restore with Velero < 0.4.

## Reason

When using Velero CSI plugin version < 0.4 to restore a PVC, only the GA storage-provisioner `volume.kubernetes.io/storage-provisioner` in the annotation will be restored, but without the beta version `volume.beta.kubernetes.io/storage-provisioner`. 

Longhorn finds the beta version of storage-provisioner in annotation and provision the volume.

## Solution

It is recommended to use Velero CSI plugin version >= 0.4 for backup and restore, it started supporting beta version storage-provisioner removed from annotation.

## Related information

* Related Longhorn comment: https://github.com/longhorn/longhorn/issues/4189#issuecomment-1192877753
