---
title: "How to Evict Longhorn Node During CAPI Node Rolling Replacement"
authors:
  - "Raphanus Lo"
draft: false
date: 2026-04-01
versions:
  - "all"
categories:
  - "instruction"
  - "nodes"
---

## Applicable versions

All Longhorn versions.

## Background

Cluster API (CAPI) performs rolling node replacement by provisioning a new Machine CR and then deleting the old one. If Longhorn has replicas or backing images scheduled on the node being removed, those resources are lost abruptly when the node terminates, which can temporarily degrade volume redundancy and trigger replica rebuilds.

Requesting node eviction before the Machine is deleted allows Longhorn to migrate all scheduled replicas and backing images to other nodes gracefully, keeping volumes healthy throughout the replacement.

## Prerequisites

- The volumes using the node being replaced must have a replica count greater than 1 (otherwise data loss can occur during node removal).
- At least one other schedulable node with sufficient disk space must be available to receive the migrated replicas and backing images (otherwise eviction will stall and not complete).

## Method 1: Manual eviction via kubectl

Use this approach for one-off replacements or when automation is not yet in place.

Patch the Longhorn Node CR to disable scheduling and request eviction:

```bash
kubectl patch node.longhorn.io <node-name> \
  -n longhorn-system --type=merge \
  -p '{"spec":{"allowScheduling":false,"evictionRequested":true}}'
```

Then poll the node status to confirm all resources have migrated off:

```bash
kubectl get node.longhorn.io <node-name> -n longhorn-system -o json \
  | jq '.status.diskStatus | to_entries[]
        | {disk: .key,
           scheduledReplicas: (.value.scheduledReplica | length),
           scheduledBackingImages: (.value.scheduledBackingImage | length)}'
```

Eviction is complete when every disk reports `scheduledReplicas: 0` and `scheduledBackingImages: 0`. Once confirmed, Longhorn no longer depends on the node, and it is safe for CAPI to proceed with Machine deletion.

> **Note**: Eviction time depends on data size and network throughput, and may take minutes to hours for large volumes.

## Method 2: Automated eviction via CAPI pre-termination hook (recommended)

For clusters where CAPI performs rolling replacements regularly, implement a custom controller that hooks into the CAPI Machine deletion lifecycle.

### How the hook works

CAPI supports pre-termination hooks on Machine CRs (see [Machine Deletions](https://cluster-api.sigs.k8s.io/tasks/automated-machine-management/machine_deletions)). When a Machine deletion is triggered, CAPI pauses at the pre-terminate phase until all registered hook annotations are removed from the Machine CR. A controller running in the management cluster can exploit this to drive Longhorn node eviction before the underlying node is terminated.

The general reconcile flow is:

1. **Machine deletion detected**: Watch for Machine CRs entering the deletion phase.
2. **Register the hook**: Add annotation `pre-terminate.delete.hook.machine.cluster.x-k8s.io/longhorn-node-eviction` to the Machine CR. This blocks CAPI from proceeding with node termination.
3. **Evict the Longhorn node**: Connect to the workload cluster’s Longhorn API endpoint and disable scheduling and reqCuest eviction on the corresponding Longhorn Node CR.
4. **Wait for eviction to complete**: Poll the Longhorn node status until all disks report zero scheduled replicas and backing images.
5. **Release the hook**: Remove the annotation `pre-terminate.delete.hook.machine.cluster.x-k8s.io/longhorn-node-eviction` from the Machine CR. CAPI resumes and terminates the node.

The hook annotation key, controller wiring, and workload cluster client configuration are left for the implementer to adapt to their environment.

### Python snippets

The following snippets use the [Longhorn Python client](https://github.com/longhorn/longhorn-tests/tree/master/manager/integration) connected to the workload cluster's Longhorn API endpoint.

**Trigger eviction**

```python
# Reconcile: Machine CR deletion event detected.
# Register the pre-termination hook on the Machine CR to block CAPI:
#   pre-terminate.delete.hook.machine.cluster.x-k8s.io/longhorn-node-eviction
# Then evict the corresponding Longhorn node on the workload cluster.
def evict_longhorn_node(client, node_name):
    node = client.by_id_node(node_name)
    client.update(node, allowScheduling=False, evictionRequested=True)
```

**Observe eviction status**

```python
# Poll until all disks have no scheduled replicas or backing images.
# When this returns True, remove the hook annotation from the Machine CR
# to unblock CAPI and allow node termination to proceed:
#   pre-terminate.delete.hook.machine.cluster.x-k8s.io/longhorn-node-eviction
def wait_for_eviction_complete(client, node_name, interval=10, timeout=600):
    import time
    deadline = time.time() + timeout
    while time.time() < deadline:
        node = client.by_id_node(node_name)
        all_evicted = all(
            len(disk.scheduledReplica) == 0 and
            len(disk.scheduledBackingImage) == 0
            for disk in node.disks.values()
        )
        if all_evicted:
            return True
        time.sleep(interval)
    return False
```

## Related links

- [longhorn/longhorn#12870 - Knowledge base: evict Longhorn node during CAPI node rolling replacement](https://github.com/longhorn/longhorn/issues/12870)
- [CAPI: Machine Deletions and pre-termination hooks](https://cluster-api.sigs.k8s.io/tasks/automated-machine-management/machine_deletions)
- [Longhorn Python client](https://github.com/longhorn/longhorn-tests/tree/master/manager/integration)
