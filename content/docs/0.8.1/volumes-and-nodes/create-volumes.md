---
title: Creating Longhorn Volumes
weight: 1
---

In this tutorial, you'll learn how to create Kubernetes persistent storage resources of persistent volumes (PVs) and persistent volume claims (PVCs) that correspond to Longhorn volumes. You will use kubectl to dynamically provision storage for workloads using a Longhorn storage class. For help creating volumes from the Longhorn UI, refer to [this section.](#creating-longhorn-volumes-with-the-longhorn-ui)

> This section assumes that you understand how Kubernetes persistent storage works. For more information, see the [Kubernetes documentation.](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)

### Creating Longhorn Volumes with kubectl

First, you will create a Longhorn StorageClass. The Longhorn StorageClass contains the parameters to provision persistent volumes.

Next, a PersistentVolumeClaim is created that references the StorageClass. Finally, the PersistentVolumeClaim is mounted as a volume within a Pod.

When the Pod is deployed, the Kubernetes master will check the PersistentVolumeClaim to make sure the resource request can be fulfilled. If storage is available, the Kubernetes master will create the Longhorn volume and bind it to the Pod.

1. Use following command to create a StorageClass called `longhorn`:

    ```
    kubectl create -f https://raw.githubusercontent.com/longhorn/longhorn/master/examples/storageclass.yaml
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
    #  diskSelector: "ssd,fast"
    #  nodeSelector: "storage,fast"
    #  recurringJobs: '[{"name":"snap", "task":"snapshot", "cron":"*/1 * * * *", "retain":1},
    #                   {"name":"backup", "task":"backup", "cron":"*/2 * * * *", "retain":1,
    #                    "labels": {"interval":"2m"}}]'
    ```

2. Create a Pod that uses Longhorn volumes by running this command:

    ```
    kubectl create -f https://raw.githubusercontent.com/longhorn/longhorn/master/examples/pod_with_pvc.yaml
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
More examples are available [here.](../../references/examples)

### Binding Workloads to PVs without a Kubernetes StorageClass

The StorageClass name can also be used as a label, so it is possible to use a Longhorn StorageClass to bind a workload to an existing PV without creating a StorageClass object in Kubernetes.

Since the Storage Class is also a field used to match a PVC with a PV, which doesn't have to be created by a Provisioner, you can create a PV manually with a custom StorageClass name, then create a PVC asking for the same StorageClass name.

When a PVC requests a StorageClass that does not exist as a Kubernetes resource, Kubernetes will try to bind your PVC to a PV with the same StorageClass name. The StorageClass will be used like a label to find the matching PV, and only existing PVs labeled with the StorageClass name will be used.

If the PVC names a StorageClass, Kubernetes will:

1. Look for an existing PV that has the label matching the StorageClass.
2. Look for an existing StorageClass Kubernetes resource. If the StorageClass exists, it will be used to create a PV.

### Creating Longhorn Volumes with the Longhorn UI

Since the Longhorn volume already exists while creating PV/PVC from it in the Longhorn UI, a StorageClass is not needed for dynamically provisioning Longhorn volumes. However, the field `storageClassName` should be set in the PVC/PV, to be used for the purpose of binding PVCs. And it's unnecessary for the related StorageClass object to be created.

By default the StorageClass for Longhorn-created PVs and PVCs is `longhorn-static`. To change the default StorageClass name, click the **Settings** tab in Longhorn and edit the ***Default Longhorn Static StorageClass Name** field.

PVCs and PVs created by Longhorn need to be manually deleted.

# PV/PVC creation for existing Longhorn volume
Now PV/PVC pairs can be created via our Longhorn UI for the existing Longhorn volumes.

Only detached volumes can be used by newly created pods.

1. In the Longhorn UI, go to the **Volume** tab.
2. Check the box to the left of the volume that needs a corresponding PV and PVC. You will see that more buttons at the top of the list of volumes are now available.
3. Click the three-line menu dropdown and click **Create PV/PVC.**
4. Enter a namespace where the PV and PVC will be created.
5. Click **OK.**

**Result:** A PV and PVC corresponding to the volume are created in the Kubernetes cluster.