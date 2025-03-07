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

Longhorn Manager repeatedly crashes, disrupting storage management operations. The logs indicate that the crashes are caused by a nil pointer dereference in the function `syncBackingImageEvictionRequested()`.

## Root Cause

The issue is caused by a race condition between the deletion of a disk in the backing image spec and the updating of its status, as explained in the following sequence:

1. Longhorn attempts to clean up unused backing images on a disk, which results in the disk being deleted from the backing image spec. The backing image status is not immediately updated to reflect this deletion.
2. When the node or disk `EvictionRequested` flag is set to true, the function `syncBackingImageEvictionRequested()` is triggered to evict the backing image from that node or disk.
3. The function builds a lookup map of disks and their corresponding backing images based on the outdated backing image status.
4. The function encounters a nil pointer when attempting to update `backingImage.spec.evictionRequested` for the evicted disk, causing Longhorn Manager to crash.

## Workaround

To mitigate the issue and restore stability, follow these steps:

1. Set all `EvictionRequested` flags to `false` to prevent the eviction process from triggering the crash.
2. Wait for the disk cleanup process to complete, and ensure the backing image status is fully updated. You can verify this by using kubectl to retrieve all backing image CRs and checking if any disks appear in the status but are no longer present in the spec.
3. Resume the eviction process by setting the `EvictionRequested` flags back to `true` as necessary.

This workaround allows Longhorn Manager to stabilize itself, prevents further crashes, and ensures that the eviction process can continue once the backing image status is consistent.

## Fixed Versions

Longhorn v1.8.1+

## Reference

https://github.com/longhorn/longhorn/issues/10464