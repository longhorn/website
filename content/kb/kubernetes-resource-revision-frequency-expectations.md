---
title: "Kubernetes resource revision frequency expectations"
authors:
- "Eric Weber"
draft: false
date: 2024-02-23
versions:
- "See Applicable Versions"
categories:
- "instruction"
- "etcd"
---

## Applicable versions

The information in this article was specifically researched for v1.6.0, but is largely applicable to other versions.

## Background

Each time a Kubernetes resource is updated, the Kubernetes API server instructs etcd to create a new revision of its
associated key. The version number of this revision is incremented by one. etcd continues to store past revisions of all
keys until its key store is compacted to save space.

A user noticed that the etcd keys associated with certain Longhorn objects had greater version numbers compared to the
keys of other objects in their cluster. The concern was that the greater version numbers for `Volume`, `Engine`, and
`Node` resources indicated issues in their Longhorn installation.

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

## Frequency of revisions during periods of churn

Longhorn may update resources very frequently to track state as it ensures volumes are ready to serve workloads.
Predicting the number of revisions to be created during certain activities is difficult. In most clusters, activities
such as node rebooting, replica rebuilding, and volume creation are relative rarities in between long stretches of
stable workload activity.

## Frequency of revisions during periods of stability

Longhorn frequently updates the statuses of `Volume`, `Engine`, and `Node` resources, even when nothing notable is
occurring. These updates help keep track of the actual space consumed by Longhorn volumes at any given moment,
particularly the following:

- `engine.status.snapshots[].size`: Tracks the space consumed by each volume snapshot in real time. An engine monitor
  collects and then pushes the information to the `Engine` object every five seconds (if the consumption has changed and
  new blocks are being written). Longhorn does not push a status update if no changes are made.
- `volume.status.actualSize`: Tracks the actual space consumed by a specific volume in real time, which is calculated
  based on values obtained from `engine.status.snapshots[].size`. This field in the `Volume` object is updated if new
  blocks are being written and `engine.status.snapshots[].size` is updated every five seconds. The information is
  displayed prominently on the Longhorn UI to help you understand your system's space consumption on a per-volume basis.
- `node.status.diskStatus[].storageAvailable`: Tracks the actual amount of space available on a physical disk in real
  time. A disk monitor collects and then pushes the information to the `Node` object every 30 seconds (if the available
  space has changed). Since physical disk space is in constant flux, Longhorn only updates this field if a change
  exceeds 100 MiB. Longhorn uses the information to make replica scheduling decisions.

### Frequency estimates

Assuming new blocks are constantly being written to a Longhorn volume, approximately 17,280 revisions per day can be
expected for `Engine` and `Volume` objects. The volume from the background section could have hit version 2804569 in
approximately 162 days. (Many volumes might not experience this kind of constant write activity).

```
(12 revisions/min)(60 min/hr)(24 hr/day) = 17,280 revisions/day
```

Assuming at least 100 MiB of new blocks are constantly being written to all Longhorn volumes with replicas on a physical
disk, approximately 2,880 revisions per day can be expected for `Node` objects. The node from the background section
could have hit version 462517 in approximately 161 days. (Many nodes might not experience this kind of constant write
activity).

```
(2 revisions/min)(60 min/hr)(24 hr/day) = 2,880 revisions/day
```
