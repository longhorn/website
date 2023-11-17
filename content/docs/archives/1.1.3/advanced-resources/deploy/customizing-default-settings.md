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
        volume-attachment-recovery-policy:
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

    ```shell
    helm install longhorn/longhorn --name longhorn --namespace longhorn-system --values values.yaml
    ```

For more info about using helm, see the section about
[installing Longhorn with Helm](../../../deploy/install/install-with-helm)

## History
[Original feature request](https://github.com/longhorn/longhorn/issues/623)

Available since v0.6.0
