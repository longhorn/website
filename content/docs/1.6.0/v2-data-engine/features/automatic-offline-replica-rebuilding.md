---
title: Automatic Offline Replica Rebuilding
weight: 10
---

Longhorn currently does not support online replica rebuilding for volumes that use the V2 Data Engine. To overcome this limitation, an automatic offline replica rebuilding mechanism has been implemented. When a degraded volume is detached, Longhorn attaches the volume in maintenance mode and then initiates the rebuilding process. The volume is detached again once rebuilding is completed.

## Settings

### Global Settings

- **offline-replica-rebuilding**: Setting that allows rebuilding of offline replicas for volumes using the V2 Data Engine. This setting is enabled by default.

### Volume-Specific Settings

- **Volume.Spec.OfflineReplicaRebuilding**: Setting that allows rebuilding of offline replicas for a specific volume. The default value is "ignored", which allows Longhorn to apply the value of the global setting `offline-replica-rebuilding`. (Options: "ignored", "disabled", "enabled")

## Notice

During the offline replica rebuilding process, it is important to note that interruptions are possible. In the case where a volume, which is undergoing rebuilding, is about to be attached by an application, the offline replica rebuilding task will be cancelled to prioritize the high-priority task. This mechanism ensures that critical tasks take precedence over the rebuilding process.