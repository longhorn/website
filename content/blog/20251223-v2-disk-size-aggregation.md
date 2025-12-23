---
title: V2 Disk Size Aggregation
author: David Cheng
draft: false
date: 2025-12-23
categories:
- "disk"
tags:
- "disk"
- "v2"
---

## Table of contents
- [Introduction](/blog/20251223-v2-disk-size-aggregation/#introduction)
- [Disk Size Aggregation Overview](/blog/20251223-v2-disk-size-aggregation/#disk-size-aggregation-overview)
- [Why Longhorn Chooses Linux RAID Over SPDK RAID (For Now)](/blog/20251223-v2-disk-size-aggregation/#why-longhorn-chooses-linux-raid-over-spdk-raid-for-now)
  - [SPDK RAID 0 – Capacity Waste](/blog/20251223-v2-disk-size-aggregation/#spdk-raid-0-capacity-waste)
  - [SPDK Concat – Capacity Good, Performance Flat](/blog/20251223-v2-disk-size-aggregation/#spdk-concat-capacity-good-performance-flat)
  - [Linux Kernel RAID 0 – Best Practical Balance](/blog/20251223-v2-disk-size-aggregation/#linux-kernel-raid-0-best-practical-balance)
  - [Comparison Table](/blog/20251223-v2-disk-size-aggregation/#comparison-table)
- [Create an Aggregated Disk Using Linux Kernel RAID](/blog/20251223-v2-disk-size-aggregation/#create-an-aggregated-disk-using-linux-kernel-raid)
  - [Create Aggregated Disk](/blog/20251223-v2-disk-size-aggregation/#create-aggregated-disk)
  - [Remove an Aggregated Disk](/blog/20251223-v2-disk-size-aggregation/#remove-an-aggregated-disk)
- [Benchmark Result](/blog/20251223-v2-disk-size-aggregation/#benchmark-result)
  - [1-Replica Volume](/blog/20251223-v2-disk-size-aggregation/#1-replica-volume)
  - [3-Replica Volume](/blog/20251223-v2-disk-size-aggregation/#3-replica-volume)
- [Conclusion](/blog/20251223-v2-disk-size-aggregation/#conclusion)
- [Future Direction](/blog/20251223-v2-disk-size-aggregation/#future-direction)

## Introduction

This article is intended for Kubernetes administrators and system engineers running **Longhorn v2** on nodes with multiple local disks who want to aggregate disk capacity or improve I/O performance. It explains the available disk aggregation options, their trade-offs, and why Linux Kernel RAID is currently the recommended approach.


## Disk Size Aggregation Overview {#disk-size-aggregation-overview}

Modern Kubernetes nodes often include multiple local disks—NVMe, SSD, or HDD—that users want to combine into a single larger storage unit. Longhorn supports using aggregated block devices as storage backends, but the aggregation itself must be created by the user on the host node before Longhorn consumes it.

Currently, the recommended way to aggregate disks for Longhorn v2 is to use **Linux Kernel RAID** (`mdadm`). Although SPDK provides RAID and concat capabilities, their current limitations make kernel RAID the more practical choice. This article explains how to create and remove aggregated disks and, more importantly, why Longhorn does not introduce a built-in SPDK RAID layer at this time.

## Why Longhorn Chooses Linux RAID Over SPDK RAID (For Now) {#why-longhorn-chooses-linux-raid-over-spdk-raid-for-now}

Longhorn v2 uses a fully SPDK-based data engine. At first glance, building disk aggregation on top of SPDK RAID appears intuitive. However, after evaluating **SPDK RAID 0** and **SPDK Concat**, several drawbacks prevent them from being adopted as the default aggregation layer for Longhorn v2 today.

The observations below are based on internal testing.

### SPDK RAID 0 - Capacity Waste {#spdk-raid-0-capacity-waste}

SPDK RAID 0 requires all member disks to operate at the size of the smallest disk in the array. For example:

| Disk  | Size  |
| ----- | ----- |
| nvme1 | 50Gi  |
| nvme2 | 100Gi |
| nvme3 | 100Gi |

The usable capacity of this SPDK RAID 0 array is: `3 × 50Gi = 150Gi`.

The remaining capacity on the larger disks is unused because SPDK RAID 0 truncates all members to the smallest size. This behavior makes SPDK RAID 0 impractical for environments with disks of mixed sizes, which is common on bare-metal and cloud instances. Linux RAID 0 does not impose this limitation.

From a performance perspective, SPDK RAID 0 behaves as expected:

- Striping works correctly and IOPS scale with disk count
- Sequential throughput increases with additional disks
- No severe latency penalties are observed

However, achieving optimal performance typically requires:

- Explicit CPU core pinning
- Stripe size tuning

Without careful tuning, SPDK RAID 0 often provides limited advantages over Linux RAID 0. Given Longhorn’s focus on operational simplicity, requiring users to manually tune SPDK internals is not desirable.

#### Structure Diagram

```
LVS
└── SPDK RAID 0
    ├── Bdev nvme
    │   └── /dev/nvme1
    ├── Bdev nvme
    │   └── /dev/nvme2
    └── Bdev nvme
        └── /dev/nvme3
```

### SPDK Concat - Capacity Good, Performance Flat {#spdk-concat-capacity-good-performance-flat}

SPDK Concat mode:

- Preserves the full capacity of all disks
- Does not provide I/O parallelism
- Does not improve bandwidth or IOPS
- Uses a simple linear data layout

Because Concat does not interleave I/O across disks, it behaves similarly to a single raw device. Although Concat does not stripe data like Linux RAID 0, the stripe size still affects I/O behavior. Internally, the RAID bdev layer uses the stripe size as an `optimal_io_boundary` and enables `split_on_optimal_io_boundary`. Large sequential I/O may be split into smaller requests before reaching the RAID module. If the stripe size is too small (for example, 4K), this excessive splitting can severely reduce sequential throughput without providing any parallelism.

In contrast, Linux RAID 0 stripes data across all disks and processes I/O in parallel, allowing both sequential and random workloads to scale with disk count. SPDK Concat performs like a single large linear device, serving I/O sequentially within each disk region, without any concurrency or bandwidth aggregation.

#### Structure Diagram

```
LVS
└── SPDK Concat
    ├── Bdev nvme
    │   └── /dev/nvme1
    ├── Bdev nvme
    │   └── /dev/nvme2
    └── Bdev nvme
        └── /dev/nvme3
```

### Linux Kernel RAID 0 - Best Practical Balance {#linux-kernel-raid-0-best-practical-balance}

Linux Kernel RAID 0 provides:

- Good sequential throughput
- Good random IOPS
- Predictable latency
- Full capacity utilization, even with mixed disk sizes
- A mature ecosystem with proven tooling and recovery workflows

It meets Longhorn’s requirements without introducing additional complexity or performance regressions.

#### Structure Diagram

```
LVS
└── Bdev aio
    └── Linux Kernel RAID 0 (mdadm)
        ├── /dev/nvme1
        ├── /dev/nvme2
        └── /dev/nvme3
```

### Comparison Table

| Category                             | **SPDK RAID 0**                                            | **SPDK Concat**                         | **Linux RAID 0**                                |
| ------------------------------------ | ---------------------------------------------------------- | --------------------------------------- | ----------------------------------------------- |
| **Capacity Behavior**                | Limited by smallest disk; wastes capacity with mixed sizes | Uses full capacity                      | Uses full capacity                              |
| **Sequential Throughput**            | Very high (striping)                                       | Same as a single disk                   | Very high (striping)                            |
| **Random IOPS**                      | Scales with number of disks                                | Same as a single disk                   | Scales with number of disks                     |
| **Latency**                          | Low                                                        | Low                                     | Slightly higher but still low                   |
| **Performance Tuning**               | CPU pinning and stripe-size tuning often needed            | No tuning                               | No tuning                                       |
| **Recovery and Tooling**             | Limited ecosystem                                          | Limited                                 | Excellent tooling (`mdadm`, recovery workflows) |
| **Suitability for Mixed Disk Sizes** | Poor                                                       | Good                                    | Good                                            |
| **Kernel or Userspace**              | Userspace (SPDK)                                           | Userspace (SPDK)                        | Kernel native                                   |
| **Integration with Longhorn**        | Requires SPDK-level configuration                          | Requires SPDK-level configuration       | Works out of the box as a block device          |
| **Overall Recommendation (2025)**    | Not recommended                                            | Not recommended for performance         | Recommended                                     |

### Create an Aggregated Disk Using Linux Kernel RAID

#### Create Aggregated Disk {#create-aggregated-disk}

- Install `mdadm` using your system package manager (for example, `sudo apt install mdadm -y` or `sudo yum install mdadm -y`).
- Create a RAID 0 array from the desired devices:

    ```bash
    sudo mdadm --create /dev/md0 \
        --level=0 \
        --raid-devices=3 \
        /dev/nvme1n1 /dev/nvme2n1 /dev/nvme3n1
    ```

- After the RAID device (for example, `/dev/md0`) is created, add it to the Longhorn cluster through the UI or via `kubectl`. Longhorn accesses this device using the **AIO backend**.

#### Remove an Aggregated Disk

- Remove the aggregated disk from the Longhorn system using the `UI` or `kubectl`.
- Stop the RAID device:

    ```bash
    sudo mdadm --stop /dev/md0
    ```

- Remove the `mdadm` superblock from each member disk:

    ```bash
    sudo mdadm --zero-superblock /dev/nvme1n1
    sudo mdadm --zero-superblock /dev/nvme2n1
    sudo mdadm --zero-superblock /dev/nvme3n1
    ```

- Verify that the superblocks have been removed: 

    ```bash
    sudo mdadm --examine /dev/nvme1n1
    sudo mdadm --examine /dev/nvme2n1
    sudo mdadm --examine /dev/nvme3n1
    ```

Expected output:

```bash
mdadm: No md superblock detected on /dev/nvme1n1.
mdadm: No md superblock detected on /dev/nvme2n1.
mdadm: No md superblock detected on /dev/nvme3n1.
```

## Benchmark Result

This benchmark uses [kbench](https://github.com/longhorn/kbench) to evaluate different aggregation configurations under varying replica counts.

FIO Test Parameters:

- Sequential workload
  - bs=128K
  - iodepth=16
  - numjobs=4

- Random workload
  - bs=4K
  - iodepth=128
  - numjobs=8
  - norandommap=1

- Common parameters
  - stonewall=1
  - randrepeat=0
  - verify=0
  - ioengine=libaio
  - direct=1
  - time_based=1
  - ramp_time=60s
  - runtime=60s
  - group_reporting=1

Measured metrics:

- Random IOPS (read and write)
- Sequential bandwidth (read and write)
- Random latency (read and write)

Test environment:

- Three nodes for 3-replica volumes; one node for 1-replica volumes
- Each node contains three disks: 50Gi, 100Gi, and 100Gi
- Instance type: `c5.xlarge`

> All bandwidth values shown below are measured in KiB/s. Stripe sizes (64K and 512K) indicate the amount of data written to one disk before continuing to the next disk in a RAID 0 array.

In summary, SPDK RAID 0 delivers strong performance but wastes capacity, SPDK Concat preserves capacity without scaling performance, and Linux RAID 0 provides the most balanced results.

### 1-Replica Volume

| Configuration              | Random IOPS (Read / Write) | Sequential Bandwidth (Read / Write) KiB/s | Random Latency (Read / Write) ns |
| -------------------------- | -------------------------- | ----------------------------------------- | -------------------------------- |
| **Baseline (Single Disk)** | 3,001 / 3,525              | 128,222 / 128,225                         | 638,322 / 941,680                |
| **SPDK RAID Concat (4K)**  | 3,002 / 3,586              | 11,939 / 12,049                           | 636,214 / 941,915                |
| **SPDK RAID Concat (64K)** | 3,002 / 3,689              | 128,229 / 128,245                         | 642,153 / 951,388                |
| **SPDK RAID 0 (64K)**      | 8,985 / 9,005              | 384,820 / 384,785                         | 731,702 / 1,042,055              |
| **SPDK RAID 0 (512K)**     | 9,004 / 8,981              | 384,643 / 384,513                         | 639,568 / 945,823                |
| **mdadm RAID 0 (512K)**    | 8,983 / 8,981              | 384,503 / 384,492                         | 647,074 / 954,796                |

### 3-Replica Volume

| Configuration              | Random IOPS (Read / Write) | Sequential Bandwidth (Read / Write) KiB/s | Random Latency (Read / Write) ns |
| -------------------------- | -------------------------- | ----------------------------------------- | -------------------------------- |
| **Baseline (Single Disk)** | 9,015 / 3,476              | 384,783 / 128,265                         | 637,628 / 1,071,141              |
| **SPDK RAID Concat (4K)**  | 9,017 / 3,409              | 36,013 / 12,215                           | 642,653 / 1,075,667              |
| **SPDK RAID Concat (64K)** | 9,004 / 3,558              | 384,831 / 128,238                         | 646,068 / 1,037,210              |
| **SPDK RAID 0 (64K)**      | 26,992 / 8,973             | 1,075,181 / 384,849                       | 644,169 / 1,083,213              |
| **SPDK RAID 0 (512K)**     | 26,936 / 9,003             | 941,377 / 380,937                         | 642,769 / 1,074,282              |
| **mdadm RAID 0 (512K)**    | 14,334 / 9,041             | 963,234 / 378,805                         | 646,411 / 1,070,201              |

> Minor variation is expected due to environmental or network factors.

### Analysis

1. **Single-disk vs. SPDK Concat**

    Single-disk and `SPDK Concat` show similar random I/O performance since each request is served by a single underlying device. Sequential throughput should also be close to a single disk; large drops typically indicate excessive I/O splitting caused by a small configured stripe size, rather than an inherent limitation of Concat.

2. **Single-replica volumes**

   For single-replica volumes, Linux Kernel RAID 0 performs similarly to `SPDK RAID 0`, delivering near–RAID 0 throughput without requiring SPDK-specific tuning. Both approaches provide strong sequential bandwidth and scale random IOPS with the number of disks.

3. **Multi-replica volumes**

   For multi-replica volumes, `SPDK RAID 0` can outperform Linux Kernel RAID 0 when the stripe size is carefully tuned (for example, 64K). In these scenarios, SPDK’s userspace datapath can reduce overhead and achieve higher sequential throughput under optimal configurations.

Overall, Linux Kernel RAID 0 provides the best balance of capacity utilization, operational simplicity, and predictable performance. In contrast, `SPDK RAID 0` and `SPDK Concat` exhibit limitations that currently prevent them from being recommended as the primary disk aggregation layer for Longhorn v2.

## Conclusion

Longhorn v2 prioritizes stability, predictable performance, and low operational complexity. Although SPDK provides RAID and concat capabilities, several limitations prevent these modes from being adopted as the default disk aggregation solution:

- `SPDK RAID 0` wastes capacity when disk sizes differ.
- `SPDK Concat` preserves capacity but does not provide parallel I/O.
- Optimal `SPDK RAID 0` performance requires advanced tuning, such as CPU pinning and stripe size configuration.
- Linux Kernel RAID 0 is mature, stable, simple to operate, and integrates cleanly with Longhorn.

In practice, users can select the appropriate Linux Kernel RAID level based on their desired balance between performance and data protection:

- `RAID 0` can be used when maximum performance and capacity utilization are required and data redundancy is handled at the Longhorn replica layer.
- `RAID 5` can be used when additional disk-level fault tolerance is desired, at the cost of some write-performance overhead.

It is also important to note that with this approach, block-type disks in Longhorn are intentionally exposed using the `AIO` disk driver.

For these reasons, **Linux Kernel RAID** remains the recommended approach for disk size aggregation in Longhorn v2, offering a flexible choice of RAID levels, proven reliability, and lower operational complexity compared to SPDK-based aggregation.

## Future Direction

Longhorn may consider introducing a built-in RAID layer in the future if the following conditions are met:

- `SPDK RAID 0` supports heterogeneous disk sizes without capacity loss.
- `SPDK Concat` delivers meaningful performance improvements.
- Linux Kernel RAID becomes insufficient or a bottleneck for workloads requiring higher throughput or lower latency.

Until then, Linux Kernel RAID continues to offer the best balance of:

- Capacity
- Performance
- Reliability
- Usability