---
title: Recovering from a Full Disk
weight: 4
---

If one disk used by one of the Longhorn replicas is full, that replica will go to the error state, and Longhorn will rebuild another replica on another node/disk.

To recover from a full disk,

1. Disable the scheduling for the full disk.
    
    Longhorn should have already marked the disk as `unschedulable`.
    
    This step is to make sure the disk will not be scheduled to by accident after more space is freed up.

2. Identify the replicas in the error state on the disk using the Longhorn UI's disk page.
3. Remove the replicas in the error state.

## Recommended after Recovery

We recommend adding more disks or more space to the node that had this situation.