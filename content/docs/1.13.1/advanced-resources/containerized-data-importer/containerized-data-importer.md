---
title: Longhorn with CDI Imports
weight: 1
---

This document explains how to use the [Containerized Data Importer (CDI)](https://github.com/kubevirt/containerized-data-importer) to import Raw or QCOW2 images into Longhorn. It details the workflow for creating a reusable **Golden Image** and provisioning multiple workloads from it using CSI Volume Cloning.

## Overview

In Kubernetes environments that require pre-populated disk images, CDI enables importing external images into Longhorn-backed PersistentVolumeClaims (PVCs), which serve as the reusable Golden Image for provisioning subsequent workloads.

Technically, the Golden Image acts as a **Base Image PVC**. Longhorn implements this via CSI Volume Cloning, creating a **full, independent copy** for each new claim. This ensures complete data isolation: workloads obtain their own writable volumes, and the original Golden Image remains unchanged and independent of the clones at runtime.

## Workflow

1.  **Import:** CDI pulls an image from an external source (HTTP, S3, or container registry) and populates a Longhorn-backed PVC.
2.  **Protect:** This PVC functions as the "Golden Image." It is recommended to treat this PVC as **read-only** or immutable to ensure consistency for future clones.
3.  **Clone:** Workloads create new PVCs referencing the base image as their `dataSource`. Longhorn copies the data from the base image to the new volume.

### Creating a Base Image PVC

A DataVolume manifest specifies the source image and the Longhorn storage class. For example, importing a QCOW2 image via HTTP:

```
apiVersion: cdi.kubevirt.io/v1beta1
kind: DataVolume
metadata:
  name: golden-base-image
spec:
  source:
    http:
      url: "https://example.com/images/base-image.qcow2"
  pvc:
    accessModes:
      - ReadWriteOnce
    resources:
      requests:
        storage: 10Gi
    storageClassName: longhorn
```

After creation, CDI handles the image import and conversion, resulting in a Longhorn-backed PVC that acts as the base image. It is recommended to treat this PVC as immutable and avoid direct writes from workloads.

### Cloning Base Images

Cloning a base image PVC in Longhorn is performed in full copy mode, creating a complete independent copy of the base image for each cloned PVC. This ensures that each workload has its own isolated volume without relying on the base image for runtime operations. For example:

```
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: cloned-pvc-1
spec:
  dataSource:
    name: golden-base-image
    kind: PersistentVolumeClaim
    apiGroup: ""
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  storageClassName: longhorn
```

Multiple clones can be created from the same base image, each as a full independent copy ensuring workload isolation.

## References

- [Containerized Data Importer](https://github.com/kubevirt/containerized-data-importer)