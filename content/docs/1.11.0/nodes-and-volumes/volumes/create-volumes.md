---
title: Create Longhorn Volumes
weight: 1
---

In this tutorial, you'll learn how to create Kubernetes persistent storage resources of persistent volumes (PVs) and persistent volume claims (PVCs) that correspond to Longhorn volumes. You will use kubectl to dynamically provision storage for workloads using a Longhorn storage class. For help creating volumes from the Longhorn UI, refer to [this section.](#creating-longhorn-volumes-with-the-longhorn-ui)

> This section assumes that you understand how Kubernetes persistent storage works. For more information, see the [Kubernetes documentation.](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)

## Access Modes

Longhorn supports the following Kubernetes PersistentVolume access modes:

- **ReadWriteOnce (RWO)**: The volume can be mounted as read-write by a single node. Multiple pods on the same node can access the volume. This is the default and most common access mode.
- **ReadWriteOncePod (RWOP)**: The volume can be mounted as read-write by a single pod in the entire cluster. This provides the strongest isolation guarantee, ensuring only one pod can access the volume at any time. Ideal for stateful workloads requiring single-writer access.
- **ReadWriteMany (RWX)**: The volume can be mounted as read-write by many nodes simultaneously, enabling shared access across multiple pods. See [ReadWriteMany (RWX) Volume](../rwx-volumes) for more details.

> **Note**: ReadOnlyMany (ROX) is not supported by Longhorn. For read-only access from multiple pods, consider using ReadWriteMany with read-only mount options in your pod specification.

### Creating Longhorn Volumes with kubectl

First, you will create a Longhorn StorageClass. The Longhorn StorageClass contains the parameters to provision PVs.

Next, a PersistentVolumeClaim is created that references the StorageClass. Finally, the PersistentVolumeClaim is mounted as a volume within a Pod.

When the Pod is deployed, the Kubernetes master will check the PersistentVolumeClaim to make sure the resource request can be fulfilled. If storage is available, the Kubernetes master will create the Longhorn volume and bind it to the Pod.

1. Use following command to create a StorageClass called `longhorn`:

    ```
    kubectl create -f https://raw.githubusercontent.com/longhorn/longhorn/v{{< current-version >}}/examples/storageclass.yaml
    ```

    The following example StorageClass is created:

    ```
    kind: StorageClass
    apiVersion: storage.k8s.io/v1
    metadata:
      name: longhorn
    provisioner: driver.longhorn.io
    allowVolumeExpansion: true
    parameters:
      numberOfReplicas: "3"
      staleReplicaTimeout: "2880" # 48 hours in minutes
      fromBackup: ""
      fsType: "ext4"
    #  backupTargetName: "default"
    #  mkfsParams: "-I 256 -b 4096 -O ^metadata_csum,^64bit"
    #  diskSelector: "ssd,fast"
    #  nodeSelector: "storage,fast"
    #  recurringJobSelector: '[
    #   {
    #     "name":"snap",
    #     "isGroup":true,
    #   },
    #   {
    #     "name":"backup",
    #     "isGroup":false,
    #   }
    #  ]'
    ```

    In particular, starting with v1.4.0, the parameter `mkfsParams` can be used to specify filesystem format options for each StorageClass.
    Starting with v1.8.0, the parameter `backupTargetName` can be used to specify the backup target. The name of the default backup target (`default`) is used if `backupTargetName` is not specified.
    Parameters may be omitted from the StorageClass specification.  When the storage class is used to create a PV and a volume, parameters that are not specified will generally be set using a default value taken from the global settings.  See [here](../../../references/storage-class-parameters) for the list of storage class parameters, and [here](../../../references/settings) for the full list of global settings.

2. Create a Pod that uses Longhorn volumes by running this command:

    ```
    kubectl create -f https://raw.githubusercontent.com/longhorn/longhorn/v{{< current-version >}}/examples/pod_with_pvc.yaml
    ```

    A Pod named `volume-test` is launched, along with a PersistentVolumeClaim named `longhorn-volv-pvc`. The PersistentVolumeClaim references the Longhorn StorageClass:

    ```
    apiVersion: v1
    kind: PersistentVolumeClaim
    metadata:
      name: longhorn-volv-pvc
    spec:
      accessModes:
        - ReadWriteOnce
      storageClassName: longhorn
      resources:
        requests:
          storage: 2Gi
    ```

    The persistentVolumeClaim is mounted in the Pod as a volume:

    ```
    apiVersion: v1
    kind: Pod
    metadata:
      name: volume-test
      namespace: default
    spec:
      containers:
      - name: volume-test
        image: nginx:stable-alpine
        imagePullPolicy: IfNotPresent
        volumeMounts:
        - name: volv
          mountPath: /data
        ports:
        - containerPort: 80
      volumes:
      - name: volv
        persistentVolumeClaim:
          claimName: longhorn-volv-pvc
    ```
More examples are available [here.](../../../references/examples)

### Binding Workloads to PVs without a Kubernetes StorageClass

It is possible to use a Longhorn StorageClass to bind a workload to a PV without creating a StorageClass object in Kubernetes.

Since the Storage Class is also a field used to match a PVC with a PV, which doesn't have to be created by a Provisioner, you can create a PV manually with a custom StorageClass name, then create a PVC asking for the same StorageClass name.

When a PVC requests a StorageClass that does not exist as a Kubernetes resource, Kubernetes will try to bind your PVC to a PV with the same StorageClass name. The StorageClass will be used like a label to find the matching PV, and only existing PVs labeled with the StorageClass name will be used.

If the PVC names a StorageClass, Kubernetes will:

1. Look for an existing PV that has the label matching the StorageClass
2. Look for an existing StorageClass Kubernetes resource. If the StorageClass exists, it will be used to create a PV.

### Creating Longhorn Volumes with the Longhorn UI

Since the Longhorn volume already exists while creating PV/PVC, a StorageClass is not needed for dynamically provisioning Longhorn volume. However, the field `storageClassName` should be set in PVC/PV, to be used for PVC binding purpose. It's unnecessary for users to create the related StorageClass object.

By default the StorageClass for Longhorn created PV/PVC is `longhorn-static`. Users can modify it in `Setting - General - Default Longhorn Static StorageClass Name` as they need.

Users need to manually delete PVC and PV created by Longhorn.

### PV/PVC Creation for Existing Longhorn Volume

Now users can create PV/PVC via our Longhorn UI for the existing Longhorn volumes.
Only detached volume can be used by a newly created pod.

### The Failure of the Longhorn Volume Creation

Creating a Longhorn volume can fail for different reasons. The issues are categorized into:

- insufficient storage
- disk not found
- disks are unavailable
- tags not fulfilled
- node not found
- nodes are unavailable
- none of the node candidates contains a ready engine image
- hard affinity cannot be satisfied
- replica scheduling failed
- unused failed replica is not supported
- replica already scheduled
- longhorn client operation failed
- incompatible volume size

The failure results in the workload failing to use the provisioned PV and showing a warning message
```
# kubectl describe pod workload-test

Events:
  Type     Reason              Age                From                     Message
  ----     ------              ----               ----                     -------
  Warning  FailedAttachVolume  14s (x8 over 82s)  attachdetach-controller  AttachVolume.Attach
  failed for volume "pvc-e130e369-274d-472d-98d1-f6074d2725e8" : rpc error: code = Aborted
  desc = volume pvc-e130e369-274d-472d-98d1-f6074d2725e8 is not ready for workloads
```

In order to help users understand the error causes, Longhorn summarizes them in the PV annotation, `longhorn.io/volume-scheduling-error`. Failures are combined in this annotation and separated by a semicolon, for example, `longhorn.io/volume-scheduling-error: insufficient storage;disks are unavailable`. The annotation can be checked by using `kubectl describe pv <pvc name>`.
```
# kubectl describe pv pvc-e130e369-274d-472d-98d1-f6074d2725e8
Name:            pvc-e130e369-274d-472d-98d1-f6074d2725e8
Labels:          <none>
Annotations:     longhorn.io/volume-scheduling-error: insufficient storage
                 pv.kubernetes.io/provisioned-by: driver.longhorn.io

...

```
