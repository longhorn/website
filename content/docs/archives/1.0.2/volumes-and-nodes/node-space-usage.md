---
title: Node space usage
weight: 1
---

In this section, you'll have a better understanding of the space usage info presented by the Longhorn UI. 


### Whole cluster space usage

In `Dashboard` page, Longhorn will show you the cluster space usage info:

{{< figure src="/img/screenshots/volumes-and-nodes/space-usage-info-dashboard-page.png" >}}

`Schedulable`: The actual space that can be used for Longhorn volume scheduling.

`Reserved`: The space reserved for other applications and system.

`Used`: The actual space that has been used by Longhorn, system, and other applications.

`Disabled`: The total space of the disks/nodes on which Longhorn volumes are not allowed for scheduling.

### Space usage of each node

In `Node` page, Longhorn will show the space allocation, schedule, and usage info for each node:

{{< figure src="/img/screenshots/volumes-and-nodes/space-usage-info-node-page.png" >}}

Column `Size`: The **max actual available space** can be used by Longhorn volumes. It equals to the total disk space of the node minus reserved space. 

Column `Allocated`: The left number is the size that has been used for **volume scheduling**, and it does not mean the space has been used for Longhorn volume data store. The right number is the **max** size for volume scheduling, which the result of `Size` multiplying `Storage Over Provisioning Percentage`.(In the above illustration, `Storage Over Provisioning Percentage` is 500.) Hence, the difference between the 2 numbers (let's call it as the allocable space) determines if a volume replica can be scheduled to this node.

Column `Used`: The left part indicates the currently used space of this node. The whole bar indicates the total space of the node. 

Notice that the allocable space may be greater than the actual available space of the node when setting `Storage Over Provisioning Percentage` is greater than 100. If the volumes are heavily used and lots of historical data will be stored in the volume snapshots, please be careful about using a large value for this setting. For more info about the setting, see [here](../../references/settings/#storage-over-provisioning-percentage) for details. 
