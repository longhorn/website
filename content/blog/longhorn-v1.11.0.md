---
title: What's New in Longhorn 1.11
author: Derek Su
draft: false
date: 2026-01-30
categories:
  - "announcement"
---

The Longhorn team is excited to announce the release of [Longhorn v1.11.0](https://github.com/longhorn/longhorn/releases/tag/v1.11.0).
This release represents a major step forward in stability, observability, and scheduling intelligence, while marking an important milestone for the **V2 Data Engine**, which officially enters the **Technical Preview** stage.

## V2 Data Engine: Entering Technical Preview

With v1.11.0, the V2 Data Engine officially graduates to **Technical Preview**, reflecting significant improvements in stability, performance, and operational readiness.

> **Note:** Live upgrade is not supported yet for the V2 Data Engine. V2 volumes must be detached before upgrading the engine.

### High-Performance Frontend with `ublk`

Longhorn supports configuring UBLK performance parameters globally, per volume, or via StorageClass to improve I/O performance.

### Deprecation of V2 Backing Image

The **Backing Image** feature for the V2 Data Engine is deprecated in this release and will be removed in v1.12.0.
Users are encouraged to adopt **Containerized Data Importer (CDI)** for volume population, aligning Longhorn with the broader Kubernetes and KubeVirt ecosystem.

## Faster Recovery: Smarter Replica Rebuilding

### Parallel Rebuilding for V1 Data Engine

Replica rebuilding in the V1 Data Engine is now significantly faster. Instead of rebuilding from a single healthy replica, Longhorn can stream data from **multiple replicas in parallel**, dramatically reducing rebuild time for fragmented or large volumes.

This improvement shortens exposure windows during failures and helps clusters recover redundancy more quickly.

## Smarter Scheduling and Better Resource Balance

### Balance-Aware Replica Scheduling

Longhorn introduces a **balance-aware disk selection algorithm** that considers disk usage across nodes and disks when scheduling replicas.  
This reduces uneven capacity distribution, avoids hotspots, and improves long-term cluster health—especially in large or heterogeneous environments.

### Topology-Aware Provisioning

With support for Kubernetes `StorageClass.allowedTopologies`, administrators can now constrain volume provisioning to specific zones, regions, or nodes, enabling better alignment with failure domains and infrastructure layouts.

## Disk Health Monitoring and Observability

### Node Disk Health Monitoring

Longhorn now actively monitors disk health using **S.M.A.R.T. data**, allowing early detection of failing disks and enabling proactive maintenance before volumes are impacted.

Administrators can also disable disk health monitoring if required for specific environments.

## Expanded Kubernetes Feature Support

### ReadWriteOncePod (RWOP)

Longhorn now fully supports the Kubernetes **ReadWriteOncePod (RWOP)** access mode, enabling stricter single-pod attachment guarantees and improving safety for stateful workloads that rely on exclusive access semantics.

### Flexible Networking for Share Manager

Users can now configure an **additional network interface** for the Share Manager, supporting more complex network segmentation and security requirements for RWX volumes.

## Get in touch

As always, these improvements are the direct result of community feedback and collaboration.
If you’re new to Longhorn or open source, remember: every contribution counts, and your voice matters.
Join the conversation on the [CNCF](https://slack.cncf.io/) [#longhorn](https://cloud-native.slack.com/messages/longhorn) Slack channel or [GitHub discussions](https://github.com/longhorn/longhorn/discussions) and let us know how you’re using Longhorn v1.11.0!