---
title: Upgrading Longhorn Engine
weight: 2
---

In this section, you'll learn how to upgrade the Longhorn Engine from the Longhorn UI.

If the live upgrade is not available, or if a volume is stuck in a degraded state, do an [offline upgrade.](#offline-upgrade)

### Prerequisites

Always make backups before upgrading the Longhorn engine images.

Upgrade the Longhorn manager before upgrading the Longhorn engine.

### Live Upgrade

Live upgrades are supported for upgrading from v1.0.0/v1.0.1 to v1.0.2.

The `iSCSI` frontend does not support live upgrades.

Live upgrades should only be done with healthy volumes.

1. Select the volume you want to upgrade.
2. Click `Upgrade Engine` in the dropdown menu.
3. Select the engine image you want to upgrade to. Normally it's the only engine image in the list, since the UI excludes the current image from the list.
4. Click OK.

During the live upgrade, you will temporarily see double the number of replicas.

After the upgrade is complete, you should see the same number of replicas as before, and the `Engine Image` field of the volume should be updated.

Notice that after the live upgrade, Rancher or Kubernetes will still show the old version of the image for the engine, and the new version for the replicas. It's expected. The upgrade is successful if you see the new version of image listed as the volume image in the Volume Detail page.

### Offline Upgrade

Follow these steps if the live upgrade is not available, or if the volume is stuck in a degraded state:

1. Follow [the detach procedure for relevant workloads](../../../volumes-and-nodes/detaching-volumes).
2. Select all the volumes using batch selection. Click the batch operation button **Upgrade Engine**, and choose the engine image available in the list. It's the default engine shipped with the manager for this release.
3. Resume all workloads. Any volume not part of a Kubernetes workload must be attached from the Longhorn UI.

### Clean up the Old Image

After you've done an upgrade for all the images, select `Settings/Engine Image` from Longhorn UI. Now you should able to remove the non-default image.
