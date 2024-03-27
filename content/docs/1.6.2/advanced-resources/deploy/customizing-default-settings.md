---
title: Customizing Default Settings
weight: 1
---

You may customize Longhorn's default settings while installing or upgrading. You may specify, for example, `Create Default Disk With Node Labeled` and `Default Data Path` before starting Longhorn.

The default settings can be customized in the following ways:

- [Installation](#installation)
  - [Using the Rancher UI](#using-the-rancher-ui)
  - [Using the Longhorn Deployment YAML File](#using-the-longhorn-deployment-yaml-file)
  - [Using Helm](#using-helm)
- [Update Settings](#update-settings)
  - [Using the Longhorn UI](#using-the-longhorn-ui)
  - [Using the Rancher UI](#using-the-rancher-ui-1)
  - [Using Kubectl](#using-kubectl)
  - [Using Helm](#using-helm-1)
- [Upgrade](#upgrade)
  - [Using the Rancher UI](#using-the-rancher-ui-2)
  - [Using the Longhorn Deployment YAML File](#using-the-longhorn-deployment-yaml-file-1)
  - [Using Helm](#using-helm-2)
- [History](#history)


> **NOTE:** When using Longhorn Deployment YAML file or Helm for installation, updating or upgrading, if the value of a default setting is an empty string and valid, the default setting will be cleaned up in Longhorn. If not, Longhorn will ignore the invalid values and will not update the default values.

## Installation
### Using the Rancher UI

From the project view in Rancher, go to **Apps && Marketplace > Longhorn > Install > Next > Edit Options > Longhorn Default Settings > Customize Default Settings** and edit the settings before installing the app.

### Using the Longhorn Deployment YAML File

1. Download the longhorn repo:

    ```shell
    git clone https://github.com/longhorn/longhorn.git
    ```

1. Modify the config map named `longhorn-default-setting` in the yaml file `longhorn/deploy/longhorn.yaml`.

    In the below example, users customize the default settings, backup-target, backup-target-credential-secret, and default-data-path.
    When the setting is absent or has a leading `#` symbol, the default setting will use the default value in Longhorn or the customized values previously configured.

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
        #allow-recurring-job-while-volume-detached:
        #create-default-disk-labeled-nodes:
        default-data-path: /var/lib/longhorn-example/
        #replica-soft-anti-affinity:
        #replica-auto-balance:
        #storage-over-provisioning-percentage:
        #storage-minimal-available-percentage:
        #upgrade-checker:
        #default-replica-count:
        #default-data-locality:
        #default-longhorn-static-storage-class:
        #backupstore-poll-interval:
        #taint-toleration:
        #system-managed-components-node-selector:
        #priority-class:
        #auto-salvage:
        #auto-delete-pod-when-volume-detached-unexpectedly:
        #disable-scheduling-on-cordoned-node:
        #replica-zone-soft-anti-affinity:
        #replica-disk-soft-anti-affinity:
        #node-down-pod-deletion-policy:
        #node-drain-policy:
        #replica-replenishment-wait-interval:
        #concurrent-replica-rebuild-per-node-limit:
        #disable-revision-counter:
        #system-managed-pods-image-pull-policy:
        #allow-volume-creation-with-degraded-availability:
        #auto-cleanup-system-generated-snapshot:
        #concurrent-automatic-engine-upgrade-per-node-limit:
        #backing-image-cleanup-wait-interval:
        #backing-image-recovery-wait-interval:
        #guaranteed-instance-manager-cpu:
        #kubernetes-cluster-autoscaler-enabled:
        #orphan-auto-deletion:
        #storage-network:
        #recurring-successful-jobs-history-limit:
        #recurring-failed-jobs-history-limit:
    ---
    ```

### Using Helm

> **NOTE:**
> Use Helm 3 when installing and upgrading Longhorn. Helm 2 is [no longer supported](https://helm.sh/blog/helm-2-becomes-unsupported/).

Use the Helm command with the `--set` flag to modify the default settings. For example:

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

   When the setting is absent or has a leading `#` symbol, the default setting will use the default value in Longhorn or the customized values previously configured.

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
      defaultLonghornStaticStorageClass: longhorn-static-example
      backupstorePollInterval: 500
      taintToleration: key1=value1:NoSchedule; key2:NoExecute
      systemManagedComponentsNodeSelector: "label-key1:label-value1"
      priorityClass: high-priority
      autoSalvage: false
      disableSchedulingOnCordonedNode: false
      replicaZoneSoftAntiAffinity: false
      replicaDiskSoftAntiAffinity: false
      volumeAttachmentRecoveryPolicy: never
      nodeDownPodDeletionPolicy: do-nothing
      guaranteedInstanceManagerCpu: 15
      orphanAutoDeletion: false
    ```

3. Run Helm with `values.yaml`:

   ```shell
   helm install longhorn longhorn/longhorn \
     --namespace longhorn-system \
     --create-namespace \
     --values values.yaml
   ```

For more info about using helm, see the section about
[installing Longhorn with Helm](../../../deploy/install/install-with-helm)

## Update Settings

### Using the Longhorn UI

We recommend using the Longhorn UI to change Longhorn setting on the existing cluster. It would make the setting persistent.

### Using the Rancher UI

From the project view in Rancher, go to **Apps && Marketplace > Longhorn > Upgrade > Next > Edit Options > Longhorn Default Settings > Customize Default Settings** and edit the settings before upgrading the app to the current Longhorn version.

### Using Kubectl

If you prefer to use the command line to update the setting, you could use `kubectl`.
```shell
kubectl edit settings <SETTING-NAME> -n longhorn-system
```

### Using Helm

Modify the default settings in the YAML file as described in [Fresh Installation > Using Helm](#using-helm) and then update the settings using
```
helm upgrade longhorn longhorn/longhorn --namespace longhorn-system --values ./values.yaml --version `helm list -n longhorn-system -o json | jq -r .'[0].app_version'`
```

## Upgrade

### Using the Rancher UI

From the project view in Rancher, go to **Apps && Marketplace > Longhorn > Upgrade > Next > Edit Options > Longhorn Default Settings > Customize Default Settings** and edit the settings before upgrading the app.
### Using the Longhorn Deployment YAML File

Modify the config map named `longhorn-default-setting` in the yaml file `longhorn/deploy/longhorn.yaml` as described in [Fresh Installation > Using the Longhorn Deployment YAML File](#using-the-longhorn-deployment-yaml-file) and then upgrade the Longhorn system using `kubectl`.

### Using Helm

Modify the default settings in the YAML file as described in [Fresh Installation > Using Helm](#using-helm) and then upgrade the Longhorn system using `helm upgrade`.

## History
Available since v1.3.0 ([Reference](https://github.com/longhorn/longhorn/issues/2570))
