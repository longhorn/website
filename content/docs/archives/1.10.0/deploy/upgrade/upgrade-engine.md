---
title: Manually Upgrading Longhorn Engine
weight: 2
---

In this section, you'll learn how to manually upgrade the Longhorn Engine from the Longhorn UI.

## Prerequisites

Always make backups before upgrading the Longhorn engine images.

Upgrade the Longhorn manager before upgrading the Longhorn engine.

## Offline Upgrade

Follow these steps if the live upgrade is not available, or if the volume is stuck in degraded state:

1. Follow [the detach procedure for relevant workloads](../../../nodes-and-volumes/volumes/detaching-volumes).
2. Select all the volumes using batch selection. Click the batch operation button **Upgrade Engine**, and choose the engine image available in the list. It's the default engine shipped with the manager for this release.
3. Resume all workloads. Any volume not part of a Kubernetes workload must be attached from the Longhorn UI.

## Live Upgrade

Live upgrade is supported when upgrading from v1.9.x to v{{< current-version >}}.

The `iSCSI` frontend does **not** support live upgrades.

Live upgrades should only be performed on **healthy volumes**.

1. Select the volume you want to upgrade.
2. Click **Upgrade Engine** from the dropdown menu.
3. Select the engine image you want to upgrade to.
   1. Normally, this is the only engine image available in the list, as the UI excludes the current engine image.
4. Click **OK**.

During the live upgrade, the user will see double number of the replicas temporarily. After upgrade complete, the user should see the same number of the replicas as before, and the `Engine Image` field of the volume should be updated.

For the liveness and cleanup of old instance manager pods during live upgrade, refer to the [Instance Manager Pods During Upgrade](../instance-manager-pods-during-upgrade) documentation.
