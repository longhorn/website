---
title: Disk Health Monitoring
weight: 4
---

## Disk Health Metrics

Starting with Longhorn v1.11.0, disk health monitoring metrics are available for both the V1 and V2 data engines. These metrics provide insights into disk health status.

> **Note:**
>   - Health data is collected periodically (every 10 minutes) by Longhorn’s disk monitor.
>   - Some virtualized or cloud environments (e.g., AWS EBS) may not expose full SMART data, resulting in zero values for certain attributes.
>   - Available health attributes may vary depending on the underlying disk type and hardware.
>   - The full set of collected health data is available in the `nodes.longhorn.io` Custom Resources (CRs).

### Data Sources

- **V1 Data Engine**:
    - Health data is collected using the SMART monitoring tool (`smartctl`).
- **V2 Data Engine**:
    - **NVMe disks:** Health data is retrieved through SPDK.
    - **AIO disks:** Health data is collected using the SMART monitoring tool (`smartctl`).

> **Note:**
>
> Health data is sourced differently depending on disk type:
> - **V1 disks and V2 AIO disks:** via SMART
> - **V2 NVMe disks:** via SPDK
>
> Available attributes and formats may vary by disk type and hardware. For details:
> - **SMART attributes:** [smartmontools documentation](https://www.smartmontools.org/wiki/TocDoc)
> - **SPDK NVMe health data:** [bdev_nvme_get_controller_health_info JSON-RPC](https://github.com/spdk/spdk/blob/v25.09/doc/jsonrpc.md.jinja2#L4805-L4856).

### Health Attributes

The `longhorn_disk_health_attribute_raw` metric exposes raw attribute values with the following labels:
- `attribute`: Name of the attribute
- `attribute_id`: Attribute ID, when provided by the collection method.
- `disk`: Longhorn disk identifier.
- `node`: Name of the node.

> **Note:**
>
> SMART data may not be available on all platforms (particularly cloud providers). If SMART is not supported, health metrics will appear as `0`.

### References

- Related Github [Issue #12016](https://github.com/longhorn/longhorn/issues/12016).
