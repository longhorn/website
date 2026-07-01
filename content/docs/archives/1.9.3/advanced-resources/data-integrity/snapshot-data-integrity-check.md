---
title: Snapshot Data Integrity Check
weight: 2
---

Longhorn is capable of hashing snapshot disk files and periodically checking their integrity.

## Introduction

Longhorn system supports volume snapshotting and stores the snapshot disk files on the local disk. However, it is impossible to check the data integrity of snapshots due to the lack of the checksums of the snapshots previously. As a result, when the data is corrupted due to, for example, the bit rot in the underlying storage, there is no way to detect the corruption and repair the replicas. After applying the feature, Longhorn is capable of hashing snapshot disk files and periodically checking their integrity. When a snapshot disk file in one replica is corrupted, Longhorn will automatically start the rebuilding process to fix it.

## Settings

### Global Settings

- **snapshot-data-integrity** <br>

    This setting allows users to enable or disable snapshot hashing and data integrity checking. Available options are:

    - **disabled**: Disable snapshot disk file hashing and data integrity checking.
    - **enabled**: Enables periodic snapshot disk file hashing and data integrity checking. To detect the filesystem-unaware corruption caused by bit rot or other issues in snapshot disk files, Longhorn system periodically hashes files and finds corrupted ones. Hence, the system performance will be impacted during the periodical checking.
    - **fast-check**: Enable snapshot disk file hashing and fast data integrity checking. Longhorn system only hashes snapshot disk files if their are not hashed or the modification time are changed. In this mode, filesystem-unaware corruption cannot be detected, but the impact on system performance can be minimized.

- **snapshot-data-integrity-immediate-check-after-snapshot-creation** <br>

    Hashing snapshot disk files impacts the performance of the system. The immediate snapshot hashing and checking can be disabled to minimize the impact after creating a snapshot.

- **snapshot-data-integrity-cronjob** <br>

    A schedule defined using the unix-cron string format specifies when Longhorn checks the data integrity of snapshot disk files.

    > **Warning**
    > Hashing snapshot disk files impacts the performance of the system. It is recommended to run data integrity checks during off-peak times and to reduce the frequency of checks.

### Per-Volume Settings

Longhorn also supports the per-volume setting by configuring `Volume.Spec.SnapshotDataIntegrity`. The value is `ignored` by default, so data integrity check is determined by the global setting `snapshot-data-integrity`. `Volume.Spec.SnapshotDataIntegrity` supports `ignored`, `disabled`, `enabled` and `fast-check`. Each volume can have its data integrity check setting customized.

## Performance Impact

For detecting data corruption, checksums of snapshot disk files need to be calculated. The calculations consume storage and computation resources. Therefore, the storage performance will be negatively impacted. In order to provide a clear understanding of the impact, we benchmarked storage performance when checksumming disk files. The read IOPS, bandwidth and latency are negatively impacted.

- Environment
    - Host: AWS EC2 c5d.2xlarge
    - CPU: Intel(R) Xeon(R) Platinum 8124M CPU @ 3.00GHz
    - Memory: 16 GB
    - Network: Up to 10Gbps
    - Kubernetes: v1.24.4+rke2r1
- Result
    - Disk: 200 GiB NVMe SSD as the instance store
      - 100 GiB snapshot with full random data
        {{< figure src="/img/diagrams/snapshot/snapshot_hash_ssd_perf.png" >}}

    - Disk: 200 GiB throughput optimized HDD (st1)
      - 30 GiB snapshot with full random data
        {{< figure src="/img/diagrams/snapshot/snapshot_hash_hdd_perf.png" >}}

## Recommendation

The feature helps detect the data corruption in snapshot disk files of volumes. However, the checksum calculation negatively impacts the storage performance. To lower down the impact, the recommendations are
- Checksumming and checking snapshot disk files can be scheduled to off-peak hours by the global setting `snapshot-data-integrity-cronjob`.
- Disable the global setting `snapshot-data-integrity-immediate-check-after-snapshot-creation`.