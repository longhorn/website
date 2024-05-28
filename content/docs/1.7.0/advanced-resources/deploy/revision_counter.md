---
title: Revision Counter
weight: 7
---

The revision counter is a mechanism that Longhorn uses to track each replica's updates.

During replica creation, Longhorn will create a 'revision.counter' file with its initial counter set to 0. And for every write to the replica, the counter in 'revision.counter' file will be increased by 1.

The Longhorn engine uses these counters as a heuristic for achieving best-effort consistency among replicas during startup. Note that because the write IOs in Longhorn are parallel, enabling the revision counter does not guarantee data consistency. Longhorn also uses these counters during auto-salvage to identify the replica with the latest update.

Disable Revision Counter is an option in which every write on replicas is not tracked. When this setting is used, performance is improved. This option can be helpful if you prefer higher performance and have a stable network infrastructure (e.g. an internal network) with enough CPU resources. When the revision counter is disabled, the Longhorn Engine skips checking the revision counter for all replicas at startup. However, auto-salvage still functions because Longhorn can use the replica's head file stat to identify the replica to be used for recovery. For more information about how auto-salvage functions without the revision counter, see [Auto-Salvage Support with Revision Counter Disabled](#auto-salvage-support-with-revision-counter-disabled).

By default, the revision counter is disabled.

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
1. Identify the replica with the most recent last modified timestamp based on when `volume-head-xxx.img` was last modified
1. Select all replicas with last modified timestamp within 5s of the above replica's last modified timestamp
2. From the replica candidates from the above step, compare the head file size of the candidates, and pick the ones with the largest file size
1. From the replica candidates from the above step, pick the best replica with most recent modified timestamp
3. Change the best replica to 'RW' mode, and the other replicas are marked as 'ERR' mode. The errored replicas are rebuilt based on the best replica
