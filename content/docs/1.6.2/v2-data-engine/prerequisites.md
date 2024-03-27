---
title: Prerequisites
weight: 1
aliases:
- /spdk/prerequisites.md
---

## Prerequisites

Longhorn nodes must meet the following requirements:

- AMD64 or ARM64 CPU
  > **NOTICE**
  >
  >  AMD64 CPUs require SSE4.2 instruction support.

- Linux kernel

  5.19 or later is required for NVMe over TCP support
  > **NOTICE**
  >
  > Host machines with Linux kernel 5.15 may unexpectedly reboot when volume-related IO errors occur. Update the Linux kernel on Longhorn nodes to version 5.19 or later to prevent such issues.

- Linux kernel modules
  - uio
  - uio_pci_generic
  - nvme-tcp

- Huge page support
  - 2 GiB of 2 MiB-sized pages

## Notice

### CPU

When the V2 Data Engine is enabled, each instance-manager pod utilizes **1 CPU core**. This high CPU usage is attributed to the `spdk_tgt` process running within each instance-manager pod. The spdk_tgt process is responsible for handling input/output (IO) operations and requires intensive polling. As a result, it consumes 100% of a dedicated CPU core to efficiently manage and process the IO requests, ensuring optimal performance and responsiveness for storage operations.

### Memory

SPDK leverages huge pages for enhancing performance and minimizing memory overhead. You must configure 2 MiB-sized huge pages on each Longhorn node to enable usage of huge pages. Specifically, 1024 pages (equivalent to a total of 2 GiB) must be available on each Longhorn node.


### Disk

**Local NVMe disks** are highly recommended for optimal storage performance of volumes using V2 Data Engine.