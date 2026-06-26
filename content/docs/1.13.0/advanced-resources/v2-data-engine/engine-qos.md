---
title: Per-Engine QoS Limits
weight: 2
---

The Longhorn V2 data engine supports **per-engine Quality of Service (QoS)** limits, allowing operators to cap aggregate I/O throughput (IOPS and bandwidth) on individual v2 volumes. QoS limits are enforced at the SPDK raid bdev level via `bdev_set_qos_limit`, providing kernel-bypass enforcement with minimal overhead.

## Overview

QoS limits can be set on a per-volume basis to:
- Cap total IOPS (read + write)
- Cap total bandwidth in MB/s (read + write)
- Cap read bandwidth separately
- Cap write bandwidth separately

All limits default to 0 (unlimited). Limits can be updated live without detaching the volume.

## Setting QoS Limits on a Volume

QoS limits are configured via the `qosLimits` field on the volume's `StorageClass` or via the Longhorn API.

### Via StorageClass

Create a StorageClass with QoS limits:

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: longhorn-v2-qos
provisioner: driver.longhorn.io
parameters:
  dataEngine: "v2"
  numberOfReplicas: "2"
  qosLimits: '{"rwIosPerSec":"1000","rwMbPerSec":"100"}'
```

This caps the volume at 1000 IOPS and 100 MB/s total throughput.

### Via Longhorn API

Update QoS limits on an existing volume:

```bash
kubectl -n longhorn-system exec deploy/longhorn-ui -- \
  curl -s -X POST \
  "http://longhorn-frontend:80/v1/volumes/<volume-name>?action=update" \
  -H 'Content-Type: application/json' \
  -d '{"qosLimits":{"rwIosPerSec":"2000","rwMbPerSec":"200"}}'
```

### Via kubectl (Volume CRD)

Patch the volume's QoS limits directly:

```bash
kubectl -n longhorn-system patch volume <volume-name> --type=merge \
  -p '{"spec":{"qosLimits":{"rwIosPerSec":"2000","rwMbPerSec":"200"}}}'
```

## QoS Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `rwIosPerSec` | Total IOPS limit (read + write). 0 = unlimited. | `0` |
| `rwMbPerSec` | Total bandwidth limit in MB/s (read + write). 0 = unlimited. | `0` |
| `rMbPerSec` | Read bandwidth limit in MB/s. 0 = unlimited. | `0` |
| `wMbPerSec` | Write bandwidth limit in MB/s. 0 = unlimited. | `0` |

Multiple limits can be combined. For example, capping IOPS at 1000 and write bandwidth at 50 MB/s:

```json
{"rwIosPerSec":"1000","wMbPerSec":"50"}
```

## Live QoS Updates

QoS limits can be updated on a running volume without detaching it. The engine applies the new limits via the `EngineSetQosLimit` RPC, which calls SPDK's `bdev_set_qos_limit` on the raid bdev in-place. There is no I/O disruption during the update.

## How Limits Are Enforced

QoS limits are applied to the raid bdev — the multipath device that the engine frontend exposes to the workload. This means:
- Limits apply to the volume's aggregate I/O across all replicas
- Rebuild traffic (which flows directly from the engine to the rebuilding replica over NVMe-oF) is **not** subject to QoS limits, ensuring rebuilds are not throttled by QoS
- SPDK enforces each limit as a separate token bucket, allowing mix-and-match (e.g., cap aggregate IOPS but only cap writes for bandwidth)

## Use Cases

- **Noisy neighbor isolation**: Cap a volume's IOPS to prevent it from saturating shared storage nodes
- **Bandwidth throttling**: Limit a volume's read or write bandwidth during off-peak data migration
- **Gradual ramp-up**: Start with low limits and increase them as workload stabilizes
- **Backup window protection**: Cap write bandwidth on a volume being backed up to prevent the backup from starving live I/O

## Verifying QoS Limits

Check the current QoS limits on a volume:

```bash
kubectl -n longhorn-system get volume <volume-name> -o jsonpath='{.spec.qosLimits}' | jq .
```

## Limitations

- QoS limits are only available for the V2 data engine
- Limits are per-volume (per-engine), not per-replica
- All-zero values mean unlimited (no cap)
- QoS limits do not affect rebuild traffic