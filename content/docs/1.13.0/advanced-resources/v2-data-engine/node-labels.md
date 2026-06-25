---
title: Per-Node V2 Configuration Labels
weight: 3
---

The Longhorn V2 data engine supports per-node configuration via Kubernetes node labels. These labels allow you to override cluster-wide settings on individual nodes, enabling heterogeneous configurations where different nodes have different CPU, memory, or transport requirements.

## Available Node Labels

| Label | Values | Description |
|-------|--------|-------------|
| `node.longhorn.io/nvmf-transport` | `tcp`, `rdma` | NVMe-oF transport type for the instance manager. Auto-detected by the longhorn-manager based on RDMA hardware. See [RDMA Transport Support](./rdma-transport). |
| `node.longhorn.io/spdk-cpu-mask` | Hex string (e.g. `0xFF`) | CPU mask for SPDK reactor threads. Overrides the cluster-wide `data-engine-cpu-mask` setting. |
| `node.longhorn.io/spdk-memory-size` | Decimal MiB (e.g. `16384`) | Hugepage memory size for SPDK in MiB. Overrides the cluster-wide `data-engine-memory-size` setting. |
| `node.longhorn.io/spdk-interrupt-mode` | `true`, `false` | Enable/disable SPDK interrupt mode. Overrides the cluster-wide `data-engine-interrupt-mode-enabled` setting. Forced to `false` when `nvmf-transport=rdma` (RDMA poll groups cannot use fd-based interrupt wakeup). |
| `node.longhorn.io/v2-im-cpu-request` | Cores (e.g. `4`) or millicores (e.g. `4000m`) | CPU request for the V2 instance manager pod on this node. Overrides the default CPU request. |
| `node.longhorn.io/disable-v2-data-engine` | `true`, `false` | Disable the V2 data engine on this node. See [Selective V2 Data Engine Activation](./selective-v2-data-engine-activation). |

## Precedence

Per-node labels take precedence over cluster-wide settings. The resolution order for each setting is:

1. **Per-node label** (highest priority) — if the node has the label, it overrides everything
2. **Per-IM spec override** — if set on the InstanceManager CR directly
3. **Cluster-wide setting** (lowest priority) — the global Longhorn setting

The exception is `spdk-interrupt-mode`: if `nvmf-transport=rdma`, interrupt mode is forced to `false` regardless of any other override, because SPDK's RDMA poll groups cannot use fd-based interrupt wakeup.

## Usage Examples

### Set SPDK CPU mask on a specific node

```bash
kubectl label node <node-name> node.longhorn.io/spdk-cpu-mask=0xFF
```

### Set SPDK memory size (16 GiB) on a high-memory node

```bash
kubectl label node <node-name> node.longhorn.io/spdk-memory-size=16384
```

### Set V2 IM CPU request to 4 cores on a dedicated storage node

```bash
kubectl label node <node-name> node.longhorn.io/v2-im-cpu-request=4
```

### Override interrupt mode on a specific node

```bash
kubectl label node <node-name> node.longhorn.io/spdk-interrupt-mode=true
```

### Remove a per-node override (fall back to cluster-wide setting)

```bash
kubectl label node <node-name> node.longhorn.io/spdk-cpu-mask-
```

## Verification

Check which labels are applied to a node:

```bash
kubectl get node <node-name> --show-labels | tr ',' '\n' | grep node.longhorn.io
```

Check the effective SPDK configuration on an instance manager:

```bash
kubectl -n longhorn-system get instancemanager <im-name> -o jsonpath='{.status.conditions}' | jq .
```

## When to Use Per-Node Labels

- **Heterogeneous hardware**: Nodes with different CPU counts, memory sizes, or RDMA capabilities can be configured individually
- **High-memory nodes**: Allocate more hugepages to SPDK on nodes with more RAM
- **CPU-pinned deployments**: Pin SPDK reactors to specific CPU cores on nodes with dedicated storage CPUs
- **Mixed transport**: Enable RDMA on nodes with RDMA hardware while leaving TCP-only nodes unchanged
- **CPU requests**: Allocate more CPU to the instance manager on nodes that host many volumes