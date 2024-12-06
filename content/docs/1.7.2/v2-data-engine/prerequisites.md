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

  v6.7 or later is recommended for improved system stability
  > **NOTICE**
  >
  > Memory corruption may occur on hosts using versions of the Linux kernel earlier than 6.7, as highlighted by this SPDK upstream issue: https://github.com/spdk/spdk/issues/3116#issuecomment-1890984674. In Longhorn environments the kernel panic can be caused by prevalent IO timeouts in communications between the `nvme_tcp` driver and SPDK. Update the Linux kernel on Longhorn nodes to version 6.7 or later to prevent the issue from occurring.

- Linux kernel modules
  - `vfio_pci`
  - `uio_pci_generic`
  - `nvme_tcp`

- Huge page support
  - 2 GiB of 2 MiB-sized pages

## Notice

### CPU

When the V2 Data Engine is enabled, each instance-manager pod utilizes **1 CPU core**. This high CPU usage is attributed to the `spdk_tgt` process running within each instance-manager pod. The spdk_tgt process is responsible for handling input/output (IO) operations and requires intensive polling. As a result, it consumes 100% of a dedicated CPU core to efficiently manage and process the IO requests, ensuring optimal performance and responsiveness for storage operations.

### Memory

SPDK leverages huge pages for enhancing performance and minimizing memory overhead. You must configure 2 MiB-sized huge pages on each Longhorn node to enable usage of huge pages. Specifically, 1024 pages (equivalent to a total of 2 GiB) must be available on each Longhorn node.


### Disk

SPDK leverages kernel drivers to support every kind of disk that Linux supports. However, SPDK is equipped with a user space NVMe driver that provides zero-copy, highly parallel, direct access to an SSD from a user space application. Because of this, using **local NVMe disks** is highly recommended for enabling V2 volumes to achieve optimal storage performance.
