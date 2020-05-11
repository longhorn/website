---
title: Tagging Nodes, Volumes and Disks
weight: 3
---

The storage tag feature enables the user to only use certain nodes or disks for storing Longhorn volume data. For example, performance-sensitive data can use only the high-performance disks which can be tagged as `fast`, `ssd` or `nvme`, or only the high-performance node could be tagged as `baremetal`.

This feature supports both disks and nodes. 

> When multiple tags are specified for a volume, the disk and the node (that the disk belongs to) must have all the specified tags to become usable.

### Tagging Nodes with Longhorn

The tag setup can be found at Longhorn UI:

1. Click the **Node** tab. Each node is listed in the table on this page.
2. Go to the node where the tags need to be added or edited. In the **Operation** column of the table, click the three-line menu dropdown and click **Edit node and disks.**
3. Click **+New Node Tag** or **+New Disk Tag** to add new tags.

All the existing scheduled replicas on the node or disk won't be affected by the new tags.

### Tagging Volumes with Longhorn

When creating a volume, specify the disk tag and node tag in the UI.

### Tagging Nodes and Disks with Kubernetes

Tags can be specified using the Kubernetes StorageClass settings.

For example:
```
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: longhorn-fast
provisioner: driver.longhorn.io
parameters:
  numberOfReplicas: "3"
  staleReplicaTimeout: "480" # 8 hours in minutes
  diskSelector: "ssd"
  nodeSelector: "storage,fast"
```

## History
* [Original feature request](https://github.com/longhorn/longhorn/issues/311)
* Available since v0.6.0
