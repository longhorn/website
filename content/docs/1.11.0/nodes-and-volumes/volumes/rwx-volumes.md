---
title: ReadWriteMany (RWX) Volume
weight: 4
---

Longhorn supports ReadWriteMany (RWX) volumes by exposing regular Longhorn volumes via NFSv4 servers that reside in share-manager pods.


# Introduction

Longhorn supports two types of ReadWriteMany (RWX) volumes:

1. **Standard (Non-Migratable) RWX Volumes**: Traditional shared storage using NFSv4.1 servers in dedicated `share-manager-<volume-name>` Pods within the `longhorn-system` namespace. These volumes provide shared access across multiple nodes but cannot be live migrated. Standard RWX volumes create a corresponding Service for each RWX volume, serving as the designated endpoint for NFSv4.1 client connections.

2. **Migratable RWX Volumes**: RWX volumes that support live migration between nodes while maintaining active I/O operations. These are designed for virtualized workloads such as KubeVirt VMs that require live migration capabilities. Migratable RWX volumes use direct block device access during migration.

You can distinguish between migratable and non-migratable RWX volumes by checking the `volume.spec.migratable` field in the volume specification.

{{< figure src="/img/diagrams/rwx/rwx-arch.png" >}}

# Requirements

## Standard RWX Volumes

