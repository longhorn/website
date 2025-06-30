---
title: "Troubleshooting: Storage Network CSI Plugin Restart Triggers Unintended Restart of RWX Migratable Volume Workload"
authors:
- "Chin-Ya Huang"
draft: false
date: 2025-06-30
versions:
- "v1.7.x"
- "v1.8.0-v1.8.2"
- "v1.9.0"
categories:
- "storage network"
- "rwx volume"
---

## Applicable versions

* All Longhorn v1.7.x versions
* Longhorn v1.8.x versions **prior to** v1.8.3
* Longhorn v1.9.0

## Symptoms

When both the storage network and the `storage-network-for-rwx-volume-enabled` setting are enabled, restarting the CSI plugin pod causes workloads using **migratable RWX volumes** to restart unexpectedly.

## Root Cause

This issue is due to a bug in the storage network support for RWX volumes. Since Longhorn RWX volumes are not true NFS-based volumes, restarting the CSI plugin should **not** trigger a workload restart.

#### Workaround

This bug is resolved in:
- **Longhorn v1.8.3 and later**
- **Longhorn v1.9.2 and later**

If you are using an affected version, consider the following workarounds:

1. **Disable** the `storage-network-for-rwx-volume-enabled` setting to revert RWX volumes to use the cluster network.
1. **Disable** the `auto-delete-pod-when-volume-detached-unexpectedly` setting.
    > **Warning**
    > Be sure to review the [limitation](../../docs/1.9.0/advanced-resources/deploy/storage-network/#limitation) of this approach before applying it.

## Related information

- GitHub Issue: [#1158](https://github.com/longhorn/longhorn/issues/11158)
