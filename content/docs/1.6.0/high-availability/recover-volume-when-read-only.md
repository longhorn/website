---
title: Recover Volume When It Becomes Read Only
weight: 1
---

The state of a volume can change to read-only when IO errors occur. IO errors can be caused by a variety of issues, including the following:
- Network disconnection: Interrupted connection between the engine and replicas
- High disk latency: Significant delay in the transfer of data between a replica and the corresponding disk

Longhorn periodically checks the volume state. When the filesystem of the volume becomes Read-only, Longhorn automatically attempts to remount the global mount point on the host to change the state back to read-write. On successful remount, the workload pods will continue working without service disruption.