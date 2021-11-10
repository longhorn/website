---
title: Disaster Recovery Volumes
description: Help and potential gotchas associated with specific cloud providers.
weight: 4
---

A **disaster recovery (DR) volume** is a special volume that is mainly intended to store data in a backup cluster in case the whole main cluster goes down. Disaster recovery volumes are used to increase the resiliency of Longhorn volumes.

For a longer explanation of how DR volumes work, see the [concepts section.](../../concepts/#33-disaster-recovery-volumes)

For disaster recovery volume, `Last Backup` indicates the most recent backup of its original backup volume.

If the icon representing the disaster volume is gray, it means the volume is restoring the `Last Backup` and this volume cannot be activated. If the icon is blue, it means the volume has restored the `Last Backup`.

## Creating DR Volumes {#creating}

> **Prerequisites:** Set up two Kubernetes clusters. These will be called cluster A and cluster B. Install Longhorn on both clusters, and set the same backup target on both clusters. For help setting the backup target, refer to [this page.](../backup-and-restore/set-backup-target)

1. In the cluster A, make sure the original volume X has a backup created or has recurring backups scheduled.
2. In backup page of cluster B, choose the backup volume X, then create disaster recovery volume Y. It's highly recommended to use the backup volume name as the disaster volume name.
3. Longhorn will automatically attach the DR volume Y to a random node. Then Longhorn will start polling for the last backup of volume X, and incrementally restore it to the volume Y.
