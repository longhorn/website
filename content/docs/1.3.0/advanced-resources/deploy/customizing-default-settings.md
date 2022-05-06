---
title: Customizing Default Settings
weight: 1
---

You may customize Longhorn's default settings when deploying it. You may specify, for example, `Create Default Disk With Node Labeled` and `Default Data Path` before starting Longhorn.

This default setting is only for a Longhorn system that hasn't been deployed. It has no impact on an existing Longhorn system. The settings for any existing Longhorn system should be modified using the Longhorn UI _or_ by kubectl. Reference to the [knowledge base doc](https://longhorn.io/kb/troubleshooting-default-settings-do-not-persist/) for the details.

The default settings can be customized in the following ways:

- [Deploy](#deploy)
  - [Using the Rancher UI](#using-the-rancher-ui)
  - [Using the Longhorn Deployment YAML File](#using-the-longhorn-deployment-yaml-file)
  - [Using Helm](#using-helm)
- [Upgrade](#upgrade)
  - [Using the Longhorn UI](#using-the-longhorn-ui)
  - [Using Kubectl](#using-kubectl)
  - [Using Script](#using-script)

## Deploy
### Using the Rancher UI

From the project view in Rancher, go to **Apps > Launch > Longhorn** and edit the settings before launching the app.

### Using the Longhorn Deployment YAML File

1. Download the longhorn repo:

    ```shell
    git clone https://github.com/longhorn/longhorn.git
    ```

2. Modify the config map named `longhorn-default-setting` in the yaml file `longhorn/deploy/longhorn.yaml`. For example:

    ```yaml
    ---
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: longhorn-default-setting
      namespace: longhorn-system
    data:
      default-setting.yaml: |-
        backup-target:
        backup-target-credential-secret:
        allow-recurring-job-while-volume-detached:
        create-default-disk-labeled-nodes:
        default-data-path:
        replica-soft-anti-affinity:
        storage-over-provisioning-percentage:
        storage-minimal-available-percentage:
        upgrade-checker:
        default-replica-count:
        default-data-locality:
        guaranteed-engine-cpu:
        default-longhorn-static-storage-class:
        backupstore-poll-interval:
        taint-toleration:
        system-managed-components-node-selector:
        priority-class:
        auto-salvage:
        auto-delete-pod-when-volume-detached-unexpectedly:
        disable-scheduling-on-cordoned-node:
        replica-zone-soft-anti-affinity:
        node-down-pod-deletion-policy:
        allow-node-drain-with-last-healthy-replica:
        mkfs-ext4-parameters:
        disable-replica-rebuild:
        replica-replenishment-wait-interval:
        disable-revision-counter:
        system-managed-pods-image-pull-policy:
        allow-volume-creation-with-degraded-availability:
        auto-cleanup-system-generated-snapshot:
        concurrent-automatic-engine-upgrade-per-node-limit:
        backing-image-cleanup-wait-interval:
        guaranteed-engine-manager-cpu:
        guaranteed-replica-manager-cpu:
    ---
    ```

### Using Helm

Use the Helm command with the `--set` flag to modify the default settings. For example:

- Helm 2
  ```shell
  helm install longhorn/longhorn \
    --name longhorn \
    --namespace longhorn-system \
    --set defaultSettings.taintToleration="key1=value1:NoSchedule; key2:NoExecute"
  ```

- Helm 3
  ```shell
  helm install longhorn longhorn/longhorn \
    --namespace longhorn-system \
    --create-namespace \
    --set defaultSettings.taintToleration="key1=value1:NoSchedule; key2:NoExecute"
  ```

You can also provide a copy of the `values.yaml` file with the default settings modified to the `--values` flag when running the Helm command:

1. Obtain a copy of the `values.yaml` file from GitHub:

    ```shell
    curl -Lo values.yaml https://raw.githubusercontent.com/longhorn/charts/master/charts/longhorn/values.yaml
    ```

2. Modify the default settings in the YAML file. The following is an example snippet of `values.yaml`:

    ```yaml
    defaultSettings:
      backupTarget: s3://backupbucket@us-east-1/backupstore
      backupTargetCredentialSecret: minio-secret
      createDefaultDiskLabeledNodes: true
      defaultDataPath: /var/lib/longhorn-example/
      replicaSoftAntiAffinity: false
      storageOverProvisioningPercentage: 600
      storageMinimalAvailablePercentage: 15
      upgradeChecker: false
      defaultReplicaCount: 2
      defaultDataLocality: disabled
      guaranteedEngineCPU:
      defaultLonghornStaticStorageClass: longhorn-static-example
      backupstorePollInterval: 500
      taintToleration: key1=value1:NoSchedule; key2:NoExecute
      systemManagedComponentsNodeSelector: "label-key1:label-value1"
      priority-class: high-priority
      autoSalvage: false
      disableSchedulingOnCordonedNode: false
      replicaZoneSoftAntiAffinity: false
      volumeAttachmentRecoveryPolicy: never
      nodeDownPodDeletionPolicy: do-nothing
      mkfsExt4Parameters: -O ^64bit,^metadata_csum
      guaranteed-engine-manager-cpu: 15
      guaranteed-replica-manager-cpu: 15
    ```

3. Run Helm with `values.yaml`:
  - Helm 2
     ```shell
     helm install longhorn/longhorn \
       --name longhorn \
       --namespace longhorn-system \
       --values values.yaml
     ```
  - Helm 3
     ```shell
     helm install longhorn longhorn/longhorn \
       --namespace longhorn-system \
       --create-namespace \
       --values values.yaml
     ```

For more info about using helm, see the section about
[installing Longhorn with Helm](../../../deploy/install/install-with-helm)

## Upgrade

### Using the Longhorn UI

We recommend using the Longhorn UI to change Longhorn setting on the existing cluster.
It would make the setting persistent.

### Using Kubectl

If you prefer to use the command line to update the setting, you could use kubectl.
But please be aware **this will bypass Longhorn backend validation**.
```shell
kubectl edit settings <SETTING-NAME> -n longhorn-system
```

### Using Script

If you're using Rancher UI _or_ Helm to upgrade the setting, but found that the customized setting does not apply to the cluster. You could run the below script to update the Longhorn Setting CR according to the longhorn-default-setting ConfigMap.
But please be aware **this will bypass Longhorn backend validation**.
```shell
kubectl -n longhorn-system get configmap longhorn-default-setting -ojsonpath="{.data['default-setting\.yaml']}" | awk '{if ($2) print $0;}' | while read key val; do kubectl -n longhorn-system patch settings ${key%:} --type='json' -p='[{"op": "replace", "path": "/value", "value": "'${val}'"}]'; done
```

## History
[Original feature request](https://github.com/longhorn/longhorn/issues/623)

Available since v0.6.0
