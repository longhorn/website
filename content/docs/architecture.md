---
title: Architecture
description: How Longhorn works
weight: 3
---

Longorn implements distributed block storage using containers and microservices. It creates a dedicated storage controller for each block device volume and synchronously replicates the volume across multiple replicas stored on multiple nodes. The storage controller and replicas are themselves orchestrated using [Kubernetes](https://kubernetes.io).

{{< info >}}
For more info, see [this blog post](https://rancher.com/blog/2017/announcing-longhorn-microservices-block-storage/) on the [Rancher blog](https://rancher.com/blog).
{{< /info >}}
