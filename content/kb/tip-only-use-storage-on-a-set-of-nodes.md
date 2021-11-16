---
title: "Tip: Set Longhorn To Only Use Storage On A Specific Set Of Nodes"
author: Phan Le
draft: false
date: 2021-11-15
categories:
- "tip"
- "scheduling"
---

## Applicable versions

All Longhorn versions.

## Background

Let's say you have a cluster of 5 nodes (`node-1`, `node-2`, ..., `node-5`).
You have some fast disks on `node-1`, `node-2`, and `node-3` so you want Longhorn to use storage on those nodes only.
There are a few ways to do this as below.

## Tell Longhorn to create a default disk on a specific set of nodes
* Label `node-1`, `node-2`, and `node-3` with label `node.longhorn.io/create-default-disk=true` (e.g., `kubectl label nodes node-1 node.longhorn.io/create-default-disk=true`)
* Install Longhorn with the setting [Create Default Disk on Labeled Nodes](https://longhorn.io/docs/1.2.2/references/settings/#create-default-disk-on-labeled-nodes) set to `true`.

**Result**: workloads that use Longhorn volumes can run on any nodes. Longhorn only uses storage on `node-1`, `node-2`, and `node-3` for replica scheduling.

## Create a StorageClass that select a specific set of nodes
* Install Longhorn normally on all nodes
* Go to the node page on Longhorn UI, tag the node `node-1`, `node-2`, and `node-3` with a tag, e.g., `storage`
* Create a new StorageClass that have node selector `nodeSelector: "storage"` . E.g.,
  ```yaml
  kind: StorageClass
  apiVersion: storage.k8s.io/v1
  metadata:
    name: my-longhorn-sc
  provisioner: driver.longhorn.io
  allowVolumeExpansion: true
  reclaimPolicy: Delete
  volumeBindingMode: Immediate
  parameters:
    numberOfReplicas: "3"
    staleReplicaTimeout: "2880" # 48 hours in minutes
    fromBackup: ""
    fsType: "ext4"
    nodeSelector: "storage"
  ```
* Use the StorageClass `my-longhorn-sc` for the PVCs of workload. E.g.,
  ```yaml
  apiVersion: v1
  kind: PersistentVolumeClaim
  metadata:
    name: my-longhorn-volv-pvc
  spec:
    accessModes:
      - ReadWriteOnce
    storageClassName: my-longhorn-s
    resources:
      requests:
        storage: 2Gi
  ```
**Result**: workloads that use Longhorn volumes can run on any nodes.
Longhorn only schedules replicas of `my-longhorn-volv-pvc` on the node `node-1`, `node-2`, and `node-3`

## Deploy Longhorn components only on a specific set of nodes
* Label `node-1`, `node-2`, and `node-3` with label `storage=longhorn` (e.g., `kubectl label nodes node-1 storage=longhorn`)
* Set node selector for Longhorn components by following [the instruction](https://longhorn.io/docs/1.2.2/advanced-resources/deploy/node-selector/) to deploy Longhorn components only on node with label `storage=longhorn`

**Result**: Longhorn components are only deployed on `node-1`, `node-2`, and `node-3`.
Workloads that use Longhorn volumes can only be scheduled on  `node-1`, `node-2`, and `node-3`.
