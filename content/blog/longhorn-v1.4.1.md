---
title: Longhorn 1.4.1 released
author: David Ko
draft: false
date: 2023-03-13
categories:
  - "announcement"
---

Longhorn 1.4.1 is the first stable release of Longhorn 1.4 since v1.4.0 was released three months ago, and its primary focus is on space efficiency, resilience, performance, and stability.

Regarding space efficiency, the space usage of volume snapshots is always the main area to improve. In previous versions, Longhorn supported recurring jobs to retain a specific number of volume snapshots for the volume that applied the job. However, there were some cases that were not achievable, such as deleting all snapshots or system snapshots with removable snapshots, especially for workloads that have their own replication capability like distributed databases. In v1.4.1, two new job types have been introduced: snapshot-delete and snapshot-cleanup. Users can plan different jobs based on their space usage requirements to clean up unnecessary snapshots and optimize space efficiency.

In terms of resilience, if a node becomes not ready due to reasons such as kubelet restarts, network partition, etc., the engine or replica of a volume will become unknown and wait to see if the situation is temporary or durable. If the situation is temporary, it will be recovered without volume restart or replica rebuild. Otherwise, the replica or engine will stay in the right status to recover if needed. For RWX share manager pods, they will still failover immediately to ensure that the service remains available.

Regarding stability, replica rebuilding will not be caused by temporary network disconnection. Volume backup and restore will work as expected under a proxy, RWX storage upgrades will fix potentially rare segments, and the new support bundle mechanism will work in an air-gap environment, among other improvements.

Lastly, in terms of performance, Longhorn has improved the memory consumption of the instance manager for replicas and unlocked stuck unmount processes caused by RWX volumes being unexpectedly detached.

Several bug fixes are also included in this new release. Please check the release notes (https://github.com/longhorn/longhorn/releases/tag/v1.4.1) and the documentation (https://longhorn.io/docs/1.4.1/) to learn more about them.

Enjoy this release and feel free to provide any feedback at https://github.com/longhorn/longhorn/issues.
