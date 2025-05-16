---
title: Orphaned Instance Cleanup
weight: 4
---

Longhorn can identify and clean up orphaned instances on each node.

## Orphaned Runtime Instance

When a network outage affects a Longhorn node, it may leave behind engine or replica runtime instances that are no longer tracked by the Longhorn system. The corresponding engine and replica CRs might be removed or rescheduled to another node during the outage. When the node comes back, the Longhorn system no longer tracks the corresponding runtime instances. These runtime instances, such as the engine and replica processes for v1 volumes, are called orphaned instances. Orphaned instances continue to consume CPU and memory.

Longhorn supports the detection and cleanup of orphaned instance. It identifies the instances and gives a list of `orphan` resources that describe those orphans. By default, Longhorn does not automatically delete `orphan` instances. Users can trigger the deletion of orphaned instances manually or have it done automatically.

### Example

The following example shows how to manage orphaned instances using `kubectl`.

#### Manage Orphaned Instances via kubectl

1. Introduce nodes that orphaned instance processes running on
    - Orphaned replica instance on Node `worker1`
     ```
     # kubectl -n longhorn-system describe instancemanager -l "longhorn.io/node=worker1"
     Name:         instance-manager-8ff396d6d3744979b32abafc6346781c
     Namespace:    longhorn-system
     Kind:         InstanceManager
     ...
     Status:
       Instance Replicas:
         pvc-569e44c0-b352-4aca-bf14-2cf7a6cfe86f-r-05660b73:
           Spec:
             Data Engine:  v1
             Name:         pvc-569e44c0-b352-4aca-bf14-2cf7a6cfe86f-r-05660b73
           Status:
             Conditions:         <nil>
             Endpoint:
             Error Msg:
             Listen:
             Port End:           10020
             Port Start:         10011
             Resource Version:   0
             State:              running
             Target Port End:    0
             Target Port Start:  0
             Type:               replica
     ...
     ```
    - Orphaned engine instance on Node `worker2`
     ```
     # kubectl -n longhorn-system describe instancemanager -l "longhorn.io/node=worker2"
     Name:         instance-manager-b87f10b867cec1dca2b814f5e78bcc90
     Namespace:    longhorn-system
     Kind:         InstanceManager
     ...
     Status:
       Instance Engines:
         pvc-569e44c0-b352-4aca-bf14-2cf7a6cfe86f-e-0:
           Spec:
             Data Engine:  v1
             Name:         pvc-569e44c0-b352-4aca-bf14-2cf7a6cfe86f-e-0
           Status:
             Conditions:
               Filesystem Read Only:  false
             Endpoint:
             Error Msg:
             Listen:
             Port End:                10020
             Port Start:              10020
             Resource Version:        0
             State:                   running
             Target Port End:         10020
             Target Port Start:       10020
             Type:                    engine
     ...
     ```

2. Longhorn detects the orphaned instances and creates an `orphan` resources describing the instances.
    ```
    # kubectl -n longhorn-system get orphan -l "longhorn.io/orphan-type in (engine-instance,replica-instance)"
    NAME                                                                      TYPE               NODE
    orphan-1807009489e50534c35c350e22680449c97deca4e5d3b72f4591976145f8bc41   engine-instance    worker2
    orphan-a91aa42ab5eda6b8b9fe1116d5b5f5673e5108d89be3db6fd18a275913463eef   replica-instance   worker1
    ```

3. You can view the list of `orphan` resources created by the Longhorn system by running `kubectl -n longhorn-system get orphan`.
    ```
    kubectl -n longhorn-system get orphan
    ```

4. Get the detailed information of one of the orphaned replica instance in `spec.parameters` by `kubectl -n longhorn-system get orphan <name>`.
    ```
    # kubectl -n longhorn-system get orphans orphan-a91aa42ab5eda6b8b9fe1116d5b5f5673e5108d89be3db6fd18a275913463eef -o yaml
    apiVersion: longhorn.io/v1beta2
    kind: Orphan
    metadata:
    creationTimestamp: "2025-05-02T06:07:32Z"
    finalizers:
    - longhorn.io
    generation: 1
    labels:
        longhorn.io/component: orphan
        longhorn.io/managed-by: longhorn-manager
        longhorn.io/orphan-type: replica-instance
        longhornnode: worker1
        longhornreplica: pvc-569e44c0-b352-4aca-bf14-2cf7a6cfe86f-r-05660b73

    ......

    spec:
      dataEngine: v1
      nodeID: worker1
      orphanType: replica-instance
      parameters:
        InstanceManager: instance-manager-8ff396d6d3744979b32abafc6346781c
        InstanceName: pvc-569e44c0-b352-4aca-bf14-2cf7a6cfe86f-r-05660b73
    status:
    conditions:
    - lastProbeTime: ""
        lastTransitionTime: "2025-05-02T06:06:39Z"
        message: ""
        reason: running
        status: "True"
        type: InstanceExist
    - lastProbeTime: ""
        lastTransitionTime: "2025-05-02T06:06:39Z"
        message: ""
        reason: ""
        status: "False"
        type: Error
    ownerID: worker1
    ```

5. Get the detailed information of one of the orphaned engine instance in `spec.parameters` by `kubectl -n longhorn-system get orphan <name>`.
    ```
    # kubectl -n longhorn-system get orphans orphan-1807009489e50534c35c350e22680449c97deca4e5d3b72f4591976145f8bc41 -o yaml
    apiVersion: longhorn.io/v1beta2
    kind: Orphan
    metadata:
    creationTimestamp: "2025-05-02T06:47:25Z"
    finalizers:
    - longhorn.io
    generation: 1
    labels:
        longhorn.io/component: orphan
        longhorn.io/managed-by: longhorn-manager
        longhorn.io/orphan-type: engine-instance
        longhornengine: pvc-569e44c0-b352-4aca-bf14-2cf7a6cfe86f-e-0
        longhornnode: worker2

    ......

    spec:
      dataEngine: v1
      nodeID: worker2
      orphanType: engine-instance
      parameters:
        InstanceManager: instance-manager-b87f10b867cec1dca2b814f5e78bcc90
        InstanceName: pvc-569e44c0-b352-4aca-bf14-2cf7a6cfe86f-e-0
    status:
    conditions:
    - lastProbeTime: ""
        lastTransitionTime: "2025-05-02T06:47:25Z"
        message: ""
        reason: running
        status: "True"
        type: InstanceExist
    - lastProbeTime: ""
        lastTransitionTime: "2025-05-02T06:47:25Z"
        message: ""
        reason: ""
        status: "False"
        type: Error
    ownerID: worker2
    ```

6. You can delete an `orphan` resource by running `kubectl -n longhorn-system delete orphan <name>`. The corresponding orphaned instance will also be removed.
    ```
    # kubectl -n longhorn-system delete orphan orphan-a91aa42ab5eda6b8b9fe1116d5b5f5673e5108d89be3db6fd18a275913463eef

    # kubectl -n longhorn-system get orphan -l "longhorn.io/orphan-type in (engine-instance,replica-instance)"
    NAME                                                                      TYPE               NODE
    orphan-1807009489e50534c35c350e22680449c97deca4e5d3b72f4591976145f8bc41   engine-instance    worker2
    ```

    The orphaned instance is deleted.
    ```
    # kubectl -n longhorn-system describe instancemanager -l "longhorn.io/node=worker1"
    Name:         instance-manager-8ff396d6d3744979b32abafc6346781c
    Namespace:    longhorn-system
    Kind:         InstanceManager
    ...
    Status:
      Instance Replicas:
    ...
    ```

7. By default, Longhorn does not automatically delete orphaned instances. You can enable automatic deletion by configuring the `orphan-resource-auto-deletion` setting.
    ```
    # kubectl -n longhorn-system edit settings.longhorn.io orphan-resource-auto-deletion
    ```
    Then, add `instance` to the list by including it as one of the semicolon-separated items.

    ```
    # kubectl -n longhorn-system get settings.longhorn.io orphan-resource-auto-deletion
    NAME                            VALUE     APPLIED   AGE
    orphan-resource-auto-deletion   nstance   true      45h
    ```

8. After enabling the automatic deletion and wait for a while, the `orphan` resources and processes are deleted automatically.
    ```
    # kubectl -n longhorn-system get orphans.longhorn.io -l "longhorn.io/orphan-type in (engine-instance,replica-instance)"
    No resources found in longhorn-system namespace.
    ```
    The orphaned instances are deleted from instance manager.
    ```
    # kubectl -n longhorn-system describe instancemanager -l "longhorn.io/node=worker1"
    Name:         instance-manager-8ff396d6d3744979b32abafc6346781c
    Namespace:    longhorn-system
    Kind:         InstanceManager
    ...
    Status:
      Instance Replicas:
    ...

    # kubectl -n longhorn-system describe instancemanager -l "longhorn.io/node=worker2"
    Name:         instance-manager-b87f10b867cec1dca2b814f5e78bcc90
    Namespace:    longhorn-system
    Kind:         InstanceManager
    ...
    Status:
      Instance Engines:
    ...

    ```

    Additionally, you can delete all orphaned instances on the specified node by running:
    ```
    # kubectl -n longhorn-system delete orphan -l "longhorn.io/orphan-type in (engine-instance,replica-instance),longhornnode=<node name>"
    ```

#### Manage Orphaned Instances via Longhorn UI

1. In the top navigation bar, go to `Settings > Orphan Resources > Instances`.
2. Review the list of orphaned instances, displaying relevant instance information.
3. To delete an orphaned instance, click `Operation > Delete`.

By default, Longhorn does not automatically delete orphaned instances. To enable automatic deletion, go to `Setting > General > Orphan`.

### Exception
Longhorn does not create an orphan resource in the following scenarios:

- The orphaned engine or replica is rescheduled back to the node.
- The engine or replica is in a migrating, starting, or stopping state.
- The node is evicted.
