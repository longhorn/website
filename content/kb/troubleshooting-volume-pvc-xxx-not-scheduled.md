---
title: "Troubleshooting: `volume pvc-xxx not scheduled`"
author: Sheng Yang
draft: false
date: 2020-10-22
catelogies:
  - "scheduling"
  - "csi"
---

## Applicable versions
All Longhorn versions.

## Symptoms

When creating a Pod with Longhorn Volume as PVC, the Pod cannot start.

When checking for error message using `kubectl describe <pod>`, the following message is shown:

```
Warning  FailedAttachVolume  4m29s (x3 over 5m33s)  attachdetach-controller     AttachVolume.Attach failed for volume "pvc-xxx" : rpc error: code = Internal desc = Bad response statusCode [500]. Status [500 Internal Server Error]. Body: [message=unable to attach volume pvc-xxx to node-xxx: volume pvc-xxx not scheduled, code=Server Error, detail=] from [http://longhorn-backend:9500/v1/volumes/pvc-xxx?action=attach]

```

Noticed the message returned by Longhorn in the error above:
```
unable to attach volume pvc-xxx to node-xxx: volume pvc-xxx not scheduled
```

## Details

This is caused by Longhorn cannot find enough spaces on different nodes to store the data for the volume, which result in the volume scheduling failure.

### Most common reason
For Longhorn v1.0.x, the default Longhorn installation has following settings:
1. `Node Level Soft Anti-affinity: false`.
1. The default StorageClass `longhorn`'s Replica count is set to `3`.

That means Longhorn will always try to allocate enough space on three different nodes for three replicas.

If this requirement cannot be satisfied, e.g. due to there are less than 3 nodes in the cluster, the volume scheduling will fail.

#### Solution
If this is the case, you can:
1. either set [`Node Level Soft Anti-affinity` to `true`](https://longhorn.io/docs/1.0.2/references/settings/#replica-node-level-soft-anti-affinity).
2. or, create [a new StorageClass](https://longhorn.io/docs/1.0.2/references/examples/#storageclass) with replica count set to `1` or `2`.
3. or, adding more nodes to your cluster.

### Other reasons
See [scheduling section in the Longhorn doc](https://longhorn.io/docs/1.0.2/volumes-and-nodes/scheduling/) for a detail description of the scheduling policy.

## Related information
Starting Longhorn v1.1.0, we will introduce a new setting `Allow Volume Creation With Degraded Availability`(`true` by default) to help with the use case on smaller cluster.

See https://github.com/longhorn/longhorn/issues/1701 for details.
