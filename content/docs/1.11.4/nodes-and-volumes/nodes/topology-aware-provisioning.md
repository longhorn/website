---
title: Topology-Aware Provisioning
weight: 6
---

Topology-aware provisioning allows you to control the `nodeAffinity` rules that Kubernetes writes into a PersistentVolume (PV) at creation time. This is useful when you want to pin volumes to specific zones or regions so that pods and their data always land in the same failure domain.

Longhorn supports this through two complementary features:

- **`csi-allowed-topology-keys` setting** — Controls which topology keys (for example, `topology.kubernetes.io/zone`) appear in the PV `nodeAffinity`.
- **`strictTopology` StorageClass parameter** — When enabled, pins the PV to the topology of the exact node selected by the scheduler instead of all matching topologies.

## Prerequisites

1. Nodes in your cluster must be labeled with the topology keys you plan to use. Kubernetes automatically applies the well-known label `topology.kubernetes.io/zone` in most cloud environments. Verify with:

   ```shell
   kubectl get nodes --label-columns topology.kubernetes.io/zone
   ```

2. Configure the **CSI Allowed Topology Keys** setting in Longhorn. Set the value to a comma-separated list of topology keys that Longhorn should pass through to Kubernetes.

   - **Longhorn UI**: Go to **Setting > General > CSI Allowed Topology Keys** and enter, for example, `topology.kubernetes.io/zone`.
   - **Longhorn API / kubectl**:
     ```shell
     kubectl -n longhorn-system edit settings.longhorn.io csi-allowed-topology-keys
     ```
     Set the `value` field to `topology.kubernetes.io/zone`.

   > **Note:** After changing this setting, you must manually restart the longhorn-csi-plugin DaemonSet for the change to take effect. Topology is applied correctly only after the CSI plugin pod on each node has restarted.

## How It Works

When a PVC is created against a StorageClass that uses the Longhorn CSI driver, several fields interact to determine what `nodeAffinity` the resulting PV receives:

| Field | Role |
|-------|------|
| `csi-allowed-topology-keys` (Longhorn setting) | Tells the CSI driver which topology keys to advertise. If empty (the default), no topology information is passed to Kubernetes, and PVs do not receive topology-based `nodeAffinity`. |
| `allowedTopologies` (StorageClass field) | Restricts which topology values are eligible. For example, you can limit provisioning to zones `a` and `b` out of `a`, `b`, and `c`. |
| `volumeBindingMode` (StorageClass field) | `WaitForFirstConsumer` (WFFC) delays provisioning until a pod is scheduled, giving the scheduler a preferred node. `Immediate` provisions right away. |
| `strictTopology` (StorageClass parameter) | When `"true"` and used with `WaitForFirstConsumer`, the PV is pinned to only the zone of the node where the pod was scheduled, rather than all allowed zones. This setting has effect only when `csi-allowed-topology-keys` includes the relevant topology key. |

## Examples

The examples below assume a cluster with six nodes across three zones:

| Node | Zone |
|------|------|
| node2 | a |
| node3 | b |
| node4 | c |
| node5 | a |
| node6 | b |
| node7 | c |

### Basic Zone-Level Affinity

Use `WaitForFirstConsumer` together with `allowedTopologies` and `csi-allowed-topology-keys` to restrict volumes to specific zones.

**Longhorn setting:**

```
csi-allowed-topology-keys = topology.kubernetes.io/zone
```

**StorageClass:**

```yaml
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: longhorn-zone-ab
provisioner: driver.longhorn.io
volumeBindingMode: WaitForFirstConsumer
parameters:
  numberOfReplicas: "3"
allowedTopologies:
  - matchLabelExpressions:
      - key: topology.kubernetes.io/zone
        values:
          - a
          - b
```

**Result:** The PV `nodeAffinity` is set to `zone in [a, b]`. The PV can only be attached to nodes in zones `a` or `b`.

### Strict Topology Pinning

Add `strictTopology: "true"` to pin the PV to the exact zone of the scheduled node.

**Longhorn setting:**

```
csi-allowed-topology-keys = topology.kubernetes.io/zone
```

**StorageClass:**

```yaml
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: longhorn-strict-zone
provisioner: driver.longhorn.io
volumeBindingMode: WaitForFirstConsumer
parameters:
  numberOfReplicas: "3"
  strictTopology: "true"
allowedTopologies:
  - matchLabelExpressions:
      - key: topology.kubernetes.io/zone
        values:
          - a
          - b
          - c
```

**Result:** Even though all three zones are listed in `allowedTopologies`, the PV `nodeAffinity` is set to only the zone of the node where the pod was scheduled (for example, `zone in [a]` if the pod lands on `node2` or `node5`).

## Behavior Reference

In the following table, zones `[a, b, c]` represent all zones present in the example cluster above.

| # | `volumeBindingMode` | `allowedTopologies` | `csi-allowed-topology-keys` | `strictTopology` | PV `nodeAffinity` |
|--:|---|---|---|---|---|
| 1 | Immediate | None | `""` (empty) | false | None |
| 2 | Immediate | None | `zone` | false | zone in [a, b, c] |
| 3 | Immediate | zone: [a, b] | `zone` | false | zone in [a, b] |
| 4 | WFFC | None | `""` (empty) | false | None |
| 5 | WFFC | None | `zone` | false | zone in [a, b, c] |
| 6 | WFFC | None | `zone` | true | zone in [selected] |
| 7 | WFFC | zone: [a] | `zone` | false | zone in [a] |
| 8 | WFFC | zone: [a, b, c] | `zone` | true | zone in [selected] |

> In this table, `zone` is shorthand for `topology.kubernetes.io/zone`, and `[selected]` means the zone of the node chosen by the Kubernetes scheduler.

**Key takeaways:**

- Without `csi-allowed-topology-keys`, no topology information is passed and PVs do not receive topology-based `nodeAffinity` (scenarios 1, 4).
- `strictTopology` only pins the PV to the scheduled Pod's topology when used with `WaitForFirstConsumer`. With `Immediate`, the PV is created before the Pod is scheduled, so its topology is selected randomly.
- `allowedTopologies` narrows the set of eligible zones; `strictTopology` further narrows it to the single selected zone.

## Notes and Warnings

- Do **not** use `allowedTopologies` together with `dataLocality: strict-local`. The PV `nodeAffinity` is immutable once set and will conflict with Longhorn's strict-local volume pinning. See [Data Locality](../../../high-availability/data-locality/) for details.
- The most common configuration for users who do **not** need topology-aware provisioning is to leave `csi-allowed-topology-keys` empty (scenarios 1 and 4). This is the default.
- For users who **do** want topology-aware provisioning, the recommended configurations are scenarios 7 and 8 — use `WaitForFirstConsumer` together with `allowedTopologies` and `csi-allowed-topology-keys`.

## Related Documentation

- [Storage Class Parameters](../../../references/storage-class-parameters/)
- [CSI Allowed Topology Keys setting](../../../references/settings/#csi-allowed-topology-keys)
- [Scheduling](../scheduling)
