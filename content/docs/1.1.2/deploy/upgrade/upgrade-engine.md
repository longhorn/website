---
title: Manually Upgrading Longhorn Engine
weight: 2
---

In this section, you'll learn how to manually upgrade the Longhorn Engine from the Longhorn UI.

### Prerequisites

Always make backups before upgrading the Longhorn engine images.

Upgrade the Longhorn manager before upgrading the Longhorn engine.

> **Note:**
> There is a bug in the instance manager image `v1_20201216` shipped in Longhorn v1.1.0 and v1.1.1
> which can lead to a deadlock in a big cluster with hundreds of volumes.
> See more details [here](https://github.com/longhorn/longhorn/issues/2697).
> Longhorn v1.1.2 is shipped with a new instance manager image `v1_20210621` which fixed the deadlock
> but engine/replica processes of volumes don't migrate from old instance manager to new instance manager
> until the next time the volumes are detached/attached because Longhorn doesn't want to interrupt the
> data plane of the volumes.
>
> To reduce the chance of hitting the deadlock while the engine/replica processes are still in the old instance manager,
> you should upgrade engine for volumes in small batches, e.g., upgrading 2 or 3 volumes at a time.

### Offline Upgrade

Follow these steps if the live upgrade is not available, or if the volume is stuck in degraded state:

1. Follow [the detach procedure for relevant workloads](../../../volumes-and-nodes/detaching-volumes).
2. Select all the volumes using batch selection. Click the batch operation button **Upgrade Engine**, and choose the engine image available in the list. It's the default engine shipped with the manager for this release.
3. Resume all workloads. Any volume not part of a Kubernetes workload must be attached from the Longhorn UI.

### Live upgrade

Live upgrade is supported for upgrading from v1.1.x to v{{< current-version >}}.

The `iSCSI` frontend does not support live upgrades.

Live upgrade should only be done with healthy volumes.

1. Select the volume you want to upgrade.
2. Click `Upgrade Engine` in the drop down.
3. Select the engine image you want to upgrade to.
    1. Normally it's the only engine image in the list, since the UI exclude the current image from the list.
4. Click OK.

During the live upgrade, the user will see double number of the replicas temporarily. After upgrade complete, the user should see the same number of the replicas as before, and the `Engine Image` field of the volume should be updated.

Notice after the live upgrade, Rancher or Kubernetes would still show the old version of image for the engine, and new version for the replicas. It's expected. The upgrade is success if you see the new version of image listed as the volume image in the Volume Detail page.

### Clean up the old image

After you've done upgrade for all the images, select `Settings/Engine Image` from Longhorn UI. Now you should able to remove the non-default image.
