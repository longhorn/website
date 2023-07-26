---
title: "Troubleshooting: Unexpected expansion leads to degradation or attach failure"
author: Eric Weber
draft: false
date: 2023-07-26
categories:
  - "expansion"
  - "replica"
  - "instance-manager"
---

## Applicable versions

Confirmed in:

- Longhorn v1.3.2 - v1.3.3
- Longhorn v1.4.0 - v1.4.2
- Longhorn v1.5.0

Potentially mitigated in:

- Longhorn v1.4.3
- Longhorn v1.5.1

Complete fix planned in:

- Longhorn v1.4.x
- Longhorn v1.5.x
- Longhorn v1.6.0

## Symptoms

While the root cause is always the same, symptoms can vary depending on other factors (e.g. whether there are multiple
healthy replicas, which specific version of Longhorn is in use, etc.).

Generic symptoms that are not in-and-of-themselves evidence of this issue include:

- A volume is degraded with multiple failed rebuild attempts.
- A volume fails to attach and/or appears to be in an attach/detach loop.
- A volume experiences the above and has fewer replicas than expected.

More specific symptoms include the following. Not all symptoms are present in all cases.

### Expansion error in the UI

A volume shows as expanding in the UI with a red info symbol indicating a problem. Hovering over the red info symbol
yields a message like:

    Expansion Error: the expected size <small_size> of engine <engine> should not be smaller than the current size <large_size>. You can cancel the expansion to avoid volume crash.

An expansion is not actually ongoing and cannot be cancelled. Attempting to do so yields an error like:

    unable to cancel expansion for volume <volume>: volume expansion is not started

### Instance-manager logs

Instance-manager pods responsible for rebuilding new or pre-existing replicas log repeated failure to do so because of a
size mismatch:

    <time> time="<time>" level=error msg="failed to prune <snapshot>.img based on <snapshot>.img: file sizes are not
    equal and the parent file is larger than the child file"

It is sometimes possible to catch this issue at its origination. The instance-manager pod for an engine logs that it
will expand a replica and then fails to add it. Note that this log is normal and is not by itself an indication of a
problem. However, it can be a red flag if no expansion has been requested:

    <time> [longhorn-instance-manager] time="<time>" level=debug msg="Adding replica <replica_address>" 
    currentSize=<size> restore=false serviceURL="<engine_address>" size=<size>
    <time> [longhorn-instance-manager] time="<time>" level=info msg="Prepare to expand new replica to size <size>"
    <time> [longhorn-instance-manager] time="<time>" level=info msg="Adding replica <replica_address> in WO mode"

Similarly, the instance-manager pod for a replica logs that it is expanding:

    <time> [<replica>] time="<time>" level=info msg="Replica server starts to expand to size <large_size>"

### Longhorn-manager logs

Longhorn-manager pods responsible for monitoring a volume's engine log a bug related to size:

    E<date> <time> 1 engine_controller.go:731] failed to update status for engine <engine>: BUG: The expected size
    <small_size> of engine <engine> should not be smaller than the current size <large_size>

It is sometimes possible to catch this issue at its origination. The longhorn-manager for an engine logs that it fails
to add a replica because it is not in the right state. Note that, while this indicates a likely problem, it is not by
itself an indication that the issue described in this KB has occurred.

    <time> time="<time>" level=error msg="Failed rebuilding of replica <replica_address>" controller=longhorn-engine
    engine=<engine> error="proxyServer=<instance_manager_address> destination=<engine_address>: failed to add replica
    <replica_address> for volume: rpc error: code = Unknown desc = failed to create replica <replica_address> for volume
    <engine_address>: rpc error: code = Unknown desc = replica must be closed, Can not add in state: dirty" node=<node>
    volume=<volume>

### Snapshot chain on disk

Each Longhorn replica maintains a chain of snapshots on disk. Each snapshot is a sparse file with the nominal size of
the volume when it was taken. The size of all snapshots after a particular snapshot is increased, even though the volume
size was never altered:

    -rw-r--r--.   1 root root 10737418240 Jun  8 04:42 volume-snap-snapshot-ab1a619f-196d-4f58-9a35-2c705a05cacb.img
    -rw-r--r--.   1 root root 10737418240 Jun  6 12:11 volume-snap-snapshot-65bfafe1-9581-496a-81bf-78a3151c658d.img
    -rw-r--r--.   1 root root 42949672960 Jun  6 12:11 volume-snap-snapshot-488c080c-0b4f-442f-aeec-667cd36f58cb.img
    -rw-r--r--.   1 root root 42949672960 Jun  6 12:43 volume-snap-snapshot-fadec910-b472-45c0-bd0c-d11f0f5b0234.img
    -rw-r--r--.   1 root root 42949672960 Jun  6 15:12 volume-snap-snapshot-d7b5d42f-0111-44a0-b9b7-6bc080a5a809.img
    -rw-r--r--.   1 root root 42949672960 Jun  7 09:06 volume-snap-snapshot-ffb8c77b-8968-443d-b9e4-d858b9fa5261.img
    -rw-r--r--.   1 root root 42949672960 Jun  7 12:03 volume-snap-snapshot-0236df7a-8b33-4569-8014-e33d735a4e01.img
    -rw-r--r--.   1 root root 42949672960 Jun  7 15:08 volume-snap-snapshot-60621c68-3dc8-445d-bc08-f0f3c5587416.img
    -rw-r--r--.   1 root root 42949672960 Jun  8 04:40 volume-snap-snapshot-71db93c1-d06f-4689-9365-5892a4bfc642.img
    -rw-r--r--.   1 root root 42949672960 Jun  8 04:39 volume-snap-dailybac-d0c4f62a-8f7a-4522-854e-c754e1dadeb9.img
    -rw-r--r--.   1 root root 42949672960 Jun  8 04:42 volume-snap-snapshot-23cbf46b-e1f8-41c7-8d21-edbdacdc38a0.img
    -rw-r--r--.   1 root root 42949672960 Jun  8 07:50 volume-head-007.img

