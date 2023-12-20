---
title: "Space consumption guideline"
author: Shuo Wu
draft: false
date: 2023-08-25
categories:
- "instruction"
---

## Applicable versions

All Longhorn versions, but some features are introduced in v1.4.0 or v1.5.0

## Volumes consume much more space than expected

Due to the fact that Longhorn volumes can hold historic data as snapshots, the volume actual size can be much greater than the spec size. For more details, you can check [this section](../../docs/1.5.1/volumes-and-nodes/volume-size/#volume-actual-size) for a better understanding over the concept of volume size.

Besides, some operations like backup, rebuilding, or expansion, will lead to a hidden system snapshot creation. Hence, there may be some snapshots even if users never create a snapshot for a volume manually.

To eliminate space being wasted the historic data/snapshots, we would recommend applying a recurring job like `snapshot-delete` that limits the snapshot counts of volumes. You can check [the recurring job section](../../docs/1.5.1/snapshots-and-backups/scheduling-backups-and-snapshots) and see how to work.

## Filesystem used size is much smaller than volume actual size

The reason for this symptom is explained in [the volume size section](../../docs/1.5.1/volumes-and-nodes/volume-size/#volume-actual-size) as well. Briefly, a Longhorn volume is a block device which does not recognize the filesystem used on top of it. Deleting a file is a filesystem layer operation that does not actually free up blocks from the underlying volume.

In order to ask the volume or the block device to release the blocks for removed files, you can rely on `fstrim`. This `trim` operation is introduced since Longhorn v1.4.0. Please see [this section](../../docs/1.5.1/volumes-and-nodes/trim-filesystem) for details.

If you make the trim operation automatic, you can apply `filesystem-trim` recurring jobs for volumes. But notice that this operation is similar to write operations, which may be resource-consuming. Please do not trigger the trim operations for lots of volumes at the same time.

## Disk exhaustion

In this case, the node is probably marked as NotReady due to the disk pressure. Therefore, the most critical measure is to recover the node while avoiding losing volume data.

To do recover nodes and disk, we would recommend directly removing some redundant replica directories for the full disk. Here redundant replicas means that the corresponding volumes have healthy replicas in other disks. Later on Longhorn will automatically rebuild new replicas in other disks if possible.
Besides, users may need to expand the existing disks or add more disks to avoid future disk exhaustion issues.

Notice that the disk exhaustion may be caused by replicas being unevenly scheduled. Users can check [setting Replica Auto Balance](../../docs/1.5.1/high-availability/auto-balance-replicas) for this scenario.

