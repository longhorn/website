---
title: Revision Counter
weight: 2
---

The revision counter is a strong mechanism that Longhorn uses to track each replica's updates.

During replica creation, Longhorn will create a 'revision.counter' file with its initial counter set to 0. And for every write to the replica, the counter in 'revision.counter' file will be increased by 1.

The Longhorn Engine will use these counters to make sure all replicas are consistent during start time. These counters are also used during salvage recovery to decide which replica has the latest update.

Disable Revision Counter is an option in which every write on replicas is not tracked. When this setting is used, performance is improved, but the strong tracking for each replica is lost. This option can be helpful if you prefer higher performance and have a stable network infrastructure (e.g. an internal network) with enough CPU resources. When the Longhorn Engine starts, it will skip checking the revision counter for all replicas, but auto-salvage will still be supported through the replica's head file stat. For details on how auto-salvage works without the revision counter, refer to [this section.](#auto-salvage-support-with-revision-counter-disabled)

By default, the revision counter is enabled.

> **Note:** 'Salvage' is Longhorn trying to recover a volume in a faulted state. A volume is in a faulted state when the Longhorn Engine loses the connection to all the replicas, and all replicas are marked as being in an error state.

# Disable Revision Counter
## Using Longhorn UI
To disable or enable the revision counter from the Longhorn UI, click **Setting > General > Disable Revision Counter.**

To create individual volumes with settings that are customized against the general settings, go to the **Volume** page and click **Create Volume.**

## Using a Manifest File

A `StorageClass` can be customized to add a `disableRevisionCounter` parameter.

By default, the `disableRevisionCounter` is false, so the revision counter is enabled.

Set `disableRevisionCounter` to true to disable the revision counter:

```yaml
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: best-effort-longhorn
provisioner: driver.longhorn.io
allowVolumeExpansion: true
parameters:
  numberOfReplicas: "1"
  disableRevisionCounter: "true"
  staleReplicaTimeout: "2880" # 48 hours in minutes
  fromBackup: ""
```

## Auto-Salvage Support with Revision Counter Disabled
The logic for auto-salvage is different when the revision counter is disabled.

When revision counter is enabled and all the replicas in the volume are in the 'ERR' state, the engine controller will be in a faulted state, and for engine to recover the volume, it will get the replica with the largest revision counter as 'Source of Truth' to rebuild the rest replicas.

When the revision counter is disabled in this case, the engine controller will get the `volume-head-xxx.img` last modified time and head file size of all replicas. It will also do the following steps:
1. Based on the time that `volume-head-xxx.img` was last modified, get the latest modified replica, and any replica that was last modified within five seconds can be put in the candidate replicas for now.
2. Compare the head file size for all the candidate replicas, and pick the one with the largest file size as the source of truth.
3. The replica chosen as the source of truth is changed to 'RW' mode, and the rest of the replicas are marked as 'ERR' mode. Replicas are rebuilt based on the replica chosen as the source of truth.
