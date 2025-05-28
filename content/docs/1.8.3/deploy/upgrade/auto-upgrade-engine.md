---
title: Automatically Upgrading Longhorn Engine
weight: 3
---

Since Longhorn v1.1.1, we provide an option to help you automatically upgrade Longhorn volumes to the new default engine version after upgrading Longhorn manager.
This feature reduces the amount of manual work you have to do when upgrading Longhorn.
There are a few concepts related to this feature as listed below:

#### 1. Concurrent Automatic Engine Upgrade Per Node Limit Setting

This is a setting that controls how Longhorn automatically upgrades volumes' engines to the new default engine image after upgrading Longhorn manager.
The value of this setting specifies the maximum number of engines per node that are allowed to upgrade to the default engine image at the same time.
If the value is 0, Longhorn will not automatically upgrade volumes' engines to the default version.
The bigger this value is, the faster the engine upgrade process finishes.

However, giving a bigger value for this setting will consume more CPU and memory of the node during the engine upgrade process.
We recommend setting the value to 3 to leave some room for error but don't overwhelm the system with too many failed upgrades.

#### 2. The behavior of Longhorn with different volume conditions.
In the following cases, assume that the `concurrent automatic engine upgrade per node limit` setting is bigger than 0.

1. Attached Volumes

   If the volume is in attached state and healthy, Longhorn will automatically do a live upgrade for the volume's engine to the new default engine image.

1. Detached Volumes

   Longhorn automatically does an offline upgrade for detached volume.

1. Disaster Recovery Volumes

   Longhorn doesn't automatically upgrade [disaster recovery volumes](../../../snapshots-and-backups/setup-disaster-recovery-volumes/) to the new default engine image because it would trigger a full restoration for the disaster recovery volumes.
The full restoration might affect the performance of other running Longhorn volumes in the system.
So, Longhorn leaves it to you to decide when it is the good time to manually upgrade the engine for disaster recovery volumes (e.g., when the system is idle or during the maintenance time).

   However, when you activate the disaster recovery volume, it will be activated and then detached.
At this time, Longhorn will automatically do offline upgrade for the volume similar to the detached volume case.

#### 3. What Happened If The Upgrade Fails?
If a volume failed to upgrade its engine, the engine image in volume's spec will remain to be different than the engine image in the volume's status.
Longhorn will continuously retry to upgrade until it succeeds.

If there are too many volumes that fail to upgrade per node (i.e., more than the `concurrent automatic engine upgrade per node limit` setting),
Longhorn will stop upgrading volume on that node.
