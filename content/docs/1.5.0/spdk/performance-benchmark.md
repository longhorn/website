---
  title: Performance Benchmark
  weight: 5
---

## Benchmarking Tool

Utilize [kbench](https://github.com/yasker/kbench) as the benchmarking tool.

## Baseline

The baseline of the data disk was also measured using [rancher/local-path-provisioner](https://github.com/rancher/local-path-provisioner).

## Equinix (m3.small.x86)

- Machine: Japan/m3.small.x86
- CPU: Intel(R) Xeon(R) E-2378G CPU @ 2.80GHz
- RAM: 64 GiB
- Kubernetes: v1.23.6+rke2r2
- Nodes: 3 (each node is a master and also a worker)
- OS: Ubuntu 22.04 / 5.15.0-33-generic
- Storage: 1 SSD (Micron_5300_MTFD)
- Network throughput between nodes (tested by iperf over 60 seconds): 15.0 Gbits/sec

{{< figure src="/img/diagrams/spdk/equinix-iops.svg" >}}

{{< figure src="/img/diagrams/spdk/equinix-bw.svg" >}}

{{< figure src="/img/diagrams/spdk/equinix-latency.svg" >}}

# AWS EC2 (c5d.xlarge)

- Machine: Tokyo/c5d.xlarge
- CPU: Intel(R) Xeon(R) Platinum 8124M CPU @ 3.00GHz
- RAM: 8 GiB
- Kubernetes: v1.25.10+rke2r1
- Nodes: 3 (each node is a master and also a worker)
- OS: Ubuntu 22.04.2 LTS / 5.19.0-1025-aws
- Storage: 1 SSD (Amazon EC2 NVMe Instance Storage/Local NVMe Storage)
- Network throughput between nodes (tested by iperf over 60 seconds): 7.9 Gbits/sec

{{< figure src="/img/diagrams/spdk/aws-c5d-xlarge-iops.svg" >}}

{{< figure src="/img/diagrams/spdk/aws-c5d-xlarge-bw.svg" >}}

{{< figure src="/img/diagrams/spdk/aws-c5d-xlarge-latency.svg" >}}
