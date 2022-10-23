---
title: Upgrading Longhorn Manager
weight: 1
---

### Upgrading from v1.2.x

We only support upgrading to v{{< current-version >}} from v1.2.x. For other versions, please upgrade to v1.2.x first.

Engine live upgrade is supported from v1.2.x to v{{< current-version >}}.

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

> Note: Because the Cluster Manager (old UI) is being deprecated, we provided the instruction to migrate the existing Longhorn installation to the Longhorn chart in the Cluster Explorer (new UI) [here](https://longhorn.io/kb/how-to-migrate-longhorn-chart-installed-in-old-rancher-ui-to-the-chart-in-new-rancher-ui/)

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
NAME                                           READY   STATUS    RESTARTS      AGE
engine-image-ei-4dbdb778-nw88l                 1/1     Running   0             4m29s
longhorn-conversion-webhook-5dc58756b6-8vf8g   1/1     Running   0             75s
longhorn-conversion-webhook-5dc58756b6-jqq6n   1/1     Running   0             75s
longhorn-ui-b7c844b49-jn5g6                    1/1     Running   0             75s
longhorn-admission-webhook-8b7f74576-898c4     1/1     Running   0             75s
longhorn-admission-webhook-8b7f74576-t7jqk     1/1     Running   0             75s
longhorn-manager-z2p8h                         1/1     Running   0             71s
instance-manager-r-de8337e2                    1/1     Running   0             65s
instance-manager-e-c812d56c                    1/1     Running   0             65s
longhorn-driver-deployer-6bd59c9f76-jp6pg      1/1     Running   0             75s
engine-image-ei-df38d2e5-zccq5                 1/1     Running   0             65s
csi-snapshotter-588457fcdf-h2lgc               1/1     Running   0             30s
csi-resizer-6d8cf5f99f-8v4sp                   1/1     Running   1 (30s ago)   37s
csi-snapshotter-588457fcdf-6pgf4               1/1     Running   0             30s
csi-provisioner-869bdc4b79-7ddwd               1/1     Running   1 (30s ago)   44s
csi-snapshotter-588457fcdf-p4kkn               1/1     Running   0             30s
csi-attacher-7bf4b7f996-mfbdn                  1/1     Running   1 (30s ago)   50s
csi-provisioner-869bdc4b79-4dc7n               1/1     Running   1 (30s ago)   43s
csi-resizer-6d8cf5f99f-vnspd                   1/1     Running   1 (30s ago)   37s
csi-attacher-7bf4b7f996-hrs7w                  1/1     Running   1 (30s ago)   50s
csi-attacher-7bf4b7f996-rt2s9                  1/1     Running   1 (30s ago)   50s
csi-resizer-6d8cf5f99f-7vv89                   1/1     Running   1 (30s ago)   37s
csi-provisioner-869bdc4b79-sn6zr               1/1     Running   1 (30s ago)   43s
longhorn-csi-plugin-b2zzj                      2/2     Running   0             24s
```

Next, [upgrade Longhorn engine.](../upgrade-engine)

#### Post upgrade

To avoid crashing existing volumes, as well as switch from the deprecated setting `Guaranteed Engine CPU` to [the new instance manager CPU reservation mechanism](../../../best-practices/#guaranteed-instance-manager-cpu), Longhorn will automatically set `Engine Manager CPU Request` and `Replica Manager CPU Request` from each node based on the deprecated setting value during upgrade. Then, the new global instance manager CPU settings [`Guaranteed Engine Manager CPU`](../../../references/settings/#guaranteed-engine-manager-cpu) and [`Guaranteed Replica Manager CPU`](../../../references/settings/#guaranteed-replica-manager-cpu) won't take effect.
You may need to check the new mechanism and the setting descriptions to see if you need any adjustments.

### TroubleShooting
1. Error: `"longhorn" is invalid: provisioner: Forbidden: updates to provisioner are forbidden.`
- This means there are some modifications applied to the default storageClass and you need to clean up the old one before upgrade.

- To clean up the deprecated StorageClass, run this command:
    ```
    kubectl delete -f https://raw.githubusercontent.com/longhorn/longhorn/v{{< current-version >}}/examples/storageclass.yaml
    ```

2. Error: `...proto: duplicate proto type registered: VersionResponse panic: Unrecognized command: conversion-webhook ...` in the longhorn-conversion-webhook pods in `CrashLoopBackOff` state.
    - Check if the longhorn-conversion-webhook image tag is v{{< current-version >}} by
        ```
        kubectl -n longhorn-system get deployments longhorn-conversion-webhook -o yaml | grep image
        ```

    - It indicates Helm uses the previously configured image tag value if the image tag is different than expected, i.e. v{{< current-version >}}. Then, you need to reset the values by `--reset-values`.
        - You can simply upgrade Longhorn without updating your customized default settings.
            ```
            helm upgrade longhorn longhorn/longhorn -n longhorn-system --reset-values
            ```
        - You can customize the default settings in as described in [Customize Default Settings](../../../advanced-resources/deploy/customizing-default-settings/) and then run
            ```
            helm upgrade longhorn longhorn/longhorn -n longhorn-system --values ./values.yaml --reset-values
            ```

