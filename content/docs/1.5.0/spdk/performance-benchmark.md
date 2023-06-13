---
  title: Performance Benchmark
  weight: 3
---

## Environment

- Cloud provider: Equinix
- Machine: Japan/m3.small.x86
- Kubernetes: v1.23.6+rke2r2
- Nodes: 3 (each node is a master and also a worker)
- OS: Ubuntu 22.04 / 5.15.0-33-generic
- Storage: 1 SSD (Micron_5300_MTFD)
- Network throughput between nodes (tested by iperf over 60 seconds): 15.0 Gbits/sec

## Benchmarking Tools

- Utilize [kbench](https://github.com/yasker/kbench) a the benchmarking tool.

## Result

The baseline of the data disk was also measured using [rancher/local-path-provisioner](https://github.com/rancher/local-path-provisioner).


{{< figure src="/img/diagrams/spdk/spdk-iops.png" >}}

{{< figure src="/img/diagrams/spdk/spdk-bw.png" >}}

{{< figure src="/img/diagrams/spdk/spdk-latency.png" >}}