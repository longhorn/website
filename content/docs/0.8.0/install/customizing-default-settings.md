---
title: Customizing Default Settings
weight: 10
---

You may customize Longhorn's default settings when deploying it. You may specify, for example, `Create Default Disk With Node Labeled` and `Default Data Path` before starting Longhorn.

## Usage

{{< info >}}
This default setting is only for Longhorn system that haven't been deployed. And it has no impact on the existing Longhorn system.

You should modify the settings for any existing Longhorn system via the Longhorn UI.
{{< /info >}}

### Via Rancher UI

[Cluster] -> System -> Apps -> Launch -> longhorn -> LONGHORN DEFAULT SETTINGS

### Via Longhorn deployment YAML file

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
        backup-target: s3://backupbucket@us-east-1/backupstore
        backup-target-credential-secret: minio-secret
        create-default-disk-labeled-nodes: true
        default-data-path: /var/lib/longhorn-example/
        replica-soft-anti-affinity: false
        storage-over-provisioning-percentage: 600
        storage-minimal-available-percentage: 15
        upgrade-checker: false
        default-replica-count: 2
        guaranteed-engine-cpu:
        default-longhorn-static-storage-class: longhorn-static-example
        backupstore-poll-interval: 500
        taint-toleration: key1=value1:NoSchedule; key2:NoExecute
    ---
    ```

### Via helm

1. Download the chart in the Longhorn repo:

    ```shell
    git clone https://github.com/longhorn/longhorn.git
    ```

2.1 Use helm command with `--set` flag to modify the default settings. For example:

    ```shell
    helm install ./longhorn/chart \
    --name longhorn \
    --namespace longhorn-system \
    --set defaultSettings.taintToleration="key1=value1:NoSchedule; key2:NoExecute"
    ```

2.2. Or directly modifying the default settings in the yaml file `longhorn/chart/values.yaml` then using helm command without `--set` to deploy Longhorn. For example:

    In `longhorn/chart/values.yaml`:

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
      guaranteedEngineCPU:
      defaultLonghornStaticStorageClass: longhorn-static-example
      backupstorePollInterval: 500
      taintToleration: key1=value1:NoSchedule; key2:NoExecute
    ```

    Then use the `helm` command:

    ```shell
    helm install ./longhorn/chart --name longhorn --namespace longhorn-system
    ```

For more info about using helm, see: 
[Install-Longhorn-with-helm](../install-with-helm)

## History
[Original feature request](https://github.com/longhorn/longhorn/issues/623)

Available since v0.6.0
