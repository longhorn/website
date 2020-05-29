---
title: Upgrading Longhorn Manager
weight: 1
---

- [Upgrading from v0.8.1 to v1.0.0](#upgrading-from-v081-to-v100)
- [Upgrading from v0.7.0+](#upgrading-from-v070)
- [Upgrading from v0.6.2 or older version to v0.8.1](#upgrading-from-v062-or-older-version-to-v081)
- [Upgrading from v0.6.2 to v0.7.0](#upgrading-from-v062-to-v070)

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
1. If you still have any volumes using the pre-v0.7.0 CSI driver name io.rancher.longhorn, follow the instructions [here](#migrate-pvs-and-pvcs-for-the-volumes-launched-in-v062-or-older) to convert your old PVs.

#### Upgrade

1. Perform the manager upgrade according to [these instructions.](#upgrading-from-v070)
1. Perform the engine upgrade according to the [offline engine upgrade instructions,](../upgrade-engine/#offline-upgrades) but don't scale back the workload just yet.
1. We recommend updating the Guaranteed Engine CPU to 0.25. This step will restart all the Instance Managers on the node, so any attached volumes will be detached.
    
    > Please make sure you have at least 2 vCPUs per node before updating this setting to 0.25. See the [settings reference](../../../references/settings/#guaranteed-engine-cpu-experimental) for details.
1. Scale back the workload. Check if everything works well.
1. We also recommend updating the **Replica Node Soft Anti-affinity** setting to false. Refer to the [settings reference](../../../references/settings/#replica-node-level-soft-anti-affinity) for details. 
    
    > Please make sure you have more nodes than the default replica count before updating this setting.


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

On Kubernetes clusters managed by Rancher 2.1 or newer, the steps to upgrade Longhorn manager are the same as the installation steps. 

Next, [upgrade Longhorn engine.](../upgrade-engine)

### Upgrading from v0.6.2 or older version to v0.8.1

#### Migrate PVs and PVCs for the Volumes Launched in v0.6.2 or Older

If a volume is launched and used in Longhorn v0.6.2 or older, the related persistent volumes (PVs) and persistent volume claims (PVCs) are still managed by the old CSI plugin, which will be deprecated in a later Longhorn version.

Therefore, the PVCs and PVs should be migrated to use the new CSI plugin for the volume in Longhorn v0.8.1.

##### Prerequisites

- Longhorn is already upgraded to v0.8.1.
- The related PVs and PVCs were created in v0.6.2 or older.
- Each volume is detached and the workloads are down.

##### Migration Steps

1. If you don't know when the volumes were created, find out which volumes need to be migrated by running the following command:

    ```
    kubectl get pv --output=jsonpath="{.items[?(@.spec.csi.driver==\"io.rancher.longhorn\")].spec.csi.volumeHandle}"
    ```

2. Shut down the related workloads and detach the volumes. 
3. Run this script for each volume:

    ```
    curl -s https://raw.githubusercontent.com/longhorn/longhorn/v0.8.1/scripts/migrate-for-pre-070-volumes.sh |bash -s -- <volume name>
    ```

    Or run the script for all volumes:
    ```
    curl -s https://raw.githubusercontent.com/longhorn/longhorn/v0.8.1/scripts/migrate-for-pre-070-volumes.sh |bash -s -- --all
    ```
**Result:** The volumes have been migrated to use the new CSI driver.

##### Migration Failure handling

If the prerequisite of the migration is not satisfied and there is no error log `failed to delete then recreate PV/PVC, users need to manually check the current PVC/PV then recreate them if needed`, the script will do nothing for the PV and PVC. Users can check the migration prerequisites and steps and retry it. 

If the migration fails and the error log mentioned above is printed out, users need to manually handle the migration for the failed volume:

1. Update `spec.persistentVolumeReclaimPolicy` to `Retain` for the PV with this command:

   ```
   kubectl edit pv <The PV name>
   ```

2. Delete the PVC and PV with this command:

    ```
    kubectl delete pvc <The PVC name> && kubectl delete pv <The PV name>
    ```

3. Use the Longhorn UI to recreate the PV and PVC.

### Upgrading from v0.6.2 to v0.7.0

You will need to follow this guide to upgrade the Longhorn manager from v0.6.2 to v0.7.0.

Live upgrades are not supported from v0.6.2 to v0.7.0.

- [Prerequisites](#prerequisites)
- [Upgrade Longhorn Manager](#upgrade-longhorn-manager)
  - [Using the Rancher Catalog App](#using-the-rancher-catalog-app)
  - [Using kubectl](#using-kubectl)
- [Troubleshooting](#troubleshooting)
- [Clean up the v0.6.2 CRDs](#clean-up-the-v062-crds)
- [Rollbacks](#rollbacks)

### Prerequisites

- Make sure Kubernetes version is v1.14.0+.
- Make backups for all the volumes.
- Stop the workloads from using the volumes.

### Upgrade Longhorn Manager
The Longhorn manager can be upgraded with kubectl or with the Rancher catalog app.
#### Using the Rancher Catalog App
1. Run the following command to avoid [this 'updates to provisioner are forbidden' error](#error-longhorn-is-invalid-provisioner-forbidden-updates-to-provisioner-are-forbidden):
    ```
    kubectl delete -f https://raw.githubusercontent.com/longhorn/longhorn/v0.7.0/examples/storageclass.yaml
    ```
2. Click the `Upgrade` button in the Rancher UI
3. Wait for the app to complete the upgrade.

Next, [upgrade Longhorn engine.](../upgrade-engine)

#### Using kubectl
Use `kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/v0.7.0/deploy/longhorn.yaml`

And wait for all the pods to become running and Longhorn UI working.

```
$ kubectl -n longhorn-system get pod
NAME                                        READY   STATUS    RESTARTS   AGE
compatible-csi-attacher-69857469fd-rj5vm    1/1     Running   4          3d12h
csi-attacher-79b9bfc665-56sdb               1/1     Running   0          3d12h
csi-attacher-79b9bfc665-hdj7t               1/1     Running   0          3d12h
csi-attacher-79b9bfc665-tfggq               1/1     Running   3          3d12h
csi-provisioner-68b7d975bb-5ggp8            1/1     Running   0          3d12h
csi-provisioner-68b7d975bb-frggd            1/1     Running   2          3d12h
csi-provisioner-68b7d975bb-zrr65            1/1     Running   0          3d12h
engine-image-ei-605a0f3e-8gx4s              1/1     Running   0          3d14h
engine-image-ei-605a0f3e-97gxx              1/1     Running   0          3d14h
engine-image-ei-605a0f3e-r6wm4              1/1     Running   0          3d14h
instance-manager-e-a90b0bab                 1/1     Running   0          3d14h
instance-manager-e-d1458894                 1/1     Running   0          3d14h
instance-manager-e-f2caa5e5                 1/1     Running   0          3d14h
instance-manager-r-04417b70                 1/1     Running   0          3d14h
instance-manager-r-36d9928a                 1/1     Running   0          3d14h
instance-manager-r-f25172b1                 1/1     Running   0          3d14h
longhorn-csi-plugin-72bsp                   4/4     Running   0          3d12h
longhorn-csi-plugin-hlbg8                   4/4     Running   0          3d12h
longhorn-csi-plugin-zrvhl                   4/4     Running   0          3d12h
longhorn-driver-deployer-66b6d8b97c-snjrn   1/1     Running   0          3d12h
longhorn-manager-pf5p5                      1/1     Running   0          3d14h
longhorn-manager-r5npp                      1/1     Running   1          3d14h
longhorn-manager-t59kt                      1/1     Running   0          3d14h
longhorn-ui-b466b6d74-w7wzf                 1/1     Running   0          50m
```

Next, [upgrade Longhorn engine.](../upgrade-engine)

### TroubleShooting
#### Error: `"longhorn" is invalid: provisioner: Forbidden: updates to provisioner are forbidden.`
- This means you need to clean up the old `longhorn` storageClass for Longhorn v0.7.0 upgrade, since we've changed the provisioner from `rancher.io/longhorn` to `driver.longhorn.io`.

- Noticed the PVs created by the old storageClass will still use `rancher.io/longhorn` as provisioner. Longhorn v0.7.0 supports attach/detach/deleting of the PVs created by the previous version of Longhorn, but it doesn't support creating new PVs using the old provisioner name. Please use the new StorageClass for the new volumes.

If you are using YAML file:
1. Clean up the deprecated StorageClass:
    ```
    kubectl delete -f https://raw.githubusercontent.com/longhorn/longhorn/v0.7.0/examples/storageclass.yaml
    ```
2. Run
    ```
    kubectl apply https://raw.githubusercontent.com/longhorn/longhorn/v0.7.0/deploy/longhorn.yaml
    ```

If you are using Rancher App:
1. Clean up the default StorageClass:
    ```
    kubectl delete -f https://raw.githubusercontent.com/longhorn/longhorn/v0.7.0/examples/storageclass.yaml
    ```
2. Follow [these troubleshooting instructions.](#error-kind-customresourcedefinition-with-the-name-xxx-already-exists-in-the-cluster-and-wasnt-defined-in-the-previous-release) 

#### Error: `kind CustomResourceDefinition with the name "xxx" already exists in the cluster and wasn't defined in the previous release...`

This is [a Helm bug](https://github.com/helm/helm/issues/6031).

Please make sure that you have not deleted the old Longhorn CRDs via the command `curl -s https://raw.githubusercontent.com/longhorn/longhorn-manager/master/hack/cleancrds.sh | bash -s v062` or executed Longhorn uninstaller before executing the following command. Otherwise you MAY LOSE all the data stored in the Longhorn system.

Clean up:
```
kubectl -n longhorn-system delete ds longhorn-manager
curl -s https://raw.githubusercontent.com/longhorn/longhorn-manager/master/hack/cleancrds.sh | bash -s v070
```

2. Re-click the `Upgrade` button in the Rancher UI.

### Clean up the v0.6.2 CRDs

> These steps should not be executed if you want to maintain the ability to [roll back](#rollbacks) from a v0.7.0 installation.

1. Bring back the workload online.
1. Make sure all the volumes are back online.
1. Check all the existing manager pods are running v0.7.0. No v0.6.2 pods should be running. Run this command:
    ```
    kubectl -n longhorn-system get pod -o yaml|grep "longhorn-manager:v0.6.2"
    ```
    No results should appear.
1. Run the following script to clean up the v0.6.2 CRDs.
    > **Important:** You must make sure all the v0.6.2 pods have been deleted, otherwise the data will be lost.
    ```
    curl -s https://raw.githubusercontent.com/longhorn/longhorn-manager/master/hack/cleancrds.sh | bash -s v062
    ```

### Rollbacks

Since we upgrade the CSI framework from v0.4.2 to v1.1.0 in this release, rolling back from Longhorn v0.7.0 to v0.6.2 or lower means downgrading the CSI plugin. But Kubernetes does not support the downgrading the CSI plugin. Therefore, restarting kubelet is unavoidable. Please be careful, and follow the instructions exactly.

> **Prerequisite:** To rollback from v0.7.0 installation, you must not have [cleaned up the v0.6.2 CRDs.](#clean-up-the-v062-crds)

Steps to roll back:

1. Clean up the components introduced by Longhorn v0.7.0 upgrade
    ```
    kubectl delete -f https://raw.githubusercontent.com/longhorn/longhorn/v0.7.0/examples/storageclass.yaml
    curl -s https://raw.githubusercontent.com/longhorn/longhorn-manager/master/hack/cleancrds.sh | bash -s v070
    ```

2. Restart the Kubelet container on all nodes or restart all the nodes. This step WILL DISRUPT all the workloads in the system.

3. Connect to the node then run:
    ```
    docker restart kubelet
    ```

3. Rollback: Use `kubectl apply` or the Rancher catalog app to roll back Longhorn.