---
title: What's New in Longhorn 1.10
author: Derek Su
draft: false
date: 2025-11-12
categories:
  - "announcement"
---

The Longhorn team is excited to announce the release of [Longhorn v1.10.0](https://github.com/longhorn/longhorn/releases/tag/v1.10.0), a major milestone focused on stability, performance, and ease of management.
This version delivers significant improvements to the V2 Data Engine, unified configuration handling, and enhanced observability across the system.

## Performance Matters: V2 Data Engine Enhancements

Longhorn v1.10.0 introduces several key upgrades to the V2 Data Engine:

- **Interrupt Mode**: The new interrupt mode automatically reduces CPU usage during idle or light workloads, improving efficiency without compromising responsiveness.

- **Controlled Replica Rebuilding**: Replica rebuilding now supports QoS controls, allowing administrators to limit rebuild bandwidth and avoid resource contention during peak loads. This ensures smoother recovery and more predictable performance under heavy usage.

- **Flexible and Fast Cloning**: Cloning is now faster and more versatile. You can choose between full-copy clones, which create fully independent volumes for complete isolation, and linked clones, which share data blocks with the source volume for near-instant creation. It is ideal for temporary workloads, backups, or testing. In addition, Longhorn now supports online expansion for V2 volumes, enabling seamless capacity increases without downtime.

- **Hugepages Not Required**: The V2 Data Engine can now run without hugepages, simplifying deployment on smaller or mixed-purpose nodes while maintaining performance and stability.

## Configurations Made Simple: Unified Settings Across Engines

Longhorn v1.10.0 introduces a consistent global settings format that applies to both V1 and V2 data engines. Using a standardized JSON structure, administrators can now manage configurations more easily and automate tasks across engines with reduced complexity.

## Networking Evolves: IPv6 Support

With Kubernetes adoption of IPv6 on the rise, Longhorn now supports single-stack IPv6 environments. This update aligns Longhorn with modern networking standards and lays the groundwork for future dual-stack capabilities.

## Smarter Scheduling, Cleaner Backups

Integration with Kubernetes `CSIStorageCapacity` enables more accurate, storage-aware volume scheduling. Backups are now more configurable, with adjustable block sizes that allow administrators to optimize for speed or storage efficiency based on workload requirements.

## Cleaning House: Removing Deprecated APIs

To improve maintainability and future-proof the system, this release removes the deprecated `longhorn.io/v1beta1` API and the unused `replica.status.evictionRequested` field. These changes streamline the codebase and provide a clean foundation for future development.

## Get in touch

As always, these improvements are the direct result of community feedback and collaboration.
If you’re new to Longhorn or open source, remember: every contribution counts, and your voice matters.
Join the conversation on the [CNCF](https://slack.cncf.io/) [#longhorn](https://cloud-native.slack.com/messages/longhorn) Slack channel or [GitHub discussions](https://github.com/longhorn/longhorn/discussions) and let us know how you’re using Longhorn v1.10.0!