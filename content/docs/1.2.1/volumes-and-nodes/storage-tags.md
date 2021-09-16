---
title: Storage Tags
weight: 3
---

## Overview

The storage tag feature enables only certain nodes or disks to be used for storing Longhorn volume data. For example, performance-sensitive data can use only the high-performance disks which can be tagged as `fast`, `ssd` or `nvme`, or only the high-performance node tagged as `baremetal`.

This feature supports both disks and nodes. 

## Setup

The tags can be set up using the Longhorn UI:

1. *Node -> Select one node -> Edit Node and Disks*
2. Click `+New Node Tag` or `+New Disk Tag` to add new tags.

All the existing scheduled replica on the node or disk won't be affected by the new tags.

## Usage

When multiple tags are specified for a volume, the disk and the node (the disk belong to) must have all the specified tags to become usable.

### UI

When creating a volume, specify the disk tag and node tag in the UI.

### Kubernetes

Use Kubernetes StorageClass setting to specify tags.

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
