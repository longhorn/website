---
title: "Troubleshooting: Orphan Engine Or Replica Instance"
authors:
- "Raphanus Lo"
draft: false
date: 2025-05-19
versions:
- "All versions"
categories:
- "orphan"
---

## Applicable versions

* All longhorn versions

## Symptoms

The `instancemanager` custom resource (CR) lists runtime instances (including engine and replica runtime instances), but the corresponding engine or replica CRs no longer exist in the cluster.

## Details

During unexpected node disconnections or interruptions (such as during a Longhorn upgrade), engine or replica runtime instances can become detached from their corresponding CRs. These are known as **orphaned instances**.

The Instance Manager can detect orphaned instances and will list them in its status. However, it cannot remove them through standard cleanup procedures. This can block normal operations like system upgrades or node replacements, since the Instance Manager cannot be shut down, restarted, or upgraded until all managed instances are safely cleaned up.

Starting with Longhorn v1.9.0, an orphaned instance tracking mechanism is introduced to help manage these orphaned instances. However, if an Instance Manager was created by a Longhorn version earlier than v1.9.0, it will not be able to track or remove orphaned instances. In such cases, you can manually remove them by following the provided workaround.

## Workaround

1. List the engine and replica instances on the node (In this example, the node is `worker-node1`.)
    Example:
    ```bash
    # kubectl -n longhorn-system get instancemanager -o yaml -l 'longhorn.io/data-engine=v1,longhorn.io/node=worker-node1'

    apiVersion: v1
    items:
    - apiVersion: longhorn.io/v1beta2
      kind: InstanceManager
      metadata:
        labels:
          ...
          longhorn.io/node: worker-node1
        name: instance-manager-8a88a7dd35eab21f30ec566737e87dd0
        namespace: longhorn-system
        ...
      spec:
        nodeID: worker-node1
        ...
      status:
        ...
        instanceEngines:
          orphan-engine-01-e-0:
            spec:
              dataEngine: v1
              name: example-orphan-engine-01-e-0
            ...
        instanceReplicas:
          orphan-replica-01-r-0:
            spec:
              dataEngine: v1
              name: example-orphan-replica-01-r-0
            ...
    ```
1. Check the existence of the corresponding engine or replica CR to identify orphaned instances (In this example, the engine is `example-orphan-engine-01-e-0` and the replica is`example-orphan-replica-01-r-0`).
    Example:
    ```bash
    # kubectl -n longhorn-system get engine example-orphan-engine-01-e-0
    error: the server doesn't have a resource type "engine"

    # kubectl -n longhorn-system get replica example-orphan-replica-01-r-0
    error: the server doesn't have a resource type "replica"
    ```
1. Shell into the pod whose name matches the Instance Manager (In this example, the instance manager is `instance-manager-8a88a7dd35eab21f30ec566737e87dd0`).
    Example:
    ```
    # kubectl -n longhorn-system exec -i -t instance-manager-8a88a7dd35eab21f30ec566737e87dd0 -- /bin/bash
    ```
1. Use the `instance-manager` CLI tool to remove the orphaned engine and replica instances.
    ```bash
    # instance-manager process delete --name example-orphan-engine-01-e-0
    # instance-manager process delete --name example-orphan-replica-01-r-0
    ```
1. Confirm that the instances are no longer listed in the Instance Manager status.
    ```bash
    # kubectl -n longhorn-system get instancemanager -o yaml -l 'longhorn.io/data-engine=v1,longhorn.io/node=worker-node1'

    apiVersion: v1
    items:
    - apiVersion: longhorn.io/v1beta2
      kind: InstanceManager
      metadata:
        labels:
          ...
          longhorn.io/node: worker-node1
        name: instance-manager-8a88a7dd35eab21f30ec566737e87dd0
        namespace: longhorn-system
        ...
      spec:
        nodeID: worker-node1
        ...
      status:
        ...(engine and replica are removed)..
    ```

## Related information

- Related Longhorn issue [#6764](https://github.com/longhorn/longhorn/issues/6764).
