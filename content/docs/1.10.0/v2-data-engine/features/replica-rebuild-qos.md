---
title: Replica Rebuild QoS
weight: 5
---

Longhorn supports rebuild bandwidth throttling (QoS) for v2 volumes based on SPDK. This feature allows users to apply bandwidth limits to replicas during rebuilding to avoid overloading the source and destination node’s storage throughput.

## Global Setting: `v2-data-engine-rebuilding-mbytes-per-second`

* A cluster-wide setting that defines the maximum write bandwidth (in MB/s) for rebuilding replicas.
* When set to `0`, there is no limit.
* This setting can only be configured via kubectl:

```bash
kubectl -n longhorn-system patch settings v2-data-engine-rebuilding-mbytes-per-second \
  --type=merge -p '{"value":"100"}'
```

## Per-Volume QoS Override

You can override the global rebuild bandwidth limit per volume by setting `spec.rebuildingMbytesPerSecond` in the `volume` spec:

```yaml
spec:
  rebuildingMbytesPerSecond: 50
```

## Effective QoS Resolution

The effective rebuild bandwidth limit is determined by evaluating both global and volume-specific settings. If the volume-specific value is greater than zero, it overrides the global setting.

| Global Setting | Volume Override | Effective QoS |
| -------------- | --------------- | ------------- |
| 0              | 0               | No limit      |
| 100            | 0               | 100 MB/s      |
| 0              | 200             | 200 MB/s      |
| 100            | 200             | 200 MB/s      |

The applied QoS is recorded in the field `status.rebuildStatus[*].appliedRebuildingMbps` in the `engine` status. 

Example of how the applied bandwidth limit appears in the volume engine status:

```yaml
  Rebuild Status:
    tcp://172.24.1.95:20001:
      Error:
      From Replica Address:  tcp://172.24.8.133:20001
      Is Rebuilding:         true
      Progress:              97
      State:                 in_progress
      appliedRebuildingMbps: 50
```
