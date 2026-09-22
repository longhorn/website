---
title: Topology-Aware Provisioning
weight: 6
---

Topology-aware provisioning helps Kubernetes and Longhorn make the same placement decision for a workload and its volume data. In clusters that span zones, regions, or other topology boundaries, a pod should normally run in a domain where its Longhorn replicas or erasure-coded shards are allowed to exist. Otherwise, provisioning can choose a topology that later constrains pod scheduling or leaves the workload dependent on long-lived remote I/O.

The feature is useful when topology affects availability, latency, or cost. By selecting a zone or region during provisioning and reusing that decision for Longhorn data placement, you can keep storage close to the workload, avoid unexpected cross-domain traffic, and make behavior during rebuilds, auto-balancing, node drains, and rolling updates easier to reason about.

Longhorn provides two levels of topology control:

- **PV topology**: Controls the `nodeAffinity` rules Kubernetes writes into a PersistentVolume (PV), dictating where pods using the PV can run.
- **Volume topology**: Controls where Longhorn stores volume data, dictating the placement of replicas, rebuild replicas, auto-balance candidates, and erasure-coded shards.

> **Note:** By default, StorageClasses without topology settings are unconstrained. To make a volume topology-aware, opt in using the `volumeTopology` StorageClass parameter.

## Volume Topology Modes

The `volumeTopology` StorageClass parameter controls whether Longhorn stores a topology requirement for the volume. It does not replace the normal Longhorn scheduling rules; instead, `zonal` and `regional` add a topology boundary that every data placement operation must obey. Values other than `any`, `zonal`, and `regional` are rejected during provisioning.

| `volumeTopology` | Stored `topologyRequirement` | PV `nodeAffinity` | Longhorn data placement |
| --- | --- | --- | --- |
| `any` or unset | None | Depends on the topology returned by CSI after `csi-allowed-topology-keys` filtering. | Replicas and shards follow the usual Longhorn scheduling rules without an additional topology boundary. |
| `zonal` | One selected zone | Restricted to the selected zone. | Replicas and shards must stay in the selected zone. |
| `regional` | One selected region | Restricted to the selected region. | Replicas and shards must stay in the selected region, and may still spread across zones within that region. |

`zonal` requires `topology.kubernetes.io/zone` and `regional` requires `topology.kubernetes.io/region` to be listed in the `csi-allowed-topology-keys` setting. If the nodes report the required label but the setting filters it out, provisioning is rejected instead of silently creating an unconstrained volume. If the nodes do not report the label at all, Longhorn creates the volume without a topology constraint, so a single StorageClass can serve both labeled multi-zone clusters and unlabeled single-zone clusters.

For `zonal` volumes, Longhorn requires `replicaZoneSoftAntiAffinity` to be `enabled`. A zonal volume keeps all replicas in one zone, so hard zone anti-affinity cannot be satisfied for more than one replica. If `replicaZoneSoftAntiAffinity` is unset or set to `ignored`, Longhorn records `enabled` on the volume instead of following the global setting. A StorageClass that explicitly sets both `volumeTopology: "zonal"` and `replicaZoneSoftAntiAffinity: "disabled"` is rejected during provisioning.

> **Warning:** A stored `topologyRequirement` is immutable. Longhorn strictly enforces this domain for initial placement, rebuilds, replica count changes, auto-balancing, and erasure-coded shards. If the resolved domain has no capacity, Longhorn **will not** fall back to another zone or region.

## Prerequisites

1. Nodes in your cluster must be labeled with the topology keys you plan to use. Most cloud providers set `topology.kubernetes.io/zone` and `topology.kubernetes.io/region` automatically; in on-premises or custom clusters, add the labels manually. Verify with:

   ```shell
   kubectl get nodes --label-columns topology.kubernetes.io/zone,topology.kubernetes.io/region
   ```

2. Configure the **CSI Allowed Topology Keys** setting in Longhorn. Set the value to a comma-separated list of topology keys that Longhorn should use when building PV `nodeAffinity`.

   - **Longhorn UI**: Go to **Setting > General > CSI Allowed Topology Keys** and enter, for example, `topology.kubernetes.io/zone` or `topology.kubernetes.io/zone,topology.kubernetes.io/region`.
   - **Longhorn API / kubectl**:
     ```shell
     kubectl -n longhorn-system edit settings.longhorn.io csi-allowed-topology-keys
     ```
     Set the `value` field to the topology keys you want Kubernetes PVs to use.

    > **Note:** Changing this setting takes effect for newly provisioned volumes. When adding a custom topology key other than the well-known hostname, zone, and region labels, restart the `longhorn-csi-plugin` DaemonSet so the nodes register the key in `CSINode`.

