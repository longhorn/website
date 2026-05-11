---
title: "Graceful Longhorn Node Eviction Before Cluster API (CAPI) Node Replacement"
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

- At least one other schedulable node with sufficient disk space must be available to receive the migrated replicas and backing images (otherwise eviction will stall and not complete).

> **Note**: The number of eligible target nodes depends on your replica anti-affinity settings. Hard anti-affinity (node, zone, or disk level) prevents replicas of the same volume from colocating, which means eviction requires at least as many suitable nodes as the volume's replica count. If anti-affinity constraints cannot be satisfied on the remaining nodes, eviction will stall. For details on how scheduling constraints work, see [Scheduling](../../docs/1.12.0/nodes-and-volumes/nodes/scheduling).

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
3. **Evict the Longhorn node**: Connect to the workload cluster’s Longhorn API endpoint and disable scheduling and request eviction on the corresponding Longhorn Node CR.
4. **Wait for eviction to complete**: Poll the Longhorn node status until all disks report zero scheduled replicas and backing images.
5. **Release the hook**: Remove the annotation `pre-terminate.delete.hook.machine.cluster.x-k8s.io/longhorn-node-eviction` from the Machine CR. CAPI resumes and terminates the node.

The hook annotation key, controller wiring, and workload cluster client configuration are left for the implementer to adapt to their environment.

### CR operations

**Trigger eviction** — patch the Longhorn Node CR on the workload cluster to disable scheduling and request eviction:

```bash
kubectl patch node.longhorn.io <node-name> \
  -n longhorn-system --type=merge \
  -p '{"spec":{"allowScheduling":false,"evictionRequested":true}}'
```

**Wait for eviction to complete** — poll until all disks on the node report zero scheduled replicas and backing images:

```bash
until kubectl get node.longhorn.io <node-name> -n longhorn-system -o json \
  | jq -e '[.status.diskStatus | to_entries[].value |
             (.scheduledReplica | length) == 0 and
             (.scheduledBackingImage | length) == 0] | all' > /dev/null; do
  sleep 10
done
```

Once the loop exits, remove the hook annotation from the Machine CR to release the pre-termination hold and allow CAPI to proceed with node termination.

## Related links

- [longhorn/longhorn#12870 - Knowledge base: evict Longhorn node during CAPI node rolling replacement](https://github.com/longhorn/longhorn/issues/12870)
- [CAPI: Machine Deletions and pre-termination hooks](https://cluster-api.sigs.k8s.io/tasks/automated-machine-management/machine_deletions)
