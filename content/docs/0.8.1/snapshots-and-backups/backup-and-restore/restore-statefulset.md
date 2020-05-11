---
title: Restoring Volumes for Kubernetes StatefulSets
weight: 4
---
Longhorn supports restoring backups, and one of the use cases for this feature is to restore data for use in a Kubernetes StatefulSet, which requires restoring a volume for each replica that was backed up.

To restore, follow the below instructions. The example below uses a StatefulSet with one volume attached to each Pod and two replicas.

1. [Create Longhorn volumes from backup](#1-create-longhorn-volumes-from-backup)
2. [Create a PV for each restored Longhorn volume](#2-create-a-pv-for-each-restored-longhorn-volume)
3. [Create a PVC for each PV](#3-create-a-pvc-for-each-pv)
4. [Create the StatefulSet](#4-create-the-statefulset)

## 1. Create Longhorn volumes from backup

1. In the Longhorn UI, click the **Backup** tab.
2. Go to the volume that is being used by the StatefulSet. Click the three-line dropdown menu of the volume entry and click **Restore Latest Backup.** 
3. Name the volume something that can easily be referenced later for the `Persistent Volumes`.

Repeat these steps for each volume you need restored.

For example, to restore a StatefulSet with two replicas that had volumes named `pvc-01a` and `pvc-02b`, the restore could look like this:  

| Backup Name | Restored Volume   |
|-------------|-------------------|
| pvc-01a     | statefulset-vol-0 |
| pvc-02b     | statefulset-vol-1 |

## 2. Create a PV for each restored Longhorn volume 

In Kubernetes, you will need to create a `PersistentVolume` for each Longhorn volume that was created.

Name the volumes something that can easily be referenced later by the `Persistent Volume Claims`.

In the example PersistentVolume below, replace the following:

- `storage` capacity
- `storageClassName`
- `numberOfReplicas`
- `volumeHandle`

In this example, we're referencing volumes named `statefulset-vol-0` and `statefulset-vol-1` in Longhorn, and we are using `longhorn` as our `storageClassName`:

    apiVersion: v1
    kind: PersistentVolume
    metadata:
      name: statefulset-vol-0
    spec:
      capacity:
        storage: <size>                    # Must match size of Longhorn volume
      volumeMode: Filesystem
      accessModes:
        - ReadWriteOnce
      persistentVolumeReclaimPolicy: Delete
      csi:
        driver: driver.longhorn.io        # Driver must match this
        fsType: ext4
        volumeAttributes:
          numberOfReplicas: <replicas>    # Must match Longhorn volume value
          staleReplicaTimeout: '30'       # In minutes
        volumeHandle: statefulset-vol-0   # Must match volume name from Longhorn
      storageClassName: longhorn          # Must be same name that we will use later
    ---
    apiVersion: v1
    kind: PersistentVolume
    metadata:
      name: statefulset-vol-1
    spec:
      capacity:
        storage: <size>                   # Must match size of Longhorn volume
      volumeMode: Filesystem
      accessModes:
        - ReadWriteOnce
      persistentVolumeReclaimPolicy: Delete
      csi:
        driver: driver.longhorn.io        # Driver must match this
        fsType: ext4
        volumeAttributes:
          numberOfReplicas: <replicas>    # Must match Longhorn volume value
          staleReplicaTimeout: '30'
        volumeHandle: statefulset-vol-1   # Must match volume name from Longhorn
      storageClassName: longhorn          # Must be same name that we will use later

## 3. Create a PVC for each PV
    
In the `namespace` the `StatefulSet` will be deployed in, create a PVC for each PV.

When you create a StatefulSet in the next step, it will use a name, volumeClaimTemplate, and StorageClassName that correspond to the information defined in this PVC.

The name of the PVC must follow this naming scheme:

    <name of Volume Claim Template>-<name of StatefulSet>-<index>
    
In this example,

- The name of the `Volume Claim Template` in the StatefulSet will be `data`
- The name of the `StatefulSet` will be `webapp`
- There are two replicas, which are indexes `0` and `1`.

StatefulSet Pods are zero-indexed. 

    apiVersion: v1
    kind: PersistentVolumeClaim
    metadata:
      name: data-webapp-0
      spec:
        accessModes:
          - ReadWriteOnce
        resources:
          requests:
            storage: 2Gi             # Must match size from earlier
      storageClassName: longhorn     # Must match name from earlier
      volumeName: statefulset-vol-0  # Must reference PersistentVolume
    ---
    apiVersion: v1
    kind: PersistentVolumeClaim
    metadata:
      name: data-webapp-1
      spec:
        accessModes:
          - ReadWriteOnce
        resources:
          requests:
            storage: 2Gi             # Must match size from earlier
      storageClassName: longhorn     # Must match name from earlier
      volumeName: statefulset-vol-1  # Must reference PersistentVolume

## 4. Create the StatefulSet

Create a StatefulSet that uses volumeClaimTemplates to match with the PVCs that you created:

    apiVersion: apps/v1beta2
    kind: StatefulSet
    metadata:
      name: webapp                  # Match this with the PersistentVolumeClaim naming scheme
    spec:
      selector:
        matchLabels:
          app: nginx                # Has to match .spec.template.metadata.labels
      serviceName: "nginx"
      replicas: 2                   # By default is 1
      template:
        metadata:
          labels:
            app: nginx              # Has to match .spec.selector.matchLabels
        spec:
          terminationGracePeriodSeconds: 10
          containers:
          - name: nginx
            image: k8s.gcr.io/nginx-slim:0.8
            ports:
            - containerPort: 80
              name: web
            volumeMounts:
            - name: data
              mountPath: /usr/share/nginx/html
      volumeClaimTemplates:
      - metadata:
          name: data               # Match this with the PersistentVolumeClaim naming scheme
        spec:
          accessModes: [ "ReadWriteOnce" ]
          storageClassName: longhorn    # Must match name from earlier
          resources:
            requests:
              storage: 2Gi         # Must match size from earlier

**Result:** The restored data should now be accessible from inside the StatefulSet Pods.