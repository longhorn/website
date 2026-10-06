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

Eviction moves the data but does not itself remove the Longhorn Node CR. After CAPI removes the Kubernetes Node object, Longhorn's Kubernetes Node controller automatically deletes the corresponding Longhorn Node CR. No explicit Longhorn Node deletion is required in the normal replacement workflow.

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

Eviction is complete when every disk reports `scheduledReplicas: 0` and `scheduledBackingImages: 0`. Once confirmed, allow CAPI to proceed with Machine deletion, including workload drain and volume detachment. Longhorn automatically cleans up its Node CR after the Kubernetes Node is removed. You can optionally [verify node removal](#verify-node-removal-optional).

> **Note**: Eviction time depends on data size and network throughput, and may take minutes to hours for large volumes.

## Method 2: Automated eviction via CAPI pre-termination hook (recommended)

For clusters where CAPI performs rolling replacements regularly, implement this workflow in the component that manages the Longhorn cluster, using a controller that integrates with the CAPI Machine deletion lifecycle.

### How the hook works

CAPI supports pre-termination hooks on Machine CRs (see [Machine Deletions](https://cluster-api.sigs.k8s.io/tasks/automated-machine-management/machine_deletions)). When a Machine deletion is triggered, CAPI pauses at the pre-terminate phase until all registered hook annotations are removed from the Machine CR. The managing component's controller can use this to drive Longhorn node eviction before the underlying node is terminated.

Use an annotation key in the form `pre-terminate.delete.hook.machine.cluster.x-k8s.io/<controller-name>`, replacing `<controller-name>` with a name identifying the controller that owns the hook. This is an integration implemented by the managing component, not a built-in Longhorn hook.

The general reconcile flow is:

1. **Register the hook before deletion starts**: Add the controller-owned hook annotation to the Machine CR before a rollout can delete it. This ensures CAPI cannot pass the pre-terminate phase before the hook is registered.
2. **Machine deletion detected**: Watch for Machine CRs entering the deletion phase.
3. **Evict the Longhorn node**: Connect to the workload cluster's Kubernetes API and disable scheduling and request eviction on the corresponding Longhorn Node CR.
4. **Wait for eviction to complete**: Poll the Longhorn node status until all disks report zero scheduled replicas and backing images.
5. **Release the hook**: Remove only this controller's hook annotation from the Machine CR. Once all pre-termination hooks are released, CAPI resumes infrastructure termination and Kubernetes Node deletion.

> **Important**: Release the pre-termination hook after eviction completes; do not wait for Kubernetes Node removal or Longhorn Node CR deletion inside the hook. CAPI removes the Kubernetes Node later in its deletion sequence, which triggers Longhorn's automatic cleanup. Waiting for cleanup inside the hook would block progress.

The controller implementation and workload cluster client configuration are left for the managing component to provide.

### CR operations

**Trigger eviction** - patch the Longhorn Node CR on the workload cluster to disable scheduling and request eviction:

```bash
kubectl patch node.longhorn.io <node-name> \
  -n longhorn-system --type=merge \
  -p '{"spec":{"allowScheduling":false,"evictionRequested":true}}'
```

**Wait for eviction to complete** - poll until all disks on the node report zero scheduled replicas and backing images:

```bash
until kubectl get node.longhorn.io <node-name> -n longhorn-system -o json \
  | jq -e '[.status.diskStatus | to_entries[].value |
             (.scheduledReplica | length) == 0 and
             (.scheduledBackingImage | length) == 0] | all' > /dev/null; do
  sleep 10
done
```

Once the loop exits, remove this controller's hook annotation from the Machine CR to release the pre-termination hold and allow CAPI to proceed with node termination. After the Kubernetes Node is removed, Longhorn automatically deletes its Node CR; the managing component does not need to implement a separate deletion step.

## Verify node removal (optional)

After eviction and CAPI node termination, you can verify automatic cleanup from the **workload cluster**, not the CAPI management cluster:

```bash
kubectl wait --for=delete node/<node-name> --timeout=300s
kubectl -n longhorn-system wait --for=delete nodes.longhorn.io/<node-name> --timeout=300s
```

An already absent resource may return `NotFound`, which also confirms removal. Cleanup is asynchronous. If either wait times out or another error occurs, investigate the relevant controller rather than treating the replacement as complete. A Machine deletion request or a Kubernetes Node in the `NotReady` state is not confirmation that the Kubernetes Node object has been removed.

Automatic deletion still honors Longhorn's deletion safeguards: scheduling must be disabled, no replicas or engines may remain on the node, and Longhorn must observe that the node is no longer ready because the Kubernetes Node or manager Pod is missing. Eviction and workload drain prepare the node for this cleanup.

If the Kubernetes Node is gone but the Longhorn Node CR remains, check these conditions and inspect the Longhorn manager logs for admission, reconciliation, or finalizer errors. Manual deletion of the Longhorn Node CR is not a required step in the normal workflow and does not bypass these safeguards.

## Related links

- [longhorn/longhorn#12870 - Knowledge base: evict Longhorn node during CAPI node rolling replacement](https://github.com/longhorn/longhorn/issues/12870)
- [Longhorn 1.13.0: Graceful Node Removal](../../docs/1.13.0/nodes-and-volumes/nodes/graceful-node-removal)
- [CAPI: Machine Deletions and pre-termination hooks](https://cluster-api.sigs.k8s.io/tasks/automated-machine-management/machine_deletions)
