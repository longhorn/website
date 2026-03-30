---
title: Upgrade Kubernetes on AWS EKS
weight: 4
---

In Longhorn, set `replica-replenishment-wait-interval` to `0`.

See [Updating a cluster](https://docs.aws.amazon.com/eks/latest/userguide/update-cluster.html) for instructions.

> **Note:** If you have created [addition disks](../manage-node-group-on-eks#create-additional-volume) for Longhorn, you will need to manually add the path of the mounted disk into the disk list of the upgraded nodes.