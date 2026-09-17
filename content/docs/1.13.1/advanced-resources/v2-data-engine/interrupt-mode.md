---
title: Interrupt Mode Support
weight: 40
---

Longhorn supports **SPDK interrupt mode** for V2 data engine volumes as an alternative to the default **polling mode**.

In polling mode, SPDK reactors busy-poll for work. This keeps the allocated CPU cores close to 100% utilization and delivers the lowest latency. In interrupt mode, I/O completions wake the reactors through events, while SPDK keeps low-frequency background checks for NVMe/TCP control work and safety. This reduces idle CPU usage without changing the V2 data engine CPU allocation model.

Interrupt mode is a good fit for clusters with limited CPU resources, a relatively small number of volumes, or sporadic I/O. V2 still runs SPDK reactors on CPUs selected by the CPU mask, even when interrupt mode is enabled.

## How Interrupt Mode Works

### Polling Mode and Interrupt Mode

| | Polling Mode (Default) | Interrupt Mode |
| --- | --- | --- |
| I/O handling | Reactors continuously poll for work | I/O completions wake reactors through events |
| Idle CPU usage | Close to 100% on each allocated CPU core | Very low, with low-frequency background checks |
| Latency | Lowest and most predictable latency | Slightly higher under sustained high-throughput workloads |
| Best fit | High-performance workloads with frequent I/O | Resource-constrained clusters, fewer volumes, or sporadic I/O |
| CPU allocation | Uses CPUs selected by the V2 data engine CPU mask | Uses CPUs selected by the V2 data engine CPU mask |

### NVMe/TCP I/O Path

In interrupt mode, I/O completions wake the SPDK reactors through events instead of being discovered by constant polling. The system behavior shifts to the following:

- **I/O completions**: Delivered to the reactors as events. No high-frequency polling is needed to pick up finished I/O.
- **Background NVMe/TCP checks**: SPDK still performs low-frequency control checks for operations such as keepalive and controller recovery. These checks run more often while a connection is being re-established, so recovery is not delayed.
- **Safety check**: Every 10 ms, SPDK checks for internal queued work that may not have its own event notification. If an event is missed, this turns it into a brief latency hiccup instead of a stalled volume.

Because the remaining checks run at low frequency rather than thousands of times per second, the reactors stay idle most of the time when there is no I/O. An idle Instance Manager therefore uses very little CPU, while still retaining safeguards for connection recovery and missed events.

## Prerequisites

- V2 data engine enabled
- If you add an NVMe disk as a node disk using the `nvme` disk driver, IOMMU must be enabled. To verify:
    ```bash
    find /sys/kernel/iommu_groups/ -type l
    ```
    Example output (IOMMU enabled):
    ```
    /sys/kernel/iommu_groups/0/devices/0000:e6:0b.1
    /sys/kernel/iommu_groups/1/devices/0000:34:0a.6
    /sys/kernel/iommu_groups/2/devices/0000:a0:00.0
    ```
    If the command returns no output, IOMMU is not enabled.

    > **Note:** IOMMU support may not be exposed on virtualized instances. If unsure, consider using a bare-metal instance, or consult your cloud provider’s documentation or support team.

    For more information, see the official [SPDK documentation](https://spdk.io/doc/system_configuration.html).

## Configuration

### Global Setting

To enable interrupt mode globally, update the [data-engine-interrupt-mode-enabled](../../../references/settings#data-engine-interrupt-mode-enabled) setting.

### Important Considerations

- **Volume State Requirement**: The setting can only be changed when no V2 volumes are attached. Longhorn blocks updates if any V2 volume is active.
- **Global Effect**: The setting applies to all V2 volumes.

## CPU Core Allocation in Interrupt Mode

Interrupt mode uses the same V2 data engine CPU allocation settings as polling mode. Longhorn still starts the SPDK target daemon (`spdk_tgt`) with an effective CPU mask, which determines the CPUs that SPDK reactors can use. For CPU mask syntax, calculation examples, global settings, and per-node overrides, see [Configurable CPU Cores](../configurable-cpu-cores).

The important difference is CPU consumption, not CPU placement:

| | Polling Mode | Interrupt Mode |
| --- | --- | --- |
| CPUs available to `spdk_tgt` | CPUs selected by the effective CPU mask | CPUs selected by the effective CPU mask |
| Idle behavior | Reactors continuously busy-poll | Reactors can block while waiting for I/O events or low-frequency checks |
| Idle CPU usage | Close to 100% on each masked CPU | Very low, but not zero |
| Peak CPU usage | Bounded by the masked CPUs | Bounded by the masked CPUs |

For example, if the effective CPU mask is `0x3`, SPDK uses two reactors pinned to CPU 0 and CPU 1 in both modes. In interrupt mode, those reactors use very little CPU while idle, but the V2 data engine still cannot use CPUs outside CPU 0 and CPU 1. Under load, it can still saturate both CPUs.

Keep these points in mind when enabling interrupt mode:

- **Keep at least 2 cores available** to the V2 data engine. The first reactor also handles management requests, so a single-core allocation can allow heavy I/O to delay management processing.
- **Keep the effective Instance Manager CPU request aligned** with the CPU mask. Even though idle usage is low in interrupt mode, the reactors still need those CPUs during I/O bursts. See [Guaranteed Instance Manager CPU](../../../references/settings#guaranteed-instance-manager-cpu).
- **Do not shrink the CPU mask** as a substitute for enabling interrupt mode. A smaller mask reduces the number of reactors available for I/O; interrupt mode reduces idle CPU consumption without removing reactors.

## Limitations

- **Residual polling**: Interrupt mode is not a complete removal of polling. Low-frequency background checks remain, so idle CPU usage is very low but not zero.
- **Latency trade-off**: Under sustained high-throughput workloads, polling mode still delivers the lowest and most predictable latency.
- **Setting changes**: Cannot be modified while V2 volumes are attached.
- **Global scope**: Applies globally; no per-volume override is available.
- **CPU mask still applies**: Interrupt mode does not remove the V2 data engine CPU mask.
