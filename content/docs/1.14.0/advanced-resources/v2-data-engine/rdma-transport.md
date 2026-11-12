---
title: RDMA Transport (Experimental)
weight: 60
---

Longhorn can run the V2 data engine's engine-to-replica traffic over **RDMA (RoCEv2)** instead of NVMe/TCP. The transport is chosen per volume, so TCP and RDMA volumes can share the same nodes, disks, and storage network.

RDMA moves the transport work to the NIC. In Longhorn's tests on BlueField-2 25GbE NICs, a three-replica volume used about 30-50% less SPDK reactor time per I/O on the engine node and 40-60% less on the replica nodes than the same volume over TCP, with lower latency.

The host-facing connection (from the node that consumes the volume to the engine) stays NVMe/TCP. Only the connections from the engine to its replicas use RDMA.

## Requirements

- V2 data engine enabled.
- RoCE-capable NICs (for example, NVIDIA ConnectX or BlueField) on the nodes that hold RDMA volumes or their replicas.
- RDMA kernel modules loaded: `ib_core`, `ib_uverbs`, `rdma_cm`, `rdma_ucm`, and the NIC's RDMA provider (for example, `mlx5_ib`). No RDMA packages are needed on the host; the RDMA userspace ships in the Instance Manager image.
- A [storage network](../../deploy/storage-network) attached to the RDMA NIC itself. The Instance Manager's storage network interface must carry a RoCE v2 GID, which means using `ipvlan` (recommended), `macvlan`, `host-device`, or an SR-IOV network over the RDMA NIC. A storage network built on a Linux bridge, or no storage network at all (the default pod network), cannot carry RDMA.

You can check the node prerequisites with `longhornctl`:

```bash
longhornctl check preflight --enable-rdma --rdma-interface <rdma-nic>
```

The check reports the RDMA kernel modules, the ACTIVE RoCE v2 ports, the `/dev/infiniband` device nodes, whether the V2 data engine CPU mask is on the NIC's NUMA node, and whether the iobuf pools are large enough for the number of reactors. `longhornctl install preflight --enable-rdma` loads the kernel modules and persists them.

## Configure the Storage Network

Create a NetworkAttachmentDefinition on the RDMA NIC and set it as the [Storage Network](../../../references/settings#storage-network). For example, with `ipvlan`:

```yaml
apiVersion: k8s.cni.cncf.io/v1
kind: NetworkAttachmentDefinition
metadata:
  name: rdma-storage-net
  namespace: longhorn-system
spec:
  config: |
    {
      "cniVersion": "0.3.1",
      "type": "ipvlan",
      "master": "<rdma-nic>",
      "mode": "l2",
      "ipam": {
        "type": "whereabouts",
        "range": "10.25.0.0/24"
      }
    }
```

Set the **Storage Network** setting to `longhorn-system/rdma-storage-net`. As with any storage network change, all volumes must be detached first.

> **Note:** On BlueField-2 NICs, `macvlan` carried a valid RoCE v2 GID but was about 20 times slower than `ipvlan` for RDMA traffic.

## Create an RDMA Volume

Set `dataEngineTransport: rdma` in a V2 StorageClass:

```yaml
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: longhorn-v2-rdma
provisioner: driver.longhorn.io
allowVolumeExpansion: true
parameters:
  dataEngine: "v2"
  dataEngineTransport: "rdma"
  numberOfReplicas: "3"
```

Volumes without the parameter, or with `dataEngineTransport: tcp`, use TCP.

Longhorn validates RDMA volumes:
- `rdma` requires the V2 data engine, the replicated data layout, and at least one RDMA-capable node.
- Replicas of an RDMA volume are only scheduled on RDMA-capable nodes, and the volume can only be attached to an RDMA-capable node.
- The transport can be changed only while the volume is detached. Switching to `rdma` requires every replica to be on an RDMA-capable node.

A node is RDMA-capable when its `RDMACapable` condition is `True`. Longhorn sets this condition on V2-enabled nodes that have an RDMA device.

## Size CPU Cores and Buffer Pools

RDMA lowers the SPDK reactor time each I/O needs, which leaves more reactor capacity for the TCP frontend and for other volumes. Adding reactors with [Configurable CPU Cores](../configurable-cpu-cores) raised throughput for both transports in Longhorn's tests, for example PostgreSQL TPS by 66-78% when going from 2 to 8 reactors. Keep the CPUs in the V2 data engine CPU mask on the same NUMA node as the RDMA NIC.

With RDMA, the engine node's SPDK target runs two NVMe-oF transports (TCP for the frontend and RDMA for the local replica), and each takes a per-reactor buffer cache. Scale the iobuf pools with the number of reactors. At least 4096 small and 512 large buffers per reactor ran without buffer retries:

| Reactors | `data-engine-iobuf-small-pool-size` | `data-engine-iobuf-large-pool-size` |
| --- | --- | --- |
| 2 | 8192 (default) | 1024 (default) |
| 8 | 32768 | 4096 |

`longhornctl check preflight --enable-rdma` warns when the pools are smaller than this.

## Verify

- The node condition `RDMACapable` is `True` on the nodes that hold RDMA volumes.
- In the V2 Instance Manager pod, the storage network interface (`lhnet1`) has a RoCE v2 GID:
    ```bash
    grep -l lhnet1 /sys/class/infiniband/*/ports/*/gid_attrs/ndevs/*
    ```
- On the engine's Instance Manager, the replica controllers report `trtype` `RDMA` in the SPDK `bdev_nvme_get_controllers` output.

## Troubleshooting

- **Replicas fail with `rdma_create_event_channel() failed, No such device`**: the Instance Manager cannot use the RDMA device. Check that the RDMA kernel modules are loaded and that the Instance Manager image includes the RDMA userspace.
- **Volume creation is rejected with "requires at least one RDMA-capable node"**: no node reports `RDMACapable`. Check the NIC and kernel modules with `longhornctl check preflight --enable-rdma`.
- **No RoCE v2 GID on `lhnet1`**: the storage network is not attached to the RDMA NIC, or it uses a Linux bridge.
- **Buffer retries in SPDK `iobuf_get_stats`, or stalls under large I/O**: raise the iobuf pools as described above.

## Limitations

- Experimental.
- The host-facing frontend stays NVMe/TCP. RDMA for the frontend is tracked in [longhorn/longhorn#14299](https://github.com/longhorn/longhorn/issues/14299).
- The sharded (erasure-coded) data layout, and internal transient paths such as rebuilding and cloning, still use TCP.

## Reference

- [longhorn/longhorn#13796](https://github.com/longhorn/longhorn/issues/13796)
