---
title: Orphaned Data Cleanup
weight: 4
---

Longhorn supports orphaned data cleanup. Currently, Longhorn can identify and clean up the orphaned replica directories on disks.

## Orphaned Replica Directories

When a user introduces a disk into a Longhorn node, it may contain replica directories that are not tracked by the Longhorn system. The untracked replica directories may belong to other Longhorn clusters. Or, the replica CRs associated with the replica directories are removed after the node or the disk is down. When the node or the disk comes back, the corresponding replica data directories are no longer tracked by the Longhorn system. These replica data directories are called orphaned.

Longhorn supports the detection and cleanup of orphaned replica directories. It identifies the directories and gives a list of `orphan` resources that describe those directories. By default, Longhorn does not automatically delete `orphan` resources and their directories. Users can trigger the deletion of orphaned replica directories manually or have it done automatically.

### Example

In the example, we will explain how to manage orphaned replica directories identified by Longhorn via `kubectl` and Longhorn UI.

#### Manage Orphaned Replica Directories via kubectl

1. Introduce disks containing orphaned replica directories.
   - Orphaned replica directories on Node `worker1` disks
    ```
    # ls /mnt/disk/replicas/
    pvc-19c45b11-28ee-4802-bea4-c0cabfb3b94c-15a210ed
    ```
   - Orphaned replica directories on Node `worker2` disks
    ```
    # ls /var/lib/longhorn/replicas/
    pvc-28255b31-161f-5621-eea3-a1cbafb4a12a-866aa0a5

    # ls /mnt/disk/replicas/
    pvc-19c45b11-28ee-4802-bea4-c0cabfb3b94c-a86771c0
    ```
   
2. Longhorn detects the orphaned replica directories and creates an `orphan` resources describing the directories.
    ```
    # kubectl -n longhorn-system get orphans
    NAME                                                                      TYPE      NODE
    orphan-fed8c6c20965c7bdc3e3bbea5813fac52ccd6edcbf31e578f2d8bab93481c272   replica   rancher60-worker1
    orphan-637f6c01660277b5333f9f942e4b10071d89379dbe7b4164d071f4e1861a1247   replica   rancher60-worker2
    orphan-6360f22930d697c74bec4ce4056c05ac516017b908389bff53aca0657ebb3b4a   replica   rancher60-worker2
    ```
3. One can list the `orphan` resources created by Longhorn system by `kubectl -n longhorn-system get orphan`.
    ```
    kubectl -n longhorn-system get orphan
    ```

4. Get the detailed information of one of the orphaned replica directories in `spec.parameters` by `kubcel -n longhorn-system get orphan <name>`.
   ```
    # kubectl -n longhorn-system get orphans orphan-fed8c6c20965c7bdc3e3bbea5813fac52ccd6edcbf31e578f2d8bab93481c272 -o yaml
    apiVersion: longhorn.io/v1beta2
    kind: Orphan
    metadata:
    creationTimestamp: "2022-04-29T10:17:40Z"
    finalizers:
    - longhorn.io
    generation: 1
    labels:
        longhorn.io/component: orphan
        longhorn.io/managed-by: longhorn-manager
        longhorn.io/orphan-type: replica
        longhornnode: rancher60-worker1
    
    ......

    spec:
    nodeID: rancher60-worker1
    orphanType: replica
    parameters:
        DataName: pvc-19c45b11-28ee-4802-bea4-c0cabfb3b94c-15a210ed
        DiskName: disk-1
        DiskPath: /mnt/disk/
        DiskUUID: 90f00e61-d54e-44b9-a095-35c2b56a0462
    status:
    conditions:
    - lastProbeTime: ""
        lastTransitionTime: "2022-04-29T10:17:40Z"
        message: ""
        reason: ""
        status: "True"
        type: DataCleanable
    - lastProbeTime: ""
        lastTransitionTime: "2022-04-29T10:17:40Z"
        message: ""
        reason: ""
        status: "False"
        type: Error
    ownerID: rancher60-worker1
   ```

5. One can delete the `orphan` resource by `kubectl -n longhorn-system delete orphan <name>` and then the corresponding orphaned replica directory will be deleted.
   ```
    # kubectl -n longhorn-system delete orphan orphan-fed8c6c20965c7bdc3e3bbea5813fac52ccd6edcbf31e578f2d8bab93481c272

    # kubectl -n longhorn-system get orphans
    NAME                                                                      TYPE      NODE
    orphan-637f6c01660277b5333f9f942e4b10071d89379dbe7b4164d071f4e1861a1247   replica   rancher60-worker2
    orphan-6360f22930d697c74bec4ce4056c05ac516017b908389bff53aca0657ebb3b4a   replica   rancher60-worker2
   ```

    The orphaned replica directory is deleted.
    ```
    # ls /mnt/disk/replicas/

    ```

6. By default, Longhorn will not automatically delete the orphaned replica directory. One can enable the automatic deletion by setting `orphan-auto-deletion` to `true`.
    ```
    # kubectl -n longhorn-system edit settings.longhorn.io orphan-auto-deletion
    ```
    Then, set the value to `true`.

    ```
    # kubectl -n longhorn-system get settings.longhorn.io orphan-auto-deletion
    NAME                   VALUE   AGE
    orphan-auto-deletion   true    26m
    ```

7. After enabling the automatic deletion and wait for a while, the `orphan` resources and directories are deleted automatically.
   ```
    # kubectl -n longhorn-system get orphans.longhorn.io
    No resources found in longhorn-system namespace.
   ```
   The orphaned replica directories are deleted.
   ```
    # ls /mnt/disk/replicas/

    # ls /var/lib/longhorn/replicas/

   ```

    Additionally, one can delete all orphaned replica directories on the specified node by
    ```
    # kubectl -n longhorn-system delete orphan -l "longhornnode=<node name>”
    ```

#### Manage Orphaned Replica Directories via Longhorn UI

In the top navigation bar of the Longhorn UI, click `Setting > Orphaned Data`. Orphaned replica directories on each node and in each disk are listed. One can delete the directories by `Operation > Delete`.

By default, Longhorn will not automatically delete the orphaned replica directory. One can enable the automatic deletion in `Setting > General > Orphan`.

### Exception
Longhorn will not create an `orphan` resource for an orphaned directory when
- The orphaned directory is not an **orphaned replica directory**.
  - The directory name does not follow the replica directory's naming convention.
  - The volume volume.meta file is missing.
- The orphaned replica directory is on an evicted node.
- The orphaned replica directory is in an evicted disk.
- The orphaned data cleanup mechanism does not clean up a stale replica, also known as an error replica. Instead, the stale replica is cleaned up according to the [staleReplicaTimeout](../../../nodes-and-volumes/volumes/create-volumes/#creating-longhorn-volumes-with-kubectl) setting.
