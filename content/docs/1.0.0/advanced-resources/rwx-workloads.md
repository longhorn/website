---
title: RWX workloads
weight: 4
---

# Longhorn RWX support

{{< figure src="/img/diagrams/rwx/rwx-01.png" >}}

Longhorn supports RWX workloads via the **nfs.longhorn.io** provisioner.
To enable RWX support you need to deploy the following files:
- [01-security.yaml](https://github.com/longhorn/longhorn/examples/rwx/01-security.yaml)
- [02-longhorn-nfs-provisioner.yaml](https://github.com/longhorn/longhorn/examples/rwx/02-longhorn-nfs-provisioner.yaml)
- [03-rwx-test.yaml](https://github.com/longhorn/longhorn/examples/rwx/03-rwx-test.yaml)

The `03-rwx-test.yaml` example deployment has 4 pods that share a rwx volume via nfs mounted at `/mnt/nfs-test`,
every second the pods append the current date time to a shared log file under `/mnt/nfs-test/test.log`

In the default configuration we provision a **20Gb** longhorn volume as a backing volume for the rwx workload.
We suggest you set that to your required capacity before deploying `02-longhorn-nfs-provisioner.yaml`
the requested size should be roughly 10% bigger then the required RWX workload size.

It's important to note that one can only run a single nfs-provisioner instance per StorageClass.
It would be incorrect to increase the replica count for the nfs-provisioner,
instead read below to see how to deploy additional nfs-provisioners.
It's possible to provision multiple rwx volumes from a single nfs-provisioner but the workloads,
would share the underlying longhorn backing storage.

# Multiple RWX workloads

{{< figure src="/img/diagrams/rwx/rwx-02.png" >}}

If you want to run multiple RWX volumes consider creating different nfs-provisioner deployments
you can modify the provisioner argument and create a new storage class for that provisioner see `02-longhorn-nfs-provisioner.yaml`.
You could call the new provisioner `nfs.longhorn.io/2` and the StorageClass `longhorn-nfs2`
afterwards create a new service `longhorn-nfs-provisioner2` with a random unique cluster-ip and update the
`SERVICE_NAME` environment variable to point to your new service.
The different provisioners can share the same security setup from `01-security.yaml`

# Failure handling

#### Service cluster ip
For the `longhorn-nfs-provisioner` service we hard code the service ip to **10.43.111.111**
if this ip is not available on your cluster (inuse, outside of network range) you can choose any other random unique ip.
We recommend to hardcode a random unique cluster ip since the pvc's will end up with this hardcoded service ip after creation.

#### Node failure
In the case of a node failure a replacement `longhorn-nfs-provisioner` pod should be available after roughly 90s.
We use the following tolerations to decide when to evict the nfs-provisioner pod, you can lower the `tolerationSeconds`
to lower the nfs-provisioner failover time in the case of a node failure.
We recommend setting up a liveness probe on your rwx workloads,
the failing liveness probe will lead to a pod restart that will make the RWX volume available again,
once the replacement nfs-provisioner is up and running.
```
  terminationGracePeriodSeconds: 30
  tolerations:
    - effect: NoExecute
      key: node.kubernetes.io/not-ready
      operator: Exists
      tolerationSeconds: 60
    - effect: NoExecute
      key: node.kubernetes.io/unreachable
      operator: Exists
      tolerationSeconds: 60
```

#### Workload health check
We recommend the setup of a liveness check on the workloads that makes sure the pods get restarted on nfs server failures.
Example liveness probe: `timeout 10 ls /mnt/nfs-mountpoint`.
We need to include the timeout command as part of the liveness check
to work around this kubernetes [issue](https://github.com/kubernetes/kubernetes/issues/26895).

