---
title: Customizing Default Settings
weight: 1
---

You may customize Longhorn's default settings when deploying it. You may specify, for example, `Create Default Disk With Node Labeled` and `Default Data Path` before starting Longhorn.

This default setting is only for a Longhorn system that hasn't been deployed. It has no impact on an existing Longhorn system. The settings for any existing Longhorn system should be modified using the Longhorn UI.

The default settings can be customized in the following ways:

- [Using the Rancher UI](#using-the-rancher-ui)
- [Using the Longhorn Deployment YAML File](#using-the-longhorn-deployment-yaml-file)
- [Using Helm](#using-helm)

### Using the Rancher UI

From the project view in Rancher, go to **Apps > Launch > Longhorn** and edit the settings before launching the app.

### Using the Longhorn Deployment YAML File

1. Download the longhorn repo:

    ```shell
    git clone https://github.com/longhorn/longhorn.git
    ```

2. Modify the config map named `longhorn-default-setting` in the yaml file `longhorn/deploy/longhorn.yaml`. For example:

    ```
    ---
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: longhorn-default-setting
      namespace: longhorn-system
    data:
      default-setting.yaml: |-
        backup-target: s3://backupbucket@us-east-1/backupstore
        backup-target-credential-secret: minio-secret
        create-default-disk-labeled-nodes: true
        default-data-path: /var/lib/longhorn-example/
        replica-soft-anti-affinity: false
        storage-over-provisioning-percentage: 600
        storage-minimal-available-percentage: 15
        upgrade-checker: false
        default-replica-count: 2
        default-data-locality: disabled
        guaranteed-engine-cpu: 0.25
        default-longhorn-static-storage-class: longhorn-static-example
        backupstore-poll-interval: 500
        taint-toleration: key1=value1:NoSchedule; key2:NoExecute
        registry-secret: registry-secret
        auto-salvage: false
        disable-scheduling-on-cordoned-node: false
        replica-zone-soft-anti-affinity: false
        volume-attachment-recovery-policy: never
        node-down-pod-deletion-policy: do-nothing
        mkfs-ext4-parameters: -O ^64bit,^metadata_csum
    ---
    ```

### Using Helm

Use the Helm command with the `--set` flag to modify the default settings. For example:

```shell
helm install longhorn/longhorn \
--name longhorn \
--namespace longhorn-system \
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
      guaranteedEngineCPU: 0.25
      defaultLonghornStaticStorageClass: longhorn-static-example
      backupstorePollInterval: 500
      taintToleration: key1=value1:NoSchedule; key2:NoExecute
      registrySecret: registry-secret
      autoSalvage: false
      disableSchedulingOnCordonedNode: false
      replicaZoneSoftAntiAffinity: false
      volumeAttachmentRecoveryPolicy: never
      nodeDownPodDeletionPolicy: do-nothing
      mkfsExt4Parameters: -O ^64bit,^metadata_csum
    ```

3. Run Helm with `values.yaml`:

    ```shell
    helm install longhorn/longhorn --name longhorn --namespace longhorn-system --values values.yaml
    ```

For more info about using helm, see the section about
[installing Longhorn with Helm](../../../deploy/install/install-with-helm)

## History
[Original feature request](https://github.com/longhorn/longhorn/issues/623)

Available since v0.6.0
