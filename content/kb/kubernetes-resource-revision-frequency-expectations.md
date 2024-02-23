---
title: "Kubernetes resource revision frequency expectations"
author: Eric Weber
draft: false
date: 2024-02-23
categories:
- "instruction"
- "etcd"
---

## Applicable versions

Specifically researched for v1.6.0, but largely applicable to other versions.

## Background

Each time a Kubernetes resource is updated, the Kubernetes API server instructs etcd to create a new revision of its
associated key. The version number of this revision is incremented by one. etcd continues to store past revisions of all
keys until its key store is compacted to save space.

A user noticed that the etcd keys associated with certain Longhorn objects had larger version number than for many other
objects in their cluster. They were concerned that this larger version number indicated their Longhorn installation had
problems. In particular, they saw high version numbers for `Volume`, `Engine`, and `Node` resources.

```
"Key" : "/registry/longhorn.io/volumes/longhorn-system/<some_volume>"
"CreateRevision" : 988635856
"ModRevision" : 1137860097
"Version" : 2804569

"Key" : "/registry/longhorn.io/engines/longhorn-system/<some_volume>-e-<some_hash>"
"CreateRevision" : 988635861
"ModRevision" : 1137860096
"Version" : 2274122

"Key" : "/registry/longhorn.io/nodes/longhorn-system/<some_node>"
"CreateRevision" : 988599936
"ModRevision" : 1137859827
"Version" : 462517
```

## Frequency of revisions during periods churn

While interesting things are happening on the cluster, Longhorn may update resources very frequently to track state as
it ensures volumes are ready to serve workloads. It is hard to predict how many revisions will be created when nodes are
rebooted, replicas are rebuilt, volumes are creates, snapshots/backups are taken, etc. In most clusters, these
activities are relative rarities in between long stretches of stable workload activity.

## Frequency of revisions during periods of stability

### Reasons for revisions

Longhorn updates `Volume`, `Engine`, and `Node` statuses relatively frequently, even when nothing particularly
interesting is happening. These updates mostly happen to help keep track of the actual space being consumed by Longhorn
volumes at any given moment. In particular:

- `engine.status.snapshots[].size` tracks the space consumed by each snapshot of a volume in real time. There is an
  engine monitor that collects this information and pushes it to the `Engine` object every five seconds if the
  consumption has changed. This only takes effect if new blocks are being written. Longhorn does not push a status
  update if nothing changes.
- `volume.status.actualSize` tracks the actual space consumed by a volume in real time. This is just a calculation done
  on the values obtained from `engine.status.snapshots[].size`. If new blocks are actively being written and
  `engine.status.snapshots[].size` is being updated every five seconds, so is this field in the `Volume` object. This
  information is displayed prominently in the UI to help users understand their space consumption on a per-volume basis.
- `node.status.diskStatus[].storageAvailable` tracks the amount of space actually available on a physical disk in real
  time. There is a disk monitor that collects this information and pushes it to the `Node` object every thirty seconds
  if the available space has changed. Since physical disk space is in constant flux, Longhorn only updates this field if
  there is a change of at least 100 MiB. It uses this information to make replica scheduling decisions.

### Frequency estimates

Assuming new blocks are being written constantly to a Longhorn volume, we can expect approximately 17,280 revisions/day
for `Engine` and `Volume` objects. The volume from the background section could have hit version 2804569 in
approximately 162 days. (Of course many/most volumes won't experience this kind of constant write activity).

```
(12 revisions/min)(60 min/hr)(24 hr/day) = 17,280 revisions/day
```

Assuming at least 100 MiB of new blocks are being written constantly to all of the Longhorn volumes with replicas on a
physical disk, we can expect approximately 2,880 revisions/day for `Node` objects. The node from the background section
could have hit version 462517 in approximately 161 days. (Of course, many nodes might not experience this kind of 
constant write activity).

```
(2 revisions/min)(60 min/hr)(24 hr/day) = 2,880 revisions/day
```
