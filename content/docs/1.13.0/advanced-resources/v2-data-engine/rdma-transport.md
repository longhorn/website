---
title: RDMA Transport Support
weight: 1
---

The Longhorn V2 data engine supports **RDMA (Remote Direct Memory Access)** transport for NVMe-oF replica connections, complementing the default TCP transport. RDMA enables direct memory-to-memory data transfer between the SPDK NVMe-oF target (replica) and initiator (engine) without CPU involvement, reducing latency and CPU overhead for high-throughput workloads.

Phase 1 focuses on **RoCE v2**, an **explicit** per-node transport choice, and a **single transport per engine** for all replica connections during an attachment.

## Prerequisites

- RDMA-capable network hardware (e.g., Mellanox ConnectX-5/6/7 with RoCE v2)
- RDMA drivers installed on all nodes that will use RDMA transport
- SPDK built with RDMA support (`--with-rdma`)

## Enabling RDMA Transport

Label each node that should use RDMA:

```bash
kubectl label node <node-name> node.longhorn.io/nvmf-transport=rdma
```

To use TCP on a node (default), leave the label unset or set:

```bash
kubectl label node <node-name> node.longhorn.io/nvmf-transport=tcp --overwrite
```

Verify labels:

```bash
kubectl get nodes -o custom-columns=NAME:.metadata.name,TRANSPORT:.metadata.labels.node\.longhorn\.io/nvmf-transport
```

When a node is labeled `rdma`, the V2 instance manager on that node:

1. Runs with host networking and InfiniBand device access so SPDK can bind the RDMA transport
2. Creates RDMA NVMe-oF listeners for replicas (and may also advertise a TCP listener for mixed clusters)
3. Connects engines on that node to **all** replicas using RDMA for that attachment

There is no automatic hardware detection in phase 1 — apply the label only on nodes with working RDMA.

## Mixed Clusters

Longhorn supports mixed clusters where some nodes use RDMA and some use TCP:

- An engine on an RDMA-labeled node uses RDMA for every replica in that attachment
- An engine on a TCP node uses TCP for every replica in that attachment
- Replicas on RDMA nodes may advertise both RDMA and TCP addresses so TCP engines can still dial them

This is **not** mid-flight failover between transports, and it is **not** mixing RDMA and TCP within a single engine attachment. Changing a node's transport requires updating the label and reattaching affected volumes.

## Verifying Transport Type

Check the transport-qualified addresses / status for a volume's engine:

```bash
kubectl get engines.longhorn.io -n longhorn-system <engine-name> -o jsonpath='{.status.replicaStatusMap}' | jq .
```

## Related Configuration

Per-node SPDK resource overrides (CPU mask, memory size, interrupt mode, IM CPU request) are documented under [Per-Node V2 Configuration Labels](./node-labels). When `nvmf-transport=rdma`, interrupt mode is forced off.

## Limitations

- RDMA transport is only available for the V2 data engine
- Dynamic transport switching for running volumes is not supported — volumes must be detached and reattached after changing the node label
- iWARP and non-RoCE RDMA protocols are not supported (RoCE v2 only)
- Auto-detection of RDMA hardware is not part of phase 1
