---
title: SPDK Data Engine (Preview Feature)
weight: 3
---

## Platform Support

Currently, SPDK Data Engine only supports `x86_64` platform.

## Feature Support

- Volume lifecycle (creation, attachment, detachment and deletion)
- Degraded volume
- Offline replica rebuilding
- Block disk management
- Orphaned replica management

## Prerequisites

- x86-64 CPU with SSE4.2 instruction support

- Required linux kernel modules
  - uio
  - uio_pci_generic
  - nvme-tcp

- HugePage support
  - 1 GiB of 2 MiB-sized pages