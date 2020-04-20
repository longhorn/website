---
title: The Longhorn Documentation
description: Cloud native distributed block storage for Kubernetes
weight: 1
---

**Longhorn** is a lightweight, reliable, and powerful distributed [block storage](https://cloudacademy.com/blog/object-storage-block-storage/) system for Kubernetes.

Longhorn implements distributed block storage using containers and microservices. Longhorn creates a dedicated storage controller for each block device volume and synchronously replicates the volume across multiple replicas stored on multiple nodes. The storage controller and replicas are themselves orchestrated using Kubernetes.

## Features

* Enterprise-grade distributed block storage with no single point of failure
* Incremental snapshot of block storage
* Backup to secondary storage ([NFS](https://www.extrahop.com/resources/protocols/nfs/) or [S3](https://aws.amazon.com/s3/)-compatible object storage) built on efficient change block detection
* Recurring [snapshot and backup](concepts/snapshots)
* Automated, non-disruptive [upgrades](install/upgrades). You can upgrade the entire Longhorn software stack without disrupting running storage volumes.]
* An intuitive GUI dashboard

## Current status

Longhorn is beta-quality software. We appreciate your willingness to deploy Longhorn and provide feedback.

The latest release of Longhorn is **v0.8.0**.

## Source code
Longhorn is 100% open source software. Project source code is spread across a number of repos:

1. Longhorn engine -- Core controller/replica logic https://github.com/longhorn/longhorn-engine
1. Longhorn manager -- Longhorn orchestration https://github.com/longhorn/longhorn-manager
1. Longhorn UI -- Dashboard https://github.com/longhorn/longhorn-ui
