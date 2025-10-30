---
title: Interrupt Mode Support
weight: 20
aliases:
- /spdk/features/interrupt-support.md
---

Starting with v1.10.0, Longhorn supports **SPDK interrupt mode** for V2 data engine volumes. Interrupt mode provides an alternative to the default **polling mode**, offering improved CPU efficiency in certain environment.

Interrupt mode is particularly suitable for clusters with limited CPU resources and a relatively small number of volumes. While polling mode maximizes performance by keeping CPU utilization close to 100% on allocated cores, interrupt mode reduces CPU usage by allowing the SPDK reactor to adjust its usage dynamically instead of continuously polling.

## Overview

### Polling Mode vs Interrupt Mode

**Polling Mode (Default)**:
- Continuously polls for I/O operations
- Provides the lowest latency
- Consumes ~100% of the allocated CPU core at all times
- Best suited for high-performance workloads with frequent I/O

**Interrupt Mode**:
- Uses interrupt-driven I/O handling
- CPU consumption scales with the number of attached volumes
- Better suited for resource-constrained environments

## Prerequisites

- Longhorn v1.10.0 or later
- V2 data engine enabled
- No attached v2 volumes when changing the setting
- For NVMe disks, IOMMU must be enabled. To verify:
    ```bash
    find /sys/kernel/iommu_groups/ -type l
    ```
    Example output (IOMMU enabled):
    ```
    /sys/kernel/iommu_groups/0/devices/0000:e6:0b.1
    /sys/kernel/iommu_groups/1/devices/0000:34:0a.6
    /sys/kernel/iommu_groups/2/devices/0000:a0:00.0
    ```
    If the command returns no output, IOMMU is not enabled.

    > **Note:** IOMMU support may not be exposed on virtualized instances. If unsure, consider using a bare-metal instance, or consult your cloud provider’s documentation or support team.

    For more information, see the official [SPDK documentation](https://spdk.io/doc/system_configuration.html).

## Configuration

### Global Setting

To enable interrupt mode globally, update the [data-engine-interrupt-mode-enabled](../../../references/settings#data-engine-interrupt-mode-enabled) setting.

### Important Considerations

- **Volume State Requirement**: The setting can only be changed when no V2 volumes are attached. Longhorn blocks updates if any V2 volume is active.
- **Global Effect**: The setting applies to all V2 volumes.

## Performance Characteristics

### Recommended Use Cases

Enable interrupt mode when:
- Running in resource-constrained clusters
- Managing only a small number of volumes
- CPU resources are limited or shared with other workloads
- I/O patterns are sporadic rather than continuous
- Energy efficiency is a priority

## Limitations

### Hybrid Implementation

The current V2 volume interrupt mode uses a hybrid approach for NVMe/TCP transport:

- **Admin Queue Operations**: Still relies on periodic polling for keepalive and controller recovery
- **I/O Queue Completion**: Uses polling for command completion
- **Residual CPU Usage**: Results in a small but constant CPU load, even when attach volumes are idle

### Performance Trade-offs

- **Latency**: Slightly higher than polling mode

### Operational Restrictions

- **Setting Changes**: Cannot be modified while V2 volumes are attached
- **Global Scope**: Applies globally; no per-volume override is available

### Disk Support

- Interrupt mode currently supports AIO disks only.
