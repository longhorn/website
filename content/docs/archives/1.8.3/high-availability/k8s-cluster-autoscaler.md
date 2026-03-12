---
  title: Kubernetes Cluster Autoscaler Support (Experimental)
  weight: 1
---

By default, Longhorn blocks Kubernetes Cluster Autoscaler from scaling down nodes because:
- Longhorn creates PodDisruptionBudgets for all engine and replica instance-manager pods.
- Longhorn instance manager pods have strict PodDisruptionBudgets.
- Longhorn instance manager pods are not backed by a Kubernetes built-in workload controller .
- Longhorn pods are using local storage volume mounts.

For more information, see [What types of pods can prevent CA from removing a node?](https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/FAQ.md#what-types-of-pods-can-prevent-ca-from-removing-a-node)

If you want to unblock the Kubernetes Cluster Autoscaler scaling, you can set the setting [Kubernetes Cluster Autoscaler Enabled](../../references/settings#kubernetes-cluster-autoscaler-enabled-experimental).

When this setting is enabled, Longhorn will retain the least instance-manager PodDisruptionBudget as possible. Each volume will have at least one replica under the protection of an instance-manager PodDisruptionBudget while no redundant PodDisruptionBudget blocking the Cluster Autoscaler from from scaling down.

When this setting is enabled, Longhorn will also add `cluster-autoscaler.kubernetes.io/safe-to-evict` annotation to Longhorn workloads that are not backed by a Kubernetes built-in workload controller or are using local storage mounts.

> **Warning:** Replica rebuilding could be expensive because nodes with reusable replicas could get removed by the Kubernetes Cluster Autoscaler.
