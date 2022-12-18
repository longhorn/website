---
title: ReadWriteMany (RWX) Volume
weight: 4
---

Longhorn supports ReadWriteMany (RWX) volumes by exposing regular Longhorn volumes via NFSv4 servers that reside in share-manager pods.


# Introduction

For each actively in use RWX volume Longhorn will create a `share-manager-<volume-name>` Pod in the `longhorn-system` namespace. This Pod is responsible for exporting a Longhorn volume via a NFSv4 server that is running inside the Pod. There is also a service created for each RWX volume, and that is used as an endpoint for the actual NFSv4 client connection.

{{< figure src="/img/diagrams/rwx/rwx-arch.png" >}}

# Requirements

It is necessary to meet the following requirements in order to use RWX volumes.

1. Each NFS client node needs to have a NFSv4 client installed.

    The [environment check script](https://raw.githubusercontent.com/longhorn/longhorn/v{{< current-version >}}/scripts/environment_check.sh) helps users to check the installation of NFS client.
     - For Debian based distros you can install a NFSv4 client via:
        ```
        apt install nfs-common
        ```

     - For RPM based distros you can install a NFSv4 client via:
        ```
        yum install nfs-utils
        ```
    - For SUSE/OpenSUSE you can install a NFSv4 client via:
        ```
        zypper install nfs-client
        ```

      > **Troubleshooting:** If the NFSv4 client is not available on the node, when trying to mount the volume the below message will be part of the error:
      > ```
      > for several filesystems (e.g. nfs, cifs) you might need a /sbin/mount.<type> helper program.
      > ```

2. The hostname of each node is unique in the Kubernetes cluster.

    There is a dedicated recovery backend service for NFS servers in Longhorn system. When a client connects to an NFS server, the client's information, including its hostname, will be stored in the recovery backend. When a share-manager Pod or NFS server is abnormally terminated, Longhorn will create a new one. Within the 90-seconds grace period, clients will reclaim locks using the client information stored in the recovery backend.
    
    > **Tip:**: The [environment check script](https://raw.githubusercontent.com/longhorn/longhorn/v{{< current-version >}}/scripts/environment_check.sh) helps users to check all nodes have unique hostnames.

# Creation and Usage of a RWX Volume

1. For dynamically provisioned Longhorn volumes, the access mode is based on the PVC's access mode.
2. For manually created Longhorn volumes (restore, DR volume) the access mode can be specified during creation in the Longhorn UI.
3. When creating a PV/PVC for a Longhorn volume via the UI, the access mode of the PV/PVC will be based on the volume's access mode.
4. One can change the Longhorn volume's access mode via the UI as long as the volume is not bound to a PVC.
5. For a Longhorn volume that gets used by a RWX PVC, the volume access mode will be changed to RWX.

# Failure Handling

1. share-manager Pod is abnormally terminated

    Client IO will be blocked until Longhorn creates a new share-manager Pod and the associated volume. Once the Pod is successfully created, the 90-seconds grace period for lock reclamation is started, and users would expect
      - Before the grace period ends, client IO to the RWX volume will still be blocked.
      - The server rejects READ and WRITE operations and non-reclaim locking requests with an error of NFS4ERR_GRACE.
      - The grace period can be terminated early if all locks are successfully reclaimed.

    After exiting the grace period, IOs of the clients successfully reclaiming the locks continue without stale file handle errors or IO errors. If a lock cannot be reclaimed within the grace period, the lock is discarded, and the server returns IO error to the client. The client re-establishes a new lock. The application should handle the IO error. Nevertheless, not all applications can handle IO errors due to their implementation. Thus, it may result in the failure of the IO operation and the data loss. Data consistency may be an issue.

    Here is an example of a DaemonSet using a RWX volume.

    Each Pod of the DaemonSet is writing data to the RWX volume. If the node, where the share-manager Pod is running, is down, a new share-manager Pod is created on another node. Since one of the clients located on the down node has gone, the lock reclaim process cannot be terminated earlier than 90-second grace period, even though the remaining clients' locks have been successfully reclaimed. The IOs of these clients continue after the grace period has expired.

2. If the Kubernetes DNS service goes down, share-manager Pods will not be able to communicate with longhorn-nfs-recovery-backend

    The NFS-ganesha server in a share-manager Pod communicates with longhorn-nfs-recovery-backend via the service `longhorn-recovery-backend`'s IP. If the DNS service is out of service, the creation and deletion of RWX volumes as well as the recovery of NFS servers will be inoperable. Thus, the high availability of the DNS service is recommended for avoiding the communication failure.

# Migration from Previous External Provisioner

The below PVC creates a Kubernetes job that can copy data from one volume to another.

- Replace the `data-source-pvc` with the name of the previous NFSv4 RWX PVC that was created by Kubernetes.
- Replace the `data-target-pvc` with the name of the new RWX PVC that you wish to use for your new workloads.

You can manually create a new RWX Longhorn volume + PVC/PV, or just create a RWX PVC and then have Longhorn dynamically provision a volume for you.

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