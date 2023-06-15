---
  title: Automatic Offline Replica Rebuilding
  weight: 2
---

## Introduction

Currently, Longhorn does not support online replica rebuilding for volumes that use the V2 Data Engine. To overcome this limitation, an automatic offline replica rebuilding mechanism has been implemented. When a degraded volume is detached, this mechanism attaches the volume in maintenance mode, and initiates the rebuilding process. Once the rebuilding is completed, the volume is detached as per the user's expectation.

## Settings

### Global Settings

- **offline-replica-rebuilding** <br>

    This setting allows users to enable the offline replica rebuilding for volumes using V2 Data Engine. The value is `enabled` by default, and available options are:

    - **disabled**
    - **enabled**

### Per-Volume Settings

Longhorn also supports the per-volume setting by configuring `Volume.Spec.OfflineReplicaRebuilding`. The value is `ignored` by default, so data integrity check is determined by the global setting `offline-replica-rebuilding`. `Volume.Spec.OfflineReplicaRebuilding` supports **ignored**, **disabled** and **enabled**. Each volume can have its offline replica rebuilding customized.

## Notice

During the offline replica rebuilding process, it is important to note that interruptions are possible. In the case where a volume, which is undergoing rebuilding, is about to be attached by an application, the offline replica rebuilding task will be cancelled to prioritize the high-priority task. This mechanism ensures that critical tasks take precedence over the rebuilding process.


