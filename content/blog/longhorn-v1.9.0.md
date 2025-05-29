---
title: What's New in Longhorn 1.9
author: Divya Mohan
draft: false
date: 2025-05-29
categories:
  - "announcement"
---

The Longhorn team is thrilled to share the general availability of [Longhorn v1.9.0](https://github.com/longhorn/longhorn/releases/tag/v1.9.0). 
This update is all about making your storage experience more resilient, more observable, and a lot less stressful.

## Building Resilience: Offline Replica Rebuilding
In distributed systems, failures aren’t a matter of “if,” but “when.” 
With v1.9.0, Longhorn introduces [offline replica rebuilding](https://longhorn.io/docs/1.9.0/advanced-resources/rebuilding/offline-replica-rebuilding/). 
This means that if a replica goes down, Longhorn can now recover it even when the volume is detached. 
For operators, this translates to less manual intervention and faster recovery, letting you focus on delivering value rather than firefighting infrastructure issues.

## Smarter Cleanup: Orphaned Resource Management
We’ve all seen those pesky orphaned resources — leftover replicas or engines that linger after a node failure or abrupt deletion. 
Longhorn now automatically tracks and cleans up these orphans, keeping your cluster tidy and your resource usage efficient. 
Just [enable the new setting](https://longhorn.io/docs/1.9.0/advanced-resources/data-cleanup/orphaned-instance-cleanup/), and let Longhorn do the housekeeping for you.

## Performance Matters: V2 Data Engine Enhancements
Performance is at the heart of every storage conversation, and the V2 Data Engine gets a significant boost in this release. 
With support for the [UBLK frontend](https://github.com/longhorn/longhorn/issues/9719) and [storage network segregation](https://github.com/longhorn/longhorn/issues/6450), 
you can expect lower latency and better throughput, especially for data-intensive workloads. 
These improvements are powered by SPDK, making Longhorn even more suitable for demanding environments.

## Backups That Work for You
Backups are your last line of defence, and Longhorn v1.9.0 makes them easier to manage. 
You can now schedule [recurring system backups](https://longhorn.io/docs/1.9.0/advanced-resources/system-backup-restore/backup-longhorn-system/), 
ensuring your system state is always protected. Plus, snapshots are automatically cleaned up after backups, so you’re not left managing storage sprawl.

## Observability: Because You Can’t Fix What You Can’t See
This release introduces new Prometheus metrics, giving you deeper insights into the health and status of your replicas and engines. 
Better observability means faster troubleshooting and more informed decisions—something every operator can appreciate.

## Keeping APIs Clean and Modern
Technical debt slows everyone down. By removing deprecated fields and signalling the end of support for the v1beta1 APIs, 
we want to make it easier for our users and integrators to work with a clean, modern interface. 
This is a win for maintainability and future-proofing your stack.

# Get in touch
As always, these improvements are a direct result of community feedback and collaboration. 
If you’re new to Longhorn or open source, remember: every contribution counts, and your voice matters. 
Join the conversation on the [CNCF](https://slack.cncf.io/) [#longhorn](https://cloud-native.slack.com/messages/longhorn) Slack channel or [GitHub discussions](https://github.com/longhorn/longhorn/discussions)
and let us know how you’re using Longhorn v1.9.0! 

Starting June 19th 2025, we will also host a **monthly community meeting** on the **3rd Thursday**, 
alternating between AMER/EU-friendly and APAC-friendly times at 4:00 PM UTC and 8:00 AM UTC, respectively. 
Please consider joining us by [downloading the calendar invite](https://zoom-lfx.platform.linuxfoundation.org/meetings/longhorn?view=list).
