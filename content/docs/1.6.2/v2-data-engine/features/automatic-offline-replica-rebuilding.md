---
title: Automatic Offline Replica Rebuilding
weight: 10
aliases:
- /spdk/automatic-offline-replica-rebuilding.md
---

Longhorn currently does not support online replica rebuilding for volumes that use the V2 Data Engine. To overcome this limitation, an automatic offline replica rebuilding mechanism has been implemented. When a degraded volume is detached, Longhorn attaches the volume in maintenance mode and then initiates the rebuilding process. The volume is detached again once rebuilding is completed.

## Settings

### Global Settings

- **offline-replica-rebuilding**: Setting that allows rebuilding of offline replicas for volumes using the V2 Data Engine. This setting is enabled by default.

### Volume-Specific Settings

- **Volume.Spec.OfflineReplicaRebuilding**: Setting that allows rebuilding of offline replicas for a specific volume. The default value is "ignored", which allows Longhorn to apply the value of the global setting `offline-replica-rebuilding`. (Options: "ignored", "disabled", "enabled")

## Notice

Interruptions are possible during offline replica rebuilding because Longhorn ensures that critical tasks take precedence. When an application attempts to attach a volume that is undergoing rebuilding, the rebuilding task is canceled to make way for the higher-priority task. 