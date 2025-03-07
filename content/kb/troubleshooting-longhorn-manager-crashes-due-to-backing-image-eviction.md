---
title: "Troubleshooting: Longhorn Manager Crashes Due To Backing Image Eviction"
authors:
- "Jack Lin"
draft: false
date: 2025-03-07
versions:
- "v1.7.0-v1.7.3 and v1.8.0"
categories:
- "longhorn manager"
---

## Applicable versions

v1.7.0-v1.7.3 and v1.8.0

## Symptoms

Longhorn-Manager might repeatedly crash, causing disruptions in storage management operations. The logs indicate that the crash is due to a nil pointer dereference in the function `syncBackingImageEvictionRequested()`.

## Root Cause

The issue occurs due to a race condition between the deletion of a disk in the backing image spec and the update of its corresponding status. The following sequence explains the root cause:

1. Longhorn attempts to clean up unused backing images on a disk, which results in the disk being deleted from the backing image spec.
2. The backing image status, however, is not immediately updated to reflect this deletion.
3. When the node or disk `EvictionRequested` flag is set to true, the function `syncBackingImageEvictionRequested()` is triggered to evict the backing image on that node or disk.
4. The function builds a lookup map of disks and their corresponding backing images based on the outdated backing image status.
5. When the function attempts to update `backingImage.spec.evictionRequested` for the evicted disk, it encounters a nil pointer, causing the longhorn-manager to crash.

## Workaround

To mitigate the issue and restore stability, follow these steps:

1. Set all EvictionRequested flags to false to prevent the eviction process from triggering the crash.
2. Wait for the disk cleanup process to complete and ensure that the backing image status is fully updated.
3. Once the cleanup is finished, resume the eviction process by setting EvictionRequested flags back to true as needed.

This workaround will allow the longhorn-manager to stabilize and prevent further crashes while ensuring that the eviction process can continue once the backing image status is consistent.

## Fixed Versions

Longhorn v1.8.1+

## Reference

https://github.com/longhorn/longhorn/issues/10464