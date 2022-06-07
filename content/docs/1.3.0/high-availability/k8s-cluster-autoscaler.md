---
  title: Kubernetes Cluster Autoscaler Support (Experimental)
  weight: 1
---

By default, Longhorn blocks Kubernetes Cluster Autoscaler from scaling down because:
- Longhorn creates PodDisruptionBudgets for all engine and replica instance-manager pods.
- Longhorn instance manager pods have strict PodDisruptionBudgets.
- Longhorn instance manager pods are not backed by a controller.
- Longhorn pods are using local storage volume mounts.

For more information, see [What types of pods can prevent CA from removing a node?](https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/FAQ.md#what-types-of-pods-can-prevent-ca-from-removing-a-node)

If you want to unblock the Kubernetes Cluster Autoscaler scaling, you can set the setting [Kubernetes Cluster Autoscaler Enabled](../../references/settings#kubernetes-cluster-autoscaler-enabled-experimental).

When this setting is enabled, Longhorn will actively manage the instance manager PodDisruptionBudgets:
- When volume is attached, Longhorn creates instance manager PodDisruptionBudgets for all engines and replicas.
- When volume is detached, Longhorn deletes the engine instance manager and keeps the minimum of 1 replica instance manager PodDisruptionBudget.

When this setting is enabled, Longhorn will also add `cluster-autoscaler.kubernetes.io/safe-to-evict` annotation to Longhorn workloads that are not backed by a controller or using local storage mounts.

> **Warning:** Replica rebuilding could be expensive because nodes with reusable replicas could get removed by the Kubernetes Cluster Autoscaler.
