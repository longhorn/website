---
title: Upgrading Longhorn Manager
weight: 1
---

### Upgrading from v1.3.x (< v{{< current-version >}}) or v1.2.x

We only support upgrading to v{{< current-version >}} from v1.3.x or v1.2.x. For other versions, please upgrade to v1.3.x or v1.2.x first.

Engine live upgrade is supported from v1.3.x or v1.2.x to v{{< current-version >}}.

For airgap upgrades when Longhorn is installed as a Rancher app, you will need to modify the image names and remove the registry URL part.

For example, the image `registry.example.com/longhorn/longhorn-manager:v{{< current-version >}}` is changed to `longhorn/longhorn-manager:v{{< current-version >}}` in Longhorn images section. For more information, see the air gap installation steps [here.](../../../advanced-resources/deploy/airgap/#using-a-rancher-app)

#### Preparing for the Upgrade

If Longhorn was installed using a Helm Chart, or if it was installed as Rancher catalog app, check to make sure the parameters in the default StorageClass weren't changed. Changing the default StorageClass's parameter might result in a chart upgrade failure. if you want to reconfigure the parameters in the StorageClass, you can copy the default StorageClass's configuration to create another StorageClass.

    The current default StorageClass has the following parameters:

        parameters:
          numberOfReplicas: <user specified replica count, 3 by default>
          staleReplicaTimeout: "30"
          fromBackup: ""
          baseImage: ""

#### Upgrade

> **Prerequisite:** Always back up volumes before upgrading. If anything goes wrong, you can restore the volume using the backup.

#### Upgrade as a Rancher Catalog App

To upgrade the Longhorn App, make sure which Rancher UI the existing Longhorn App was installed with. There are two Rancher UIs, one is the Cluster Manager (old UI), and the other one is the Cluster Explorer (new UI). The Longhorn App in different UIs considered as two different applications by Rancher. They cannot upgrade to each other. If you installed Longhorn in the Cluster Manager, you need to use the Cluster Manager to upgrade Longhorn to a newer version, and vice versa for the Cluster Explorer.

Different Rancher UIs screenshots.
- The Cluster Manager (old UI)
{{< figure src="/img/screenshots/install/cluster-manager.png" >}}
- The Cluster Explorer (new UI)
{{< figure src="/img/screenshots/install/cluster-explorer.png" >}}

#### Upgrade with Kubectl

To upgrade with kubectl, run this command:

```
kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/v{{< current-version >}}/deploy/longhorn.yaml
```

#### Upgrade with Helm

To upgrade with Helm, run this command:

```
helm upgrade longhorn longhorn/longhorn --namespace longhorn-system --version {{< current-version >}}
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

#### Post upgrade

To avoid crashing existing volumes, as well as switch from the deprecated setting `Guaranteed Engine CPU` to [the new instance manager CPU reservation mechanism](../../../best-practices/#guaranteed-instance-manager-cpu), Longhorn will automatically set `Engine Manager CPU Request` and `Replica Manager CPU Request` from each node based on the deprecated setting value during upgrade. Then, the new global instance manager CPU settings [`Guaranteed Engine Manager CPU`](../../../references/settings/#guaranteed-engine-manager-cpu) and [`Guaranteed Replica Manager CPU`](../../../references/settings/#guaranteed-replica-manager-cpu) won't take effect.
You may need to check the new mechanism and the setting descriptions to see if you need any adjustments.

### TroubleShooting
#### Error: `"longhorn" is invalid: provisioner: Forbidden: updates to provisioner are forbidden.`
- This means there are some modifications applied to the default storageClass and you need to clean up the old one before upgrade.

- To clean up the deprecated StorageClass, run this command:
    ```
    kubectl delete -f https://raw.githubusercontent.com/longhorn/longhorn/v{{< current-version >}}/examples/storageclass.yaml
    ```

