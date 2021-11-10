---
title: Customizing Default Settings
weight: 1
---

You may customize Longhorn's default settings when deploying it. You may specify, for example, `Create Default Disk With Node Labeled` and `Default Data Path` before starting Longhorn.

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

2. Modify the Setting CRs in the yaml file `longhorn/deploy/longhorn.yaml`. For example:

    ```yaml
    apiVersion: longhorn.io/v1beta2
    kind: Setting
    metadata:
      name: create-default-disk-labeled-nodes
      namespace: longhorn-system
    value: "true"
    ---
    apiVersion: longhorn.io/v1beta2
    kind: Setting
    metadata:
      name: default-data-path
      namespace: longhorn-system
    value: "/var/lib/longhorn/"
    ---
    ...
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
