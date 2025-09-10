---
title: "Troubleshooting: Backing Image Download Stuck After Node Disconnection"
authors:
- "Raphanus Lo"
draft: false
date: 2025-09-10
versions:
- "v1.9.2 and earlier versions"
- "v1.10.0"
categories:
- "Backing image"
---

## Applicable Versions

- v1.9.2 and earlier versions
- v1.10.0

## Symptoms

A backing image (BI) is created and begins downloading from a remote HTTP server. During this process, a backing image data source (BIDS) is also created to manage the image file download, which in turn launches a downloader pod. However, if the BIDS custom resource (CR) is later rescheduled to a different node, the downloader pod and the BIDS CR may end up on different nodes.

For example:

```bash
$ kubectl -n longhorn-system get po backing-image-ds-${BACKING_IMAGE_NAME} -o jsonpath="{.spec.nodeName}"

longhorn-node1

$ kubectl -n longhorn-system get backingimagedatasource.longhorn.io ${BACKING_IMAGE_NAME} -o jsonpath="{.spec.nodeID}"

longhorn-node2
```

In this state, the BIDS CR remains empty, as shown below:

```bash
$ kubectl -n longhorn-system get backingimagedatasource.longhorn.io ${BACKING_IMAGE_NAME}

NAME                 UUID       STATE   SOURCETYPE   SIZE   NODE   DISKUUID                               AGE
BACKING_IMAGE_NAME   8c72eeb1           download     0      node2  837c7163-3575-4094-9023-9b223f409dc8   1h
```

Additionally, the backing image cannot be removed.

## Root Cause

The BIDS controller manages the creation, monitoring, and deletion of the downloader pod. It regularly polls the image download status from a downloader pod running on the same node and updates the corresponding BIDS CR. The downloader pod is only deleted when the download succeeds or fails.

When a node disconnects from the cluster, the BIDS CR is automatically rescheduled to a new node, which is different from the node running the existing downloader pod. This rescheduling leads to a specific issue:

- The downloader pod remains running on the original, disconnected node, which prevents the BIDS controller on the new node from creating a new downloader pod.
- The BIDS controller on the original node loses control of the BIDS CR due to the disconnection. As a result, it is unable to update the CR's status.
- Both the BI and BIDS resources become stuck because deletion is blocked. The BI CR cannot be deleted because it is still referenced by the BIDS CR, and the BIDS CR cannot be deleted because its download state is never updated to "failed", which prevents cleanup.

This situation leads to a state where the BIDS remains empty, and the backing image resource cannot be removed.

## Mitigation

To resolve the issue, manually delete the downloader pod:

```bash
kubectl -n longhorn-system delete pod backing-image-ds-${BACKING_IMAGE_NAME}
```

This action triggers the creation of a new downloader pod on the correct node. As a result, the backing image and BIDS resources can be deleted as expected.

## Related Information

- [Longhorn Issue #11622](https://github.com/longhorn/longhorn/issues/11622): Original issue documenting this failure.