3. For topology-aware dynamic provisioning, set the StorageClass `volumeBindingMode` to `WaitForFirstConsumer`. This lets Kubernetes choose a consumer pod's node first, and then Longhorn resolves the volume topology from that node's topology labels. As a result, the PV `nodeAffinity` and Longhorn data placement follow the workload's actual failure domain. With `Immediate` binding, provisioning happens before any consumer pod is scheduled, so the selected topology may not match where the workload would otherwise run.

## How It Works

The following flowchart illustrates the provisioning lifecycle of a topology-aware volume, from PVC creation to failure domain enforcement:

```mermaid
%%{init: {'theme':'base', 'themeVariables': {
  'primaryColor':'#E8E1E4',
  'primaryBorderColor':'#B7A5B0',
  'primaryTextColor':'#2F2A2D',
  'lineColor':'#B7A5B0'
}, 'themeCSS': '.nodeLabel, .edgeLabel, .cluster-label { font-weight: normal; }'}}%%
flowchart TD
    A["PVC created<br/>(WaitForFirstConsumer StorageClass)"] --> B["Pod scheduled<br/>Kubernetes selects a node"]
  B --> C["CSI CreateVolume receives<br/>topology requirements"]
  C --> D["Keep only the csi-allowed-topology-keys<br/>Return accessible topology for PV nodeAffinity"]
    D --> E{"volumeTopology?"}
    E -->|any / unset| F["No constraint stored<br/>Replicas scheduled as before"]
    E -->|zonal| G["Pin the volume to one zone<br/>Require replicaZoneSoftAntiAffinity = enabled"]
    E -->|regional| H["Pin the volume to one region<br/>Replicas may still span zones in that region"]
    G --> I["Constraint applies to every placement:<br/>new replicas, rebuilds, replica-count changes,<br/>auto-balance, and erasure-coded shards.<br/>No fallback to another zone or region."]
    H --> I
```

The provisioning process follows these steps:

1. **Topology Discovery**: The Kubernetes CSI external-provisioner sends Longhorn the topology requirements in the `CreateVolume` request. With `WaitForFirstConsumer`, the requirements are based on the node selected for the first consumer pod.
2. **Filtering**: Longhorn keeps only the topology keys listed in `csi-allowed-topology-keys` and returns the filtered topology to Kubernetes. Kubernetes records the returned topology in the PV `nodeAffinity`.
3. **Volume Topology Enforcement**: If `volumeTopology` is `zonal` or `regional`, Longhorn also stores the selected domain in the Volume spec as `topologyRequirement` and uses it as a data placement constraint.

Several fields work together:

| Field | Role |
|-------|------|
| `csi-allowed-topology-keys` (Longhorn setting) | Controls which topology keys Longhorn includes in PV `nodeAffinity`. If empty, PVs do not receive topology-based `nodeAffinity`. |
| `allowedTopologies` (StorageClass field) | Restricts which topology values are eligible. For example, you can limit provisioning to zones `a` and `b` out of `a`, `b`, and `c`. |
| `volumeBindingMode` (StorageClass field) | `WaitForFirstConsumer` (WFFC) delays provisioning until a pod is scheduled, giving the scheduler a preferred node. `Immediate` provisions right away. |
| `volumeTopology` (StorageClass parameter) | Controls Longhorn data placement. `any` leaves placement unconstrained, `zonal` pins the volume data to one zone, and `regional` pins it to one region. |

## Recommended Usage

Use topology-aware provisioning when the workload's failure domain should also define where Longhorn stores the volume data. Select the topology mode based on the placement goal and make sure the selected domain has enough Longhorn nodes, disks, and capacity for the requested replica count or sharding layout.

