---
title: Huge Page Configuration
weight: 20
---

The V2 Data Engine uses SPDK, which by default allocates memory through huge pages for better performance. Longhorn allows you to configure the memory allocation size or disable huge pages entirely and use anonymous (legacy) memory instead.

## Settings

- [`data-engine-hugepage-enabled`](../../../references/settings#data-engine-hugepage-enabled)
- [`data-engine-memory-size`](../../../references/settings#data-engine-memory-size)

## Using Huge Pages (Default)

When huge pages are enabled, you must pre-allocate huge pages on each node that runs V2 volumes.

### Pre-allocate Huge Pages on Nodes

The total huge page allocation on each node must be at least equal to the `data-engine-memory-size` value (default 2048 MiB). For detailed steps on enabling and verifying huge pages, see [Enable HugePages](../../../deploy/install#enable-hugepages).

### Adjust Memory Size

Before adjusting the memory size, ensure that the huge page allocation on each node is sufficient to meet the new memory requirement.

To change the memory allocated to the SPDK target daemon, update the `data-engine-memory-size` setting. For example, set the value of the setting to `{"v2":"4096"}` to allocate 4096 MiB of memory.

> **Note**: Changing this setting requires all V2 volumes to be detached. The instance manager pods will be restarted with the new memory allocation.

## Disabling Huge Pages (Using Anonymous Memory)

If huge pages are not available or not desired on your nodes, you can disable huge pages and use anonymous (legacy) memory instead by setting `data-engine-hugepage-enabled` to `{"v2":"false"}`.

When huge pages are disabled:
- SPDK uses anonymous (legacy) memory allocation instead of huge pages.
- No `hugepages-2Mi` resource limit is set on the instance manager container.
- The `data-engine-memory-size` setting still defines how much memory SPDK preallocates.

> **Note**:
>
> Disabling huge pages reduces memory pressure on low-spec nodes and increases deployment flexibility. However, performance may be lower compared to running with huge pages.
