---
title: Graceful Node Removal
weight: 7
---

Removing a node from a Kubernetes cluster requires careful coordination with Longhorn to ensure data availability. Simply running `kubectl delete node` is insufficient because Kubernetes does not automatically notify CSI storage layers to migrate data replicas before the node is destroyed.

If a node is removed without following this procedure, the replicas stored on that node will be lost, potentially leaving your volumes in a **Degraded** or **Faulted** state.

## Prerequisites

- The cluster must have enough available space and schedulable nodes to receive the replicas being moved.
- Verify volume health: Ensure no volumes are currently `Degraded` before starting.

## Step-by-Step Procedure

### 1. Cordon and Drain the Kubernetes Node

Prepare the node for removal by moving all running workloads (Pods) to other nodes. Using a timeout and force flag ensures that the drain completes even if some pods are slow to terminate or protected by Pod Disruption Budgets.

```bash
kubectl cordon <NODE_NAME>
kubectl drain <NODE_NAME> \
  --ignore-daemonsets \
  --delete-emptydir-data \
  --force \
  --grace-period=-1 \
  --timeout=300s
```

> **Note**: The `--grace-period=-1` flag allows pods to honor their own `terminationGracePeriodSeconds`. The `--force` flag is necessary to remove pods that are not managed by a ReplicationController, ReplicaSet, Job, DaemonSet, or StatefulSet.

### 2. Disable Scheduling and Trigger Eviction

You must prevent new data from being scheduled on the node and move existing data to other healthy nodes. This can be done via the Longhorn UI or the command line.

#### Via Longhorn UI

1. Open the Longhorn UI and navigate to the **Nodes** tab.
2. Select the node and click the **Edit Node** button.
3. Set **Node Scheduling** to **Disable**.
4. Set **Eviction Requested** to **true**.
5. Click **Save**.

#### Via kubectl

Patch the Longhorn Node CR to disable scheduling and request eviction in a single command:

```bash
kubectl patch node.longhorn.io <NODE_NAME> \
  -n longhorn-system --type=merge \
  -p '{"spec":{"allowScheduling":false,"evictionRequested":true}}'
```

### 3. Monitor Eviction Progress

Before proceeding to delete the node, you must ensure all replicas has successfully migrated.

* **Via UI**: In the **Nodes** list, watch the **Replicas** column for the node. Wait until the count reaches **0**.
* **Via CLI**: Poll the node status to confirm all resources (Replicas and Backing Images) have migrated:

    ```bash
    kubectl get node.longhorn.io <NODE_NAME> -n longhorn-system -o json \
    | jq '.status.diskStatus | to_entries[]
            | {disk: .key,
            scheduledReplicas: (.value.scheduledReplica | length),
            scheduledBackingImages: (.value.scheduledBackingImage | length)}'
    ```

> **Note**: Eviction is complete only when every disk reports `scheduledReplicas: 0` and `scheduledBackingImages: 0`. This process works for both `Attached` and `Detached` volumes. Longhorn will automatically attach detached volumes to migrate data and detach them when finished.

### 4. Delete the Kubernetes Node

Remove the node resource from the Kubernetes cluster. Longhorn requires the Kubernetes node to be removed before it will allow the deletion of the Longhorn Node resource.

```bash
kubectl delete node <NODE_NAME>
```

### 5. Delete the Longhorn Node

Once the Kubernetes node is deleted, the Longhorn UI will show the node in a **Down** state. You can now safely remove the metadata.

- **Via UI**: In the **Nodes** tab, the **Delete** button for the node will now be enabled. Click **Delete**.
- **Via CLI**: If you prefer using `kubectl`, you can delete the Longhorn Node resource directly using the following command:    
    ```bash
    kubectl -n longhorn-system delete nodes.longhorn.io <NODE_NAME>
    ```

## Troubleshooting

### Node "Delete" button is greyed out

The UI disables the **Delete** button if the corresponding Kubernetes node still exists. Ensure you have successfully executed `kubectl delete node <NODE_NAME>` first.

### Eviction is stuck

If the replica count does not reach 0, check the **Events** log. Common causes include:

- **Insufficient Space**: No other nodes have enough disk space to house the replicas. To recover from this, you can refer to [Manual Recovery of Nodes with Insufficient Space](../../../../kb/manual-recovery-of-nodes-with-insufficient-space).
- **Anti-Affinity Constraints**: If `Replica Node Level Soft Anti-Affinity` is disabled, and all other nodes already host a replica of the same volume, the eviction will have no valid destination. To learn more about anti-affinity and how to resolve this, see [Replica Scheduling and Anti-Affinity](../../best-practices.md#replica-node-level-soft-anti-affinity).
- **Volume Health**: Rebuilding cannot start if the volume is already in a `Faulted` state. To learn more volume and volume health, refer to [Volume documentation](../volumes/create-volumes).
