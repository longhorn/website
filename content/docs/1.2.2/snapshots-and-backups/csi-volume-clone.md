---
title: CSI Volume Clone Support
description: Creating a new volume as a duplicate of an existing volume
weight: 3
---

Longhorn supports [CSI volume cloning](https://kubernetes.io/docs/concepts/storage/volume-pvc-datasource/).
Suppose that you have the following `source-pvc`:
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: source-pvc
spec:
  storageClassName: longhorn
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
```
You can create a new PVC that has the exact same content as the `source-pvc` by applying the following yaml file:
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: cloned-pvc
spec:
  storageClassName: longhorn
  dataSource:
    name: source-pvc
    kind: PersistentVolumeClaim
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
```

> Note:
> In addition to the requirements listed at [CSI volume cloning](https://kubernetes.io/docs/concepts/storage/volume-pvc-datasource/),
> the `cloned-pvc` must have the same `resources.requests.storage` as the `source-pvc`.

## History
- [GitHub Issue](https://github.com/longhorn/longhorn/issues/1815)
- [Longhorn Enhancement Proposal](https://github.com/longhorn/longhorn/pull/2864)

Available since v1.2.0
