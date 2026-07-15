---
title: V2 Data Engine
weight: 110
---

The Longhorn V2 Data Engine is built on the Storage Performance Development Kit (SPDK) and uses NVMe-oF (NVMe over Fabrics) for high-performance, kernel-bypass storage I/O.

## Features

- [Selective V2 Data Engine Activation](./selective-v2-data-engine-activation)
- [Configurable CPU Cores](./configurable-cpu-cores)
- [Hugepage Configuration](./hugepage-configuration)
- [Interrupt Mode](./interrupt-mode)
- [ublk Frontend Support](./ublk-frontend-support)
- [RDMA Transport Support](./rdma-transport)
- [Per-Node V2 Configuration Labels](./node-labels)
- [Shallow Copy and Deep Copy](./shallow-deep-copy)

## Transport Options

The V2 Data Engine supports two NVMe-oF transport protocols:

- **TCP** (default) — works on any network, no special hardware required
- **RDMA** — requires RDMA-capable hardware (e.g., Mellanox ConnectX with RoCE v2), provides lower latency and reduced CPU overhead

See [RDMA Transport Support](./rdma-transport) for details on enabling RDMA.

## Efficient Rebuilds

Replica rebuilds use SPDK's shallow copy and range shallow copy primitives, copying only allocated clusters rather than the full volume. See [Shallow Copy and Deep Copy](./shallow-deep-copy) for details.
