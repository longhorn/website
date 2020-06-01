---
title: Upgrading Longhorn Manager
weight: 1
---

- [Upgrading from v0.8.1 to v1.0.0](#upgrading-from-v081-to-v100)
- [Upgrading from v0.7.0+](#upgrading-from-v070)

### Upgrading from v0.8.1 to v1.0.0

We only support upgrading to v1.0.0 from v0.8.1. For other versions, please upgrade to v0.8.1 first.

We only support offline upgrades from v0.8.1 to v1.0.0 due to an Instance Manager change.

#### Preparing for the Upgrade

1. If Longhorn was installed using a Helm Chart, or if it was installed as Rancher catalog app, check to make sure the parameters in the default StorageClass weren't changed. Changing the default StorageClass's parameter might result in a chart upgrade failure. if you want to reconfigure the parameters in the StorageClass, you can copy the default StorageClass's configuration to create another StorageClass.

    The current default StorageClass has the following parameters:

        parameters:
          numberOfReplicas: <user specified replica count, 3 by default>
          staleReplicaTimeout: "30"
          fromBackup: ""
          baseImage: ""

1. Shut down your workloads following the instructions [here.](../../../volumes-and-nodes/detaching-volumes/)
1. If you still have any volumes using the pre-v0.7.0 CSI driver name io.rancher.longhorn, follow the instructions [here](https://longhorn.io/docs/0.8.1/deploy/upgrade/longhorn-manager/#migrate-pvs-and-pvcs-for-the-volumes-launched-in-v062-or-older) to convert your old PVs.

#### Upgrade

1. Perform the manager upgrade according to [these instructions.](#upgrading-from-v070)
1. Perform the engine upgrade according to the [offline engine upgrade instructions,](../upgrade-engine/#offline-upgrades) but don't scale back the workload just yet.
1. We recommend updating the Guaranteed Engine CPU to 0.25. This step will restart all the Instance Managers on the node, so any attached volumes will be detached.
    
    > Please make sure you have at least 2 vCPUs per node before updating this setting to 0.25. See the [settings reference](../../../references/settings/#guaranteed-engine-cpu) for details.
1. Scale back the workload. Check if everything works well.
1. We also recommend updating the **Replica Node Soft Anti-affinity** setting to false. Refer to the [settings reference](../../../references/settings/#replica-node-level-soft-anti-affinity) for details.
    
    > Please make sure you have more nodes than the default replica count before updating this setting.

#### Cleanup for Compatible CSI Plugin

Due to removing the compatible CSI deployment, without removing the compatible plugin registry socket, the following error message will be in the kubelet logs:

```
clientconn.go:1120] grpc: addrConn.createTransport failed to connect to {/var/lib/kubelet/plugins/io.rancher.longhorn-reg.sock 0  <nil>}. Err :connection error: desc = "transport: Error while dialing dial unix /var/lib/kubelet/plugins/io.rancher.longhorn-reg.sock: connect: connection refused". Reconnecting...
```

It can be fixed by removing the `io.rancher.longhorn-reg.sock` from the kubelet on the node with the following command:

> **Note**: Please make sure there is no PV running with driver `io.rancher.longhorn`.

```
rm /var/lib/kubelet/plugins_registry/io.rancher.longhorn-reg.sock
```

Meanwhile the kubelet will log the following message:

```
plugin_watcher.go:212] Removing socket path /var/lib/kubelet/plugins_registry/io.rancher.longhorn-reg.sock from desired state cache
```

### Upgrading from v0.7.0+

> **Prerequisite:** Always back up volumes before upgrading. If anything goes wrong, you can restore the volume using the backup.

To upgrade with kubectl, run this command:

```
kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/master/deploy/longhorn.yaml
```

To upgrade with Helm, run this command:

```
helm upgrade longhorn ./longhorn/chart
```

On Kubernetes clusters managed by Rancher 2.1 or newer, the steps to upgrade the catalog app `longhorn-system` are the similar to the installation steps. 

Then wait for all the pods to become running and Longhorn UI working. e.g.:

```
$ kubectl -n longhorn-system get pod
NAME                                        READY   STATUS    RESTARTS   AGE
csi-attacher-78bf9b9898-mb7jt               1/1     Running   1          3m11s
csi-attacher-78bf9b9898-n2224               1/1     Running   1          3m11s
csi-attacher-78bf9b9898-rhv6m               1/1     Running   1          3m11s
csi-provisioner-8599d5bf97-dr5n4            1/1     Running   1          2m58s
csi-provisioner-8599d5bf97-drzn9            1/1     Running   1          2m58s
csi-provisioner-8599d5bf97-rz5fj            1/1     Running   1          2m58s
csi-resizer-586665f745-5bkcm                1/1     Running   0          2m49s
csi-resizer-586665f745-vgqx8                1/1     Running   0          2m49s
csi-resizer-586665f745-wdvdg                1/1     Running   0          2m49s
engine-image-ei-62c02f63-bjfkp              1/1     Running   0          14m
engine-image-ei-62c02f63-nk2jr              1/1     Running   0          14m
engine-image-ei-62c02f63-pjtgg              1/1     Running   0          14m
engine-image-ei-ac045a0d-9bbb8              1/1     Running   0          3m46s
engine-image-ei-ac045a0d-cqvv2              1/1     Running   0          3m46s
engine-image-ei-ac045a0d-wzmhv              1/1     Running   0          3m46s
instance-manager-e-4deb2a16                 1/1     Running   0          3m23s
instance-manager-e-5526b121                 1/1     Running   0          3m28s
instance-manager-e-eff765b6                 1/1     Running   0          2m59s
instance-manager-r-3b70b0db                 1/1     Running   0          3m27s
instance-manager-r-4f7d629a                 1/1     Running   0          3m22s
instance-manager-r-bbcf4f17                 1/1     Running   0          2m58s
longhorn-csi-plugin-bkgjj                   2/2     Running   0          2m39s
longhorn-csi-plugin-tjhhq                   2/2     Running   0          2m39s
longhorn-csi-plugin-zslp6                   2/2     Running   0          2m39s
longhorn-driver-deployer-75b6bf4d6d-d4hcv   1/1     Running   0          3m57s
longhorn-manager-4j77v                      1/1     Running   0          3m53s
longhorn-manager-cwm5z                      1/1     Running   0          3m50s
longhorn-manager-w7scb                      1/1     Running   0          3m50s
longhorn-ui-8fcd9fdd-qpknp                  1/1     Running   0          3m56s
```

Next, [upgrade Longhorn engine.](../upgrade-engine)

### TroubleShooting
#### Error: `"longhorn" is invalid: provisioner: Forbidden: updates to provisioner are forbidden.`
- This means there are some modifications applied to the default storageClass and you need to clean up the old one before upgrade.

- To clean up the deprecated StorageClass, run this command:
    ```
    kubectl delete -f https://raw.githubusercontent.com/longhorn/longhorn/v1.0.0/examples/storageclass.yaml
    ```

