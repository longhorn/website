---
title: Scale Replica Rebuilding
weight: 6
---

Starting with v1.11.0, Longhorn supports **scale replica rebuilding**, allowing a rebuilding replica to fetch snapshot data from multiple healthy replicas concurrently to improve rebuild performance.

## Introduction

Traditionally, Longhorn rebuilds a failed replica by fetching all snapshot data from a single healthy replica. With scale replica rebuilding, the rebuilding replica can fetch snapshot data from multiple source replicas simultaneously, potentially reducing rebuild time.

This feature is particularly beneficial when volumes contain scattered small data chunks and holes in their snapshots, as it allows better utilization of available network bandwidth and parallel processing.

## How It Works

When scale replica rebuilding is enabled:

1. Multiple healthy replicas start sync servers as snapshot data sources.
2. The rebuilding replica fetches snapshot data from different snapshots across different source replicas simultaneously.
3. The number of concurrent source replicas is controlled by the `replica-rebuild-concurrent-sync-limit` setting.

## Settings

### Global Setting: `replica-rebuild-concurrent-sync-limit`

This setting controls the maximum number of healthy replicas that can sync snapshot data to a single rebuilding replica concurrently.

- **Default**: `1` (scale rebuilding disabled)
- **Range**: `1` to `5`

When set to `1`, only one source replica syncs to the rebuilding replica at a time (traditional behavior). Values greater than `1` enable scale replica rebuilding, allowing multiple source replicas (up to the configured limit) to sync snapshot data to the rebuilding replica simultaneously.

For more information, see [Settings Reference](../../../references/settings#replica-rebuild-concurrent-sync-limit).

### Per-Volume Override

You can override the global `replica-rebuild-concurrent-sync-limit` setting for individual volumes:

- Using the Longhorn UI: Edit the volume and modify the `Rebuild Concurrent Sync Limit` field.
- Using kubectl: Run `kubectl -n longhorn-system edit volume [volume-name]` and modify the `spec.rebuildConcurrentSyncLimit` field.

When the per-volume setting is set to `0`, the volume uses the global setting. Otherwise, the per-volume setting takes precedence.

## Performance Considerations

### When Scale Rebuilding Helps

Scale replica rebuilding provides significant performance improvements in the following scenarios:

- **Volumes with scattered small data chunks**: When snapshots consist of intermittent small data chunks (e.g., 4K blocks) with holes, scale rebuilding can significantly reduce rebuild time by utilizing multiple source replicas.
- **Network bandwidth availability**: When network bandwidth is underutilized during traditional rebuilding, adding more source replicas can better utilize available bandwidth.

## Best Practices

1. **Start with the default**: The default value of `1` (scale replica rebuilding disabled) is conservative and suitable for most environments.

2. **Test before increasing**: Before increasing the limit, test in a non-production environment to understand the resource impact on your specific workload.

3. **Consider your workload**:
   - For volumes with scattered small data chunks: Consider enabling scale replica rebuilding (set to `2` or higher).
   - For volumes with continuous large data chunks: The performance benefit may be minimal.

4. **Monitor resource usage**: When scale replica rebuilding is enabled, monitor CPU usage on nodes hosting source and destination replicas to ensure sufficient resources are available.

5. **Balance performance and resources**: Higher concurrent sync limits can improve rebuild speed but consume more CPU resources. Consider the trade-off based on your cluster's resource availability and rebuild urgency.

## Limitations

- The maximum number of concurrent source replicas is limited to `5`.
- Scale replica rebuilding is disabled by default to avoid unexpected high resource consumption.
- Actual performance improvements depend on factors including disk I/O performance, network bandwidth, data distribution patterns, and available CPU resources.

## References

For more information on related rebuilding features, see [Longhorn #11331](https://github.com/longhorn/longhorn/issues/11331).
