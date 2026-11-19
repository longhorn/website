---
title: I/O Buffer Pool Configuration
weight: 25
---

The V2 Data Engine uses SPDK's `iobuf` subsystem to preallocate shared zero-copy data buffers for network I/O processing, including NVMe-oF/TCP target requests between engines and replicas. Longhorn lets you tune the small and large `iobuf` pool sizes to prevent buffer exhaustion under high-concurrency workloads and concurrent replica rebuilds.

## Settings

- [`data-engine-iobuf-large-pool-size`](../../../references/settings#data-engine-iobuf-large-pool-size)
- [`data-engine-iobuf-small-pool-size`](../../../references/settings#data-engine-iobuf-small-pool-size)
- [`data-engine-memory-size`](../../../references/settings#data-engine-memory-size)

## How SPDK `iobuf` Pools Work

When the SPDK target daemon (`spdk_tgt`) starts inside a V2 Instance Manager pod, it allocates two buffer pools from the memory budget defined by [`data-engine-memory-size`](../hugepage-configuration) (default `2048` MiB):

| Pool | Setting | Buffer Size | Default Count | Default Memory | Typical Workload |
| --- | --- | --- | --- | --- | --- |
| **Small Pool** (`small_pool`) | `data-engine-iobuf-small-pool-size` | `8` KiB | `8192` | `64` MiB | I/O requests `<= 8` KiB (for example, `4` KiB random reads and writes) |
| **Large Pool** (`large_pool`) | `data-engine-iobuf-large-pool-size` | `132` KiB | `6144` | `792` MiB | I/O requests `> 8` KiB (for example, `16` KiB database pages, `128` KiB–`1` MiB reads/writes, and replica rebuilds) |

Because SPDK handles NVMe-oF/TCP data transfers without extra memory copies, each incoming read or write PDU holds one or more `iobuf` buffers from the moment it enters the NVMe/TCP transport layer until backend disk I/O completes.

### Impact of Concurrent Writes and Replica Rebuilds

In Longhorn V2, each open logical volume (`lvol`) and snapshot allocates its own isolated blobstore I/O channel, preventing Copy-on-Write (CoW) cluster allocations on one rebuilding replica from blocking healthy volumes or snapshot reads at the blobstore layer.

However, all V2 volumes on the same node still share that node's `iobuf` pools:

- When a rebuilding replica receives writes to unallocated `1` MiB clusters, subsequent unallocated-cluster writes on that replica wait in its channel queue while it reads `1` MiB from the remote external snapshot over NVMe/TCP.
- Every queued write holds its `132` KiB `large_pool` buffer(s) until the CoW allocation and local disk write finish.
- Longhorn defaults `data-engine-iobuf-large-pool-size` to `6144` (`792` MiB) so 1-NUMA and 2-NUMA nodes with the default `2048` MiB `data-engine-memory-size` have ample headroom for concurrent writes and replica rebuilds instead of leaving huge pages idle. On very dense nodes where total in-flight writes still exceed `large_pool`, incoming NVMe/TCP requests—including cross-node snapshot reads required by peer nodes to complete their own rebuilds—must wait for buffers (`NEED_BUFFER`), which can cause I/O timeouts or stalls.

## When to Adjust Pool Sizes

Consider **increasing** `data-engine-iobuf-large-pool-size` above `6144` (together with `data-engine-memory-size`) when:

- Each node serves a large number of active V2 volumes or applications issuing `> 8` KiB I/O (`16` KiB to `1` MiB) at high queue depth alongside many concurrent replica rebuilds.
- SPDK `iobuf_get_stats` reports non-zero `retry` counts on `large_pool`.

Consider **lowering** `data-engine-iobuf-large-pool-size` (toward `1024`–`2048`) or **increasing** `data-engine-memory-size` when:

- Nodes have **4 or more NUMA nodes** with only `2048` MiB of total huge pages (`<= 512` MiB per NUMA node), or `data-engine-memory-size` is reduced below `2048` MiB. See [Multi-NUMA Considerations](#multi-numa-considerations).

Consider **increasing** **`data-engine-iobuf-small-pool-size`** above `8192` when:

- Workloads drive high-queue-depth `<= 8` KiB (such as `4` KiB) random reads or writes across many volumes per node.
- SPDK `iobuf_get_stats` reports non-zero `retry` counts on `small_pool`.

## Memory Sizing Guidelines

Both `iobuf` pools are carved out of the fixed `spdk_tgt` memory allocation (`data-engine-memory-size`, backed by huge pages by default). Always leave sufficient headroom in `data-engine-memory-size` for base SPDK mempools (`~220` MiB for `bdev_io`, `fsdev_io`, and transport structures), lvstore/bdev metadata, per-channel metadata DMA pages (`8` KiB per active `(lvol, I/O thread)` channel), and transient `1` MiB Copy-on-Write buffers.

| `large_pool` Count | `large_pool` Memory (`× 132` KiB) | `small_pool` Count | `small_pool` Memory (`× 8` KiB) | Total `iobuf` Memory | Recommended Minimum `data-engine-memory-size` (when `vm.nr_hugepages` matches `data-engine-memory-size`) |
| --- | --- | --- | --- | --- | --- |
| `1024` (minimum) | `132` MiB | `8192` (default) | `64` MiB | `196` MiB | `2048` MiB (`1`–`4` NUMA nodes) |
| `4096` | `528` MiB | `8192` | `64` MiB | `592` MiB | `2048` MiB (`1`–`2` NUMA), `4096` MiB (`4` NUMA) |
| `6144` (default) | `792` MiB | `8192` (default) | `64` MiB | `856` MiB | `2048` MiB (`1`–`2` NUMA), `4096` MiB (`4` NUMA) |
| `8192` | `1056` MiB | `16384` | `128` MiB | `1184` MiB | `4096` MiB (`1`–`2` NUMA), `8192` MiB (`4` NUMA) |
| `16384` | `2112` MiB | `32768` | `256` MiB | `2368` MiB | `4096` MiB (`1` NUMA), `8192` MiB (`2` NUMA) |

> **Important**: If you increase `data-engine-memory-size` while huge pages are enabled (`data-engine-hugepage-enabled` is `{"v2":"true"}`), ensure that you pre-allocate at least that amount of `2` MiB huge pages on every V2 node first. See [Huge Page Configuration](../hugepage-configuration).

### Multi-NUMA Considerations

On multi-socket or multi-NUMA servers, keep two platform behaviors in mind when sizing `iobuf` pools, host huge pages, and `data-engine-memory-size`:

1. **Linux divides system-wide huge pages evenly across NUMA nodes**: Setting `2048` MiB of system huge pages (`vm.nr_hugepages=1024`) provides `2048` MiB on a single-NUMA host, `1024` MiB per NUMA node on a 2-NUMA host, and `512` MiB per NUMA node on a 4-NUMA host. (If the host pre-allocates more huge pages than `data-engine-memory-size`, DPDK can draw more pages from a single NUMA node up to `data-engine-memory-size`.)
2. **Each `iobuf` pool must fit contiguously within one NUMA node, while later allocations spill over across NUMA nodes**: During `spdk_tgt` startup, `iobuf` initializes early and allocates `small_pool` and `large_pool` (`large_pool_count × 132` KiB) as contiguous blocks that cannot span multiple NUMA nodes. Subsequent SPDK allocations (`bdev_io`, per-channel DMA pages, and transient `1` MiB Copy-on-Write buffers) use `SPDK_ENV_NUMA_ID_ANY` and automatically spill over to other NUMA nodes when NUMA node 0 fills up:
   - For example, on a 2-NUMA host with `2048` MiB of huge pages (`1024` MiB per NUMA node), `large_pool = 6144` (`792` MiB) and `small_pool = 8192` (`64` MiB) fit cleanly on NUMA node 0 (`856` MiB `< 1024` MiB), while `bdev_io` and Copy-on-Write buffers use the remaining `~900` MiB on NUMA node 1.
   - However, if **no single NUMA node** has enough free huge pages to hold the contiguous `large_pool` block itself—for example, `large_pool = 8192` (`1056` MiB `> 1024` MiB) on that same 2-NUMA host, or `large_pool = 4096` (`528` MiB `> 512` MiB) on a 4-NUMA `2048` MiB host—`spdk_tgt` fails to start with `-ENOMEM`.

Ensure that at least one NUMA node has enough free huge page capacity (within `data-engine-memory-size`) to hold the contiguous `large_pool` (and `small_pool`), and that total `data-engine-memory-size` across all NUMA nodes leaves ample headroom (`>= 256` MiB) for `bdev_io` and Copy-on-Write buffers.

You can check the number of NUMA nodes and per-NUMA `2` MiB huge page distribution on a host with:

```bash
lscpu | grep -i numa
grep . /sys/devices/system/node/node*/hugepages/hugepages-2048kB/{nr_hugepages,free_hugepages}
```

## Configuring `iobuf` Pool Sizes

### Using the Longhorn UI

1. Navigate to **Setting > General**.
2. In the **Danger Zone** section, locate **Data Engine iobuf Large Pool Size** or **Data Engine iobuf Small Pool Size**.
3. Set the desired JSON value (for example, `{"v2":"6144"}`) and save.

### Using `kubectl`

```bash
kubectl -n longhorn-system patch settings.longhorn.io data-engine-iobuf-large-pool-size \
  --type=merge -p '{"value":"{\"v2\":\"6144\"}"}'
```

### How Changes Take Effect

- **Startup-only allocation**: SPDK sizes `iobuf` pools only when `spdk_tgt` starts; pool sizes cannot be resized dynamically at runtime.
- **Minimum values**: Values must be at least `1024` for `data-engine-iobuf-large-pool-size` and `8192` for `data-engine-iobuf-small-pool-size` (SPDK's built-in defaults).
- **Instance Manager rollout**:
  - V2 Instance Manager pods with **no running engine or replica instances** are automatically recreated so the new pool size takes effect immediately.
  - V2 Instance Manager pods with **running instances** stay active to avoid disrupting attached volumes and report the `SettingSynced=False` condition until all V2 volumes on that node are detached (or migrated) and the pod is recreated.
