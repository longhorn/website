---
title: Revision Counter
weight: 2
---

Revision Counter is a strong mechanism that Longhorn keeps tracking each replicas' updates. During replica creation, Longhorn will create a 'revision.counter' file, it's initial counter is 0. And for every write to the replica, the counter in 'revision.counter' file will be increased by 1. And Longhorn Engine will use these counters to make sure all replcias are consistent during start time. Also for salvage recovering, will use these counters to decide which replica has the latest update.

Disable Revision Counter is an option to boost Longhorn performance which doesn't keep tracking every write on replicas, but lose the strong tracking for each replica. If some user prefers higher performance and have a stable network infrastructure(e.g. internal network) with enough CPU resourse. This option can help in such case. During Longhorn Engine start time, it will skip checking the revision counter for all replicas. But Longhorn still support auto-salvage through the replica's head file stat. By default the revision counter is enabled.

> **Note:** 'Salvage' is Longhorn trying to recover a 'Faulted' state volume(Longhorn Engine lost the connection to all the replicas, and mark all replicas as 'ERR' state).


# Disable Revision Counter
## Using Longhorn UI
The 'Disable Revision Counter' setting can be found in the Longhorn UI:

Setting -> General -> Disable Revision Counter

User can enable or disable the revision counter by unselect or select the setting.

And in 'Volume' page, once click 'Create Volume' button, user can customize individual volume setting against the general setting.

## Using manifest file.

User can define customize 'StorageClass' and add 'disableRevisionCounter' parameter to it. By default disableRevisionCounter' is false, which the revision counter is enabled.

    * Set 'disableRevisionCounter' to true to disable revision counter

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

## Auto-Salvage support with revision counter disabled
The logic for auto-salvage is different when the revision counter is disabled.

When revision counter is enabled and all the replicas in the volume are in 'ERR' state, the engine controller will be in faulted state, and for engine to recover the volume, it will get the replica with the largest revisiion counter as 'Source of Truth' to rebuild the rest replicas.

When reivision counter is disabled in this case, the engine controller will get the all replicas' 'volume-head-xxx.img' last modified time and head file size. And do the following steps:
1. Based on 'volume-head-xxx.img' last modified time, to get the latest one and any one within 5 second can be put in the candidate replicas for now.
2. Compare the head file size for all the candidate replicas, pick the one with the largest file size as the 'Source of Truth'.
3. Only mark the 'Source of Truth' replica to 'RW' mode, the rest of replicas would be marked as 'ERR' mode. Rebuild replicas base on the 'Source of Truth' replica.
