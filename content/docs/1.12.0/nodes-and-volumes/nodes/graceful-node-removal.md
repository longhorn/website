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

Prepare the node for removal by moving all running workloads (Pods) to other nodes.

```bash
kubectl cordon <NODE_NAME>
kubectl drain <NODE_NAME> --ignore-daemonsets --delete-emptydir-data
```

### 2. Disable Scheduling in Longhorn

Prevent Longhorn from attempting to schedule new replicas onto this node.

1. Open the Longhorn UI and navigate to the **Node** tab.
2. Select the node and click **Edit Node and Disks**.
3. Set **Scheduling** to **Disable**.
4. Click **Save**.

### 3. Trigger Node Eviction

Evict existing replicas to other healthy nodes.

1. In the **Edit Node** dialog, set **Eviction Requested** to **true**.
2. Click **Save**.
3. **Monitor Progress**: In the **Node** list, watch the **Replicas** column. Wait until the count reaches **0**.

> **Note**: This process works for both `Attached` and `Detached` volumes. Longhorn will automatically attach detached volumes to migrate data and detach them when finished. To maintain high availability, Longhorn only deletes the old replica after the new replica has successfully finished rebuilding.

### 4. Delete the Kubernetes Node

Remove the node resource from the Kubernetes cluster. Longhorn requires the Kubernetes node to be removed before it will allow the deletion of the Longhorn Node resource.

```bash
kubectl delete node <NODE_NAME>
```

### 5. Delete the Longhorn Node

Once the Kubernetes node is deleted, the Longhorn UI will show the node in a **Down** state. You can now safely remove the metadata.

- **Via UI**: In the **Node** tab, the **Remove** button for the node will now be enabled. Click **Remove**.
- **Via CLI**: If you prefer using `kubectl`, you can delete the Longhorn Node resource directly using the following command:    
    ```bash
    kubectl -n longhorn-system delete nodes.longhorn.io <NODE_NAME>
    ```

## Troubleshooting

### Node "Remove" button is greyed out

The UI disables the **Remove** button if the corresponding Kubernetes node still exists. Ensure you have successfully executed `kubectl delete node <NODE_NAME>` first.

### Eviction is stuck

If the replica count does not reach 0, check the **Events** log. Common causes include:

- **Insufficient Space**: No other nodes have enough disk space to house the replicas.
- **Anti-Affinity Constraints**: If `Replica Node Level Soft Anti-Affinity` is disabled, and all other nodes already host a replica of the same volume, the eviction will have no valid destination.
- **Volume Health**: Rebuilding cannot start if the volume is already in a `Faulted` state.