1. Each NFS client node needs to have a NFSv4 client installed.

    Please refer to [Installing NFSv4 client](../../../deploy/install/#installing-nfsv4-client) for more installation details.

      > **Troubleshooting:** If the NFSv4 client is not available on the node, when trying to mount the volume the below message will be part of the error:
      > ```
      > for several filesystems (e.g. nfs, cifs) you might need a /sbin/mount.<type> helper program.
      > ```

2. The hostname of each node is unique in the Kubernetes cluster.

    There is a dedicated recovery backend service for NFS servers in Longhorn system. When a client connects to an NFS server, the client's information, including its hostname, will be stored in the recovery backend. When a share-manager Pod or NFS server is abnormally terminated, Longhorn will create a new one. Within the 90-seconds grace period, clients will reclaim locks using the client information stored in the recovery backend.

## Migratable RWX Volumes

1. The cluster must support CSI volume attachment/detachment operations for multi-attach scenarios.

2. A live migration platform like KubeVirt is typically used to coordinate the migration process.

3. Each node hostname must be unique in the Kubernetes cluster for proper volume management during migration processes.

# Creation and Usage of an RWX Volume

Longhorn supports two types of RWX volumes:

## Standard (Non-Migratable) RWX Volumes

**Standard RWX volumes** use NFSv4 servers in share-manager pods and are suitable for most workloads that need shared storage across multiple nodes.

> **Notice**  
> Standard RWX volumes must have the access mode set to `ReadWriteMany` and the "migratable" flag disabled (*parameters.migratable: `false`*).

**Use Cases:**
- Traditional shared storage scenarios
- Applications requiring concurrent read/write access from multiple nodes
- Workloads that do not require live migration capabilities

**Configuration Example:**
```yaml
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: longhorn-rwx-standard
provisioner: driver.longhorn.io
allowVolumeExpansion: true
reclaimPolicy: Delete
volumeBindingMode: Immediate
parameters:
  numberOfReplicas: "3"
  staleReplicaTimeout: "2880"
  migratable: "false"  # Explicitly disabled for standard RWX
```

## Migratable RWX Volumes

**Migratable RWX volumes** are designed for workloads that need live migration capabilities, such as virtual machines managed by tools like KubeVirt. This feature allows a volume to move seamlessly from one node to another without interrupting the application.

> **Notice**  
> For migratable RWX volumes to work correctly, they must be configured with:
>   - Access Mode: `ReadWriteMany`
>   - Parameters: `migratable: true`
>   - Volume Mode: `volumeMode: Block`
> This specific combination is essential for the underlying block-level synchronization required for live migration.

**Use Cases:**
- Virtual machines that require live migration for high availability or maintenance
-  Workloads that benefit from dynamic load balancing by moving between nodes

**Key Features:**
- Supports live migration between nodes
- Uses block device mode (`volumeMode: Block`)
- Manages dual engine instances during migration
- Automatic migration confirmation or rollback based on pod lifecycle

**How Migration Works:**
1. **Migration Start**: When Kubernetes requests attachment of an already-attached migratable volume to a new node, Longhorn creates a second engine on the destination node with matching replicas
2. **Dual Engine State**: Both engines run simultaneously, with the volume accessible from both nodes during the migration period
3. **Migration Completion**: Based on which pod is terminated:
   - If the original pod is terminated → migration completes, volume moves to the new node
   - If the new pod is terminated → migration rolls back, volume remains on the original node
4. **Cleanup**: Longhorn automatically cleans up the unused engine and adjusts replica states

**Configuration Example:**
```yaml
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: longhorn-rwx-migratable
provisioner: driver.longhorn.io
allowVolumeExpansion: true
reclaimPolicy: Delete
volumeBindingMode: Immediate
parameters:
  numberOfReplicas: "3"
  staleReplicaTimeout: "2880"
  migratable: "true"   # Required for live migration support
```

**PVC Example for Migratable RWX:**
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: migratable-rwx-pvc
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: longhorn-rwx-migratable
  volumeMode: Block  # Required for migratable RWX volumes
  resources:
    requests:
      storage: 10Gi
```

## General RWX Volume Creation Steps

1. For dynamically provisioned Longhorn volumes, the access mode is based on the PVC's access mode.
2. For manually created Longhorn volumes (restore, DR volume) the access mode can be specified during creation in the Longhorn UI.
3. When creating a PV/PVC for a Longhorn volume via the UI, the access mode of the PV/PVC will be based on the volume's access mode.
4. One can change the Longhorn volume's access mode via the UI as long as the volume is not bound to a PVC.
5. For a Longhorn volume that gets used by an RWX PVC, the volume access mode will be changed to RWX.

## Important Considerations

### Standard RWX Volumes
- Cannot be live migrated and should be used for traditional shared storage needs
- Use NFSv4 protocol for file system access
- Support all standard NFS features and mount options
- Suitable for applications requiring concurrent file system access

### Migratable RWX Volumes  
- Specifically designed for live migration scenarios
- **Must** use `volumeMode: Block` - file system mode is not supported
- Require `ReadWriteMany` access mode and `migratable: true` parameter
- Not suitable for general shared file system use cases

## Configuring Volume Locality for RWX Volumes

Longhorn provides new settings that allow you to precisely control the data locality of RWX volumes (through identification of associated Share Manager pods). These granular settings work with related global settings to provide optimal performance, resilience, and adherence to organizational policies or constraints.

### `shareManagerNodeSelector`

You can use the StorageClass parameter `shareManagerNodeSelector` to specify selectors for identifying nodes that RWX volumes can be scheduled on. These selectors are merged with global `system-managed-components-node-selector` settings and then applied to the Share Manager pods of the RWX volumes to provide more control over volume locality.

  Example:
  ```
  kind: StorageClass
  apiVersion: storage.k8s.io/v1
  metadata:
    name: longhorn-rwx
  provisioner: driver.longhorn.io
  parameters:
    shareManagerNodeSelector: label-key1:label-value1;label-key2:label-value2
  ```
  In this example, RWX volumes provisioned with the specified StorageClass will be scheduled on nodes with the labels `label-key1:label-value1` and `label-key2:label-value2`. 

### `allowedTopologies`

Longhorn converts the `storageClass.allowedTopologies` settings into affinity rules for the Share Manager pods of the RWX volumes. This ensures that the pods are scheduled on nodes that meet the specified topological requirements (such as regions and zones) and align with the RWX volume locality.

  Example:
  ```
  kind: StorageClass
  apiVersion: storage.k8s.io/v1
  metadata:
    name: longhorn-rwx
  provisioner: driver.longhorn.io
  allowedTopologies:
  - matchLabelExpressions:
    - key: topology.kubernetes.io/region
      values:
      - us-west-1
  ```
  In this example, the Share Manager pods and RWX volumes will be scheduled in the `us-west-1` region.

### `shareManagerTolerations`

You can also use the StorageClass parameter `shareManagerTolerations` to allow more flexible scheduling based on node taints. The defined tolerations are merged with global `taint-toleration` settings and then applied to the Share Manager pods.

  Example:
  ```
  kind: StorageClass
  apiVersion: storage.k8s.io/v1
  metadata:
    name: longhorn-rwx
  provisioner: driver.longhorn.io
  parameters:
    shareManagerTolerations: nodetype=storage:NoSchedule
  ```
  In this example, the Share Manager pods will tolerate the `nodetype=storage:NoSchedule` taint on nodes, allowing them to be scheduled on those nodes.

## Configuring Volume Mount Options

An RWX volume is accessible only when mounted via NFS. By default Longhorn uses NFS version 4.1 with the `softerr` mount option, a `timeo` value of "600", and a `retrans` value of "5".

If the NFS server becomes inaccessible, requests from NFS clients are retried according to the configured `retrans` value. Longer-duration events such as power outages and factors such as network partitions cause the requests to eventually fail. An NFS error (`ETIMEDOUT` for the `softerr` mount option) is returned to the calling application and data loss may occur. If `softerr` is not supported, Longhorn automatically uses the `soft` mount option instead, which returns an `EIO` as the error.

You can use specific mount options for new volumes. First, create a customized StorageClass with an `nfsOptions` parameter, and then create PVCs for RWX volumes using that specific StorageClass.

Example:

  ```yaml
  kind: StorageClass
  apiVersion: storage.k8s.io/v1
  metadata:
    name: longhorn-test
  provisioner: driver.longhorn.io
  allowVolumeExpansion: true
  reclaimPolicy: Delete
  volumeBindingMode: Immediate
  parameters:
    numberOfReplicas: "3"
    staleReplicaTimeout: "2880"
    fromBackup: ""
    fsType: "ext4"
    nfsOptions: "vers=4.2,noresvport,softerr,timeo=600,retrans=5"
  ```

> **Important:**
> To create PVCs for RWX volumes using the sample StorageClass, replace the `nfsOptions` string with a customized comma-separated list of legal options.

### Notes

1. You must provide the complete set of desired options. Any options not supplied will use the NFS-server side defaults, not Longhorn's own.

2. Longhorn does not validate the `nfsOptions` string, so erroneous values and typographical errors are not flagged. When the string is invalid, the mount is rejected by the NFS server and the volume is not created nor attached.

3. In Longhorn v1.4.0 to 1.4.3 and v1.5.0 to v1.5.1, volumes within a share manager pod (specifically, in the `NodeStageVolume` step) are hard mounted by default by the Longhorn CSI plugin. Hard mounting allows Longhorn to persistently retry sending NFS requests, ensuring that IOs do not fail even when the NFS server becomes inaccessible for some time. IOs resume seamlessly when the server regains connectivity or a replacement server is created.

   This mechanism for guaranteeing data integrity, however, comes with some risk. To maintain stability, the Linux kernel does not allow unmounting of a file system until all pending IOs are completed. This is a concern because the system cannot shut down until all file systems are unmounted. If the NFS server is unable to recover, the client nodes must undergo a forced reboot.

   To mitigate the issue, upgrade to v1.4.4, v1.5.2, or a later version. After upgrading, either `softerr` or `soft` is automatically applied to the `nfsOptions` parameter whenever RWX volumes are reattached (if the default settings are not overridden).

4. You can still use the `hard` mount option (via the `nfsOptions` override mechanism), but hard-mounted volumes are subject to the outlined risks.

For more information, see [#6655](https://github.com/longhorn/longhorn/issues/6655).

# Failure Handling

1. share-manager Pod is abnormally terminated

    Client IO will be blocked until Longhorn creates a new share-manager Pod and the associated volume. Once the Pod is successfully created, the 90-seconds grace period for lock reclamation is started, and users would expect
      - Before the grace period ends, client IO to the RWX volume will still be blocked.
      - The server rejects READ and WRITE operations and non-reclaim locking requests with an error of NFS4ERR_GRACE.
      - The grace period can be terminated early if all locks are successfully reclaimed.

    After exiting the grace period, IOs of the clients successfully reclaiming the locks continue without stale file handle errors or IO errors. If a lock cannot be reclaimed within the grace period, the lock is discarded, and the server returns IO error to the client. The client re-establishes a new lock. The application should handle the IO error. Nevertheless, not all applications can handle IO errors due to their implementation. Thus, it may result in the failure of the IO operation and the data loss. Data consistency may be an issue.

    Here is an example of a DaemonSet using an RWX volume.

    Each Pod of the DaemonSet is writing data to the RWX volume. If the node where the share-manager Pod is running is down, a new share-manager Pod is created on another node. Since one of the clients located on the down node has gone, the lock reclaim process cannot be terminated earlier than the 90-second grace period, even though the remaining clients' locks have been successfully reclaimed. The IOs of these clients continue after the grace period has expired.

2. If the Kubernetes DNS service goes down, share-manager Pods will not be able to communicate with longhorn-nfs-recovery-backend

    The NFS-ganesha server in a share-manager Pod communicates with longhorn-nfs-recovery-backend via the service `longhorn-recovery-backend`'s IP. If the DNS service is out of service, the creation and deletion of RWX volumes as well as the recovery of NFS servers will be inoperable. Thus, the high availability of the DNS service is recommended for avoiding the communication failure.

3. Fast failover feature.

    Longhorn supports a feature that can improve availability by shortening the time it takes to recover from a failure of the node on which the volume's share-manager NFS server pod is running.  The feature uses a direct heartbeat to monitor the server. If the server is unresponsive it acts to create a new one faster than the usual sequence. It also configures the NFS server differently, to shorten the recovery grace period from 90 to 30 seconds.  
    More details are at [RWX Volume Fast Failover](../../../high-availability/rwx-volume-fast-failover).


# Migration from Previous External Provisioner

The below PVC creates a Kubernetes job that can copy data from one volume to another.

- Replace the `data-source-pvc` with the name of the previous NFSv4 RWX PVC that was created by Kubernetes.
- Replace the `data-target-pvc` with the name of the new RWX PVC that you wish to use for your new workloads.

You can manually create a new RWX Longhorn volume + PVC/PV, or just create an RWX PVC and then have Longhorn dynamically provision a volume for you.

Both PVCs need to exist in the same namespace. If you were using a different namespace than the default, change the job's namespace below.

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  namespace: default  # namespace where the PVC's exist
  name: volume-migration
spec:
  completions: 1
  parallelism: 1
  backoffLimit: 3
  template:
    metadata:
      name: volume-migration
      labels:
        name: volume-migration
    spec:
      restartPolicy: Never
      containers:
        - name: volume-migration
          image: ubuntu:xenial
          tty: true
          command: [ "/bin/sh" ]
          args: [ "-c", "cp -r -v /mnt/old /mnt/new" ]
          volumeMounts:
            - name: old-vol
              mountPath: /mnt/old
            - name: new-vol
              mountPath: /mnt/new
      volumes:
        - name: old-vol
          persistentVolumeClaim:
            claimName: data-source-pvc # change to data source PVC
        - name: new-vol
          persistentVolumeClaim:
            claimName: data-target-pvc # change to data target PVC
```


# History
* Available since v1.0.1 [External provisioner](https://github.com/Longhorn/Longhorn/issues/1183)
* Available since v1.1.0 [Native RWX support](https://github.com/Longhorn/Longhorn/issues/1470)