## Root cause

This issue occurs when the engine of a larger volume incorrectly attempts to add the running replica of a smaller
volume. While the larger engine fails to add the smaller replica (because the smaller replica is actively being used),
it successfully expands the smaller replica on disk. Once expanded, the smaller replica can continue to be used as
normal. Its engine can continue writing to and reading from the expected offsets and there may be no immediately
observable symptoms. The Longhorn control plane continues to assume the replica has the correct size.

Symptoms may start to appear when the expanded replica is used as the source for a rebuild (e.g. when another replica is
restarted in normal operation and must sync its files from a healthy one). The rebuild fails in the pruning process
because the volume head for the new replica has the correct size and the snapshot copied from the expanded replica has
a larger size.

Symptoms may also appear if the engine restarts with only the expanded replica. Because there is only one
replica, the engine successfully starts with that replica's size. This conflicts with the size expected by
Longhorn-manager, leading to errors. In practice, this situation can occur relatively easily. Rebuilds using the
expanded replica as a source fail, eventually causing the expanded replica to be the only one remaining.

## Known triggers

In general, this issue seems to be triggered by instance-manager pods being shut down / restarted or entire Longhorn
nodes being shut down / restarted while running engine and replica processes. The Longhorn control plane tracks a
replica by an address/port combination assigned by an instance-manager. During periods of high churn, the address/port
combination referring to one replica (and being tracked by the Kubernetes object for one engine) may be assumed by
another replica. At this moment, actions taken using the outdated Kubernetes object may cause its engine to communicate
with the wrong replica.

Two specific races that lead to this situation have been identified and fixed, but it is possible that another exists:

- https://github.com/longhorn/longhorn-manager/pull/1868 (Longhorn v1.3.x, v1.4.2+, v1.5.0+)
- https://github.com/longhorn/longhorn-manager/pull/2042 (Longhorn v1.3.x, v1.4.3+, v1.5.1+)

## Workaround

### Avoid the issue

Whenever possible, follow the [node maintenance guide](../../docs/1.5.1/volumes-and-nodes/maintenance) when
shutting down or restarting nodes. This eliminates the churn described above and ensures Longhorn safely moves engine
and replica processes between nodes. Never intentionally shut down instance-manager pods or nodes running
instance-manager pods while Longhorn processes are running in them.

### Correct the issue

If a replica has been expanded due to this issue but the volume is not yet degraded, it can be resolved with minimal
impact. Unfortunately, it is unlikely to discover it occurred before symptoms are present.

1. See that a replica has been unexpectedly expanded in instance-manager logs.
1. Verify that there are other, healthy replicas.
1. Delete the expanded replica.

If symptoms are observed and there is an acceptable backup,
[restore from backup](../../docs/1.5.1/snapshots-and-backups/backup-and-restore/restore-from-a-backup).

If symptoms are observed and there is not an acceptable backup, expand the volume to the size of the expanded replica.

1. Identify the size of the expanded replica. This is the larger size shown in the UI error and the instance-manager
   logs. It is also the larger size of the snapshot files on disk.
1. On Longhorn versions before v1.4.0 (or if these steps otherwise don't succeed), scale down the workload. Longhorn
   v1.4.0+ supports online expansion and it should work depending on the exact state of the volume.
1. [Expand the volume to the larger size](../../docs/1.5.1/volumes-and-nodes/expansion).
1. Wait for replicas to rebuild and for the volume to transition from degraded to healthy.
1. If the workload is scaled down, scale it up again.

In some situations, the above volume expansion may be unacceptable (e.g. if a 2 GiB volume was expanded by a 2 TiB
engine). If desired, after expansion:

1. Create a new volume (with the correct size).
1. Manually attach the old and new volume to the same node.
1. Copy all data from the old volume to the new volume using `cp` or `rsync` at the filesystem level.
1. Detach both volumes.
1. Use the new volume for the workload.
1. Delete the old volume.

## Long term fix

A complete fix for this issue is under active development. The goal is to make it impossible for any Longhorn component
(instance-manager, engine, etc.) to communicate with the wrong process by sending volume name and instance name metadata
in each request. If a process receives the wrong metadata, it will return an error and take no action. This fix should
be available in v1.6.0, v1.5.x, and v1.4.x. See the [GitHub issue](https://github.com/longhorn/longhorn/issues/5845) for
more information.

## Related information

- https://github.com/longhorn/longhorn/issues/5709:
  One of the original GitHub issues.
- https://github.com/longhorn/longhorn/issues/6078:
  GitHub issue reporting that a first fix was insufficient.
- https://github.com/longhorn/longhorn/issues/6217:
  GitHub issue with a recreate and a second fix eliminating it.
- https://github.com/longhorn/longhorn/issues/5845:
  GitHub issue tracking the long term fix.
