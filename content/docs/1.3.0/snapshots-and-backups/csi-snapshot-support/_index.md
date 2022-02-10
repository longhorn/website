---
title: CSI Snapshot Support
description: Creating and Restoring Longhorn Snapshots/Backups via the kubernetes CSI VolumeSnapshot mechanism
weight: 3
---

## History
- GitHub Issues:
  - https://github.com/longhorn/longhorn/issues/304
  - https://github.com/longhorn/longhorn/issues/2534
- Longhorn Enhancement Proposals:
  - https://github.com/longhorn/longhorn/blob/master/enhancements/20200904-csi-snapshot-support.md
  - https://github.com/longhorn/longhorn/blob/master/enhancements/20220110-extend-csi-snapshot-to-support-longhorn-snapshot.md
- Availability:
  - CSI VolumeSnapshot associated with Longhorn backup is available since v1.1.0
  - CSI VolumeSnapshot associated with Longhorn snapshot is available since v1.3.0

## Overview

In Kubernetes, a [CSI VolumeSnapshot](https://kubernetes.io/docs/concepts/storage/volume-snapshots/) represents a snapshot of a volume on a storage system.
When you create a CSI VolumeSnapshot, the storage system will take a snapshot of the corresponding volume.
You can then use the CSI VolumeSnapshot to create a new volume that has the same content as the content of the CSI VolumeSnapshot.

In Longhorn, there are 2 concepts related to the content of a volume at particular moment: [Longhorn snapshot](../../concepts/#24-snapshots) and [Longhorn backup](../../concepts/#3-backups-and-secondary-storage).
Longhorn snapshot is the content of a Longhorn volume at a particular moment. It is stored inside the cluster.
A Longhorn backup is associated with a Longhorn snapshot, but it is stored externally inside a [backup target](../backup-and-restore/set-backup-target/).

When you create a CSI VolumeSnapshot, you can specify whether the CSI VolumeSnapshot should be associated with a Longhorn snapshot (content is stored inside cluster) or a Longhorn backup (content is stored both inside the cluster and uploaded to an external backup target).

After installing the [prerequisite](./enable-csi-snapshot-support), you can see [CSI VolumeSnapshot Associated with Longhorn Snapshot](./csi-volume-snapshot-associated-with-longhorn-snapshot) and [CSI VolumeSnapshot Associated with Longhorn Backup](./csi-volume-snapshot-associated-with-longhorn-backup) for more detail about how to create/restore a CSI VolumeSnapshot and the perameters you can set.