| Goal | Recommended configuration | Notes |
| --- | --- | --- |
| Keep workloads and volume data in one zone | Set `volumeTopology: "zonal"`, configure `csi-allowed-topology-keys` with `topology.kubernetes.io/zone`, and use `volumeBindingMode: WaitForFirstConsumer`. | Use this for zone-scoped applications, edge clusters with zone-local storage, or workloads where cross-zone I/O adds latency or network transfer cost. |
| Keep workloads and volume data in one region | Set `volumeTopology: "regional"`, configure `csi-allowed-topology-keys` with `topology.kubernetes.io/region`, and use `volumeBindingMode: WaitForFirstConsumer`. | Use this for multi-zone regional clusters that must avoid cross-region traffic while still allowing replicas to spread across zones in the selected region. |
| Allow normal Longhorn scheduling | Leave `volumeTopology` unset or set it to `"any"`. | Use this when cross-zone or cross-region placement is acceptable, or when the cluster does not have stable topology labels. |

Follow these guidelines when enabling `volumeTopology`:

- Configure `csi-allowed-topology-keys` before creating StorageClasses that use `volumeTopology`.
- Use `allowedTopologies` to limit the eligible domains when only specific zones or regions should be used.
- For sharded volumes, use `zonal` or `regional` only when every required shard can be placed in the selected domain. If the selected domain lacks enough eligible nodes or disks, provisioning or rebuilds wait instead of falling back to another domain.

## Examples

The examples below assume a cluster with six nodes across three zones in one region:

| Node | Zone | Region |
|------|------|--------|
| node2 | a | us-central |
| node3 | b | us-central |
| node4 | c | us-central |
| node5 | a | us-central |
| node6 | b | us-central |
| node7 | c | us-central |

### Zonal Volume Placement

Use `volumeTopology: "zonal"` when you want the pod and all Longhorn data for the volume to remain in one zone.

**Longhorn setting:**

```
csi-allowed-topology-keys = topology.kubernetes.io/zone
```

**StorageClass:**

```yaml
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: longhorn-zonal
provisioner: driver.longhorn.io
volumeBindingMode: WaitForFirstConsumer
parameters:
  numberOfReplicas: "3"
  volumeTopology: "zonal"
  replicaZoneSoftAntiAffinity: "enabled"
allowedTopologies:
  - matchLabelExpressions:
      - key: topology.kubernetes.io/zone
        values:
          - a
          - b
          - c
```

**Result:** Longhorn resolves the volume to the zone selected during provisioning. If the first consumer pod is scheduled on `node2`, the PV `nodeAffinity` is set to `zone in [a]`, and all replicas, rebuild replicas, auto-balance candidates, and erasure-coded shards for the volume must stay in zone `a`. If zone `a` has no capacity, scheduling waits instead of falling back to another zone.

### Regional Volume Placement

Use `volumeTopology: "regional"` when you want all Longhorn data to remain in one region while still allowing replicas to spread across zones inside that region.

**Longhorn setting:**

```
csi-allowed-topology-keys = topology.kubernetes.io/region
```

**StorageClass:**

```yaml
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: longhorn-regional
provisioner: driver.longhorn.io
volumeBindingMode: WaitForFirstConsumer
parameters:
  numberOfReplicas: "3"
  volumeTopology: "regional"
allowedTopologies:
  - matchLabelExpressions:
      - key: topology.kubernetes.io/region
        values:
          - us-central
```

**Result:** The PV `nodeAffinity` is set to `region in [us-central]`, and Longhorn schedules the volume data only on nodes in `us-central`. Replicas may be placed in different zones within `us-central` according to the normal Longhorn scheduling and anti-affinity rules.

## Notes and Warnings

- `volumeTopology` has no effect on volumes with `dataLocality: strict-local`, and `allowedTopologies` is not written to the PV. Longhorn ignores the CSI topology for these volumes and places the data on the workload node.
- Avoid setting `volumeTopology` on a StorageClass used for linked clones. A linked clone replica can be scheduled only on a node that has a healthy source replica, so its data placement is already constrained by the source volume. A `zonal` or `regional` clone volume stays unschedulable if the selected domain has no eligible source replica.
- With `Immediate` binding, the failure domain is resolved from the first accessible topology in the provisioner-supplied requirements at creation time, and the first consumer pod is then constrained to that domain through the PV `nodeAffinity`.
- Existing volumes and StorageClasses are unchanged unless you set `volumeTopology` on a StorageClass used for new PVCs.

## Related Documentation

- [Storage Class Parameters](../../../references/storage-class-parameters/)
- [CSI Allowed Topology Keys setting](../../../references/settings/#csi-allowed-topology-keys)
- [Scheduling](../scheduling)
