---
title: RDMA Transport Support
weight: 1
---

The Longhorn V2 data engine supports **RDMA (Remote Direct Memory Access)** transport for NVMe-oF replica connections, complementing the default TCP transport. RDMA enables direct memory-to-memory data transfer between the SPDK NVMe-oF target (replica) and initiator (engine frontend) without CPU involvement, reducing latency and CPU overhead for high-throughput workloads.

## Prerequisites

- RDMA-capable network hardware (e.g., Mellanox ConnectX-5/6/7 with RoCE v2)
- RDMA drivers installed on all nodes that will use RDMA transport
- SPDK built with RDMA support (`--with-rdma=mlx5_dv`)

## Enabling RDMA Transport

RDMA transport is automatically enabled on nodes that have RDMA-capable hardware and drivers. The longhorn-manager detects RDMA hardware and applies the `node.longhorn.io/nvmf-transport=rdma` node label automatically. No manual configuration is required.

To verify that a node has been labeled:

```bash
kubectl get nodes -o custom-columns=NAME:.metadata.name,TRANSPORT:.metadata.labels.node\.longhorn\.io/nvmf-transport
```

Nodes with RDMA hardware will show `rdma`; nodes without will show `tcp` or no label.

To manually override the automatic detection (e.g., to force TCP on a node with RDMA hardware):

```bash
kubectl label node <node-name> node.longhorn.io/nvmf-transport=tcp --overwrite
```

When a node is labeled `rdma`, the instance manager on that node:
1. Creates RDMA NVMe-oF listeners for all replicas
2. Connects to remote replicas via RDMA when the remote node also supports RDMA
3. Falls back to TCP for replicas on nodes that only support TCP

## Mixed Clusters

Longhorn supports mixed clusters where some nodes use RDMA and others use TCP:
- An engine on an RDMA node connects to RDMA-capable replicas via RDMA and TCP-only replicas via TCP
- An engine on a TCP node always uses TCP for all replica connections
- The transport type is reported per-replica in the `Engine` and `Replica` CRD status

## Verifying Transport Type

Check the transport type for a volume's replicas:

```bash
kubectl get engines.longhorn.io -n longhorn-system <engine-name> -o jsonpath='{.status.replicaStatusMap}' | jq .
```

Each replica entry includes a `transport` field indicating whether it is connected via `tcp` or `rdma`.

## Node Label Auto-Detection

The longhorn-manager automatically detects RDMA hardware on nodes and applies the `nvmf-transport` label. If RDMA hardware is later removed or drivers are unloaded, the label should be manually updated to `tcp` to prevent connection attempts on a non-functional RDMA path.

## Limitations

- RDMA transport is only available for the V2 data engine
- Dynamic transport switching for running volumes is not supported — volumes must be detached and reattached after changing the node label
- iWARP and non-RoCE RDMA protocols are not supported (focus on RoCE v2)