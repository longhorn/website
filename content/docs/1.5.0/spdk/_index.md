---
title: V2 Data Engine (Preview Feature)
weight: 3
---

## Platform Support

Currently, V2 Data Engine only supports `x86_64` platform.

## Feature Support

- Volume lifecycle (creation, attachment, detachment and deletion)
- Degraded volume
- Offline replica rebuilding
- Block disk management
- Orphaned replica management

In addition to the features mentioned above, additional functionalities such as replica number adjustment, online replica rebuilding, snapshot, backup, restore and so on will be introduced in future versions.

## Prerequisites

- x86-64 CPU with SSE4.2 instruction support

- Required linux kernel modules
  - uio
  - uio_pci_generic
  - nvme-tcp

- HugePage support
  - 1 GiB of 2 MiB-sized pages

## Notice

### CPU

When the V2 Data Engine is enabled, each instance-manager pod utilizes **1 CPU core**. This high CPU usage is attributed to the `spdk_tgt` process running within each instance-manager pod. The spdk_tgt process is responsible for handling input/output (IO) operations and requires intensive polling. As a result, it consumes 100% of a dedicated CPU core to efficiently manage and process the IO requests, ensuring optimal performance and responsiveness for storage operations.

### Memory

SPDK utilizes huge pages to enhance performance and minimize memory overhead. To enable the usage of huge pages, it is necessary to configure 2MiB-sized huge pages on each Longhorn node. Specifically, **512 pages (equivalent to a total of 1 GiB)** need to be available on each Longhorn node.