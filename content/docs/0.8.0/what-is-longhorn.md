---
title: What is Longhorn?
weight: 2
---

Longhorn is an open source project for microservices-based distributed block storage.

## Why Longhorn

To keep up with the growing scale of cloud- and container-based deployments, distributed block storage systems are becoming increasingly sophisticated. The number of volumes a storage controller serves continues to increase. While storage controllers in the early 2000s served no more than a few dozen volumes, modern cloud environments require tens of thousands to millions of distributed block storage volumes. Storage controllers have therefore become highly complex distributed systems.

Distributed block storage is inherently simpler than other forms of distributed storage such as file systems. No matter how many volumes the system has, each volume can only be mounted by a single host. Because of this, it is conceivable that we should be able to partition a large block storage controller into a number of smaller storage controllers, as long as those volumes can still be built from a common pool of disks and we have the means to orchestrate the storage controllers so they work together coherently.