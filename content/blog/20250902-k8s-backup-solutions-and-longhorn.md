---
title: Backup Applications with Longhorn V2 Volumes using Velero
author: Phan Le
draft: false
date: 2025-09-10
categories:
- "backup"
tags:
- "backup"
- "clone"
- "velero"
---

<!--more-->

## Table of contents:

* [Overview](/blog/20250902-k8s-backup-solutions-and-longhorn/#overview)
* [Setup Longhorn](/blog/20250902-k8s-backup-solutions-and-longhorn/#setup-longhorn)
* [Setup Velero](/blog/20250902-k8s-backup-solutions-and-longhorn/#setup-velero)
* [Deloy Application with Longhorn V2 volume](/blog/20250902-k8s-backup-solutions-and-longhorn/#deploy-application-with-longhorn-v2-volume)
  * [Deploy the application](/blog/20250902-k8s-backup-solutions-and-longhorn/#deploy-the-application)
  * [Generate some data](/blog/20250902-k8s-backup-solutions-and-longhorn/#generate-some-data)
* [Backup ](/blog/20250902-k8s-backup-solutions-and-longhorn/#backup)
* [Restore](/blog/20250902-k8s-backup-solutions-and-longhorn/#restore)
* [Restore to a different cluster and different storage provider](/blog/20250902-k8s-backup-solutions-and-longhorn/#restore-to-a-different-cluster-and-different-storage-provider)
* [Conclusion](/blog/20250902-k8s-backup-solutions-and-longhorn/#conclusion)


## Overview

When you run stateful applications on Kubernetes with Longhorn as the storage provider, you often need to back up the entire application stack, including namespaces, ConfigMaps, Secrets, and PVCs/PVs. This ensures a quick and reliable restoration if something goes wrong, even on a new cluster.

This guide uses Velero, a standard, open-source Kubernetes backup solution, to protect applications whose PVCs are backed by Longhorn v2 (Data Engine v2). It also enables a performance optimization using Longhorn v2 linked-clone, which creates Velero's temporary backup PVC almost instantly, reducing backup time.

The Longhorn v2 linked-clone feature was introduced in the Longhorn v1.10. For more details, see the GitHub ticket [#7794](https://github.com/longhorn/longhorn/issues/7794). In short, when you clone a new PVC from an existing PVC using linked-clone mode, no data is copied, and the clone completes instantly.

## Setup Longhorn

1. Create a three-node Kubernetes cluster.
1. Install Longhorn and enable the v2 data engine following the [Quick Start](https://longhorn.io/docs/1.10.0/v2-data-engine/quick-start/).
1. Create a StorageClass for app PVCs (note the `dataEngine: "v2"` setting):
    ```yaml
    kind: StorageClass
    apiVersion: storage.k8s.io/v1
    metadata:
      name: longhorn-v2-data-engine
    provisioner: driver.longhorn.io
    allowVolumeExpansion: true
    reclaimPolicy: Delete
    volumeBindingMode: Immediate
    parameters:
      numberOfReplicas: "2"
      staleReplicaTimeout: "2880"
      fsType: "ext4"
      dataEngine: "v2"
    ```
1. Install the VolumeSnapshot CRDs and the external snapshot controller if your cluster does not have them. Refer to the [Longhorn documentation for CSI snapshot support](https://longhorn.io/docs/1.9.1/snapshots-and-backups/csi-snapshot-support/enable-csi-snapshot-support/#if-your-kubernetes-distribution-does-not-bundle-the-snapshot-controller).
1. Create a `VolumeSnapshotClass` for Longhorn and label it so Velero picks it up for Longhorn-provisioned PVCs.
   > **Note**:
   > - The label `velero.io/csi-volumesnapshot-class: "true"` tells Velero to use this as the default `VolumeSnapshotClass` for any Longhorn volumes during a backup.
   > - The parameter `type: snap` instructs Longhorn to create an in-cluster snapshot, not a Longhorn backup. Velero handles moving the snapshot data to the S3 bucket later.

   ```yaml
   kind: VolumeSnapshotClass
   apiVersion: snapshot.storage.k8s.io/v1
   metadata:
     name: longhorn-snapshot-vsc
     labels:
       velero.io/csi-volumesnapshot-class: "true"
   driver: driver.longhorn.io
   deletionPolicy: Delete
   parameters:
     type: snap
   ```


## Setup Velero
1. Download and install the Velero CLI from the [official releases page](https://github.com/vmware-tanzu/velero/releases).
1. Use an AWS S3 bucket as the backup location for Velero. Create an S3 bucket and obtain the access key and secret key. Then create a `credentials-velero` file in the following format:
    ```ini
    [default]
    aws_access_key_id=<AWS_ACCESS_KEY_ID>
    aws_secret_access_key=<AWS_SECRET_ACCESS_KEY>
    ```
1. Create the Velero namespace:
    ```bash
    kubectl create ns velero
    ```
1. Create a fast-clone StorageClass for Velero’s temporary backup PVC. This guide uses linked-clone with one replica to make the PVC creation nearly instant.
    ```yaml
    kind: StorageClass
    apiVersion: storage.k8s.io/v1
    metadata:
      name: velero-backuppvc-longhorn-v2-data-engine
    provisioner: driver.longhorn.io
    reclaimPolicy: Delete
    volumeBindingMode: Immediate
    parameters:
      numberOfReplicas: "1"
      staleReplicaTimeout: "2880"
      fsType: "ext4"
      dataEngine: "v2"
      cloneMode: "linked-clone"
    ```
1. Tell the Velero Node Agent to use that StorageClass when it creates the temporary backup PVC:
    ```yaml
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: velero-node-agent-cfg
      namespace: velero
    data:
      node-agent-config.json: |
        {
          "backupPVC": {
            "longhorn-v2-data-engine": {
              "storageClass": "velero-backuppvc-longhorn-v2-data-engine"
            }
          }
        }
    ```

1. Install Velero using the CLI. Include the AWS object-store plugin for S3, enable CSI, and turn on the Node Agent (privileged for block-volume access). Also pass our Node Agent ConfigMap:
    ```bash
    velero install \
    --provider aws \
    --plugins velero/velero-plugin-for-aws:v1.12.2 \ # choose a compatible version with the CLI version. Ref https://github.com/vmware-tanzu/velero-plugin-for-aws?tab=readme-ov-file#compatibility
    --bucket <BUCKET> \
    --backup-location-config region=<REGION> \
    --secret-file ./credentials-velero \
    --features=EnableCSI \                        # enable CSI integration
    --use-node-agent \                            # required for data movement
    --privileged-node-agent \                     # needed for block volumes
    --node-agent-configmap=velero-node-agent-cfg  # needed for Longhorn linked-clone (fast clone)
    ```


## Deploy Application with Longhorn V2 volume

This section describes how to deploy a fully functional [Gitea](https://about.gitea.com/) instance, which is a lightweight, open-source, self-hosted Git service. The instance uses a PVC backed by a Longhorn v2 volume to persist repository data. After deployment, you will create a sample repository and then back up the entire application stack with Velero. This process uses Longhorn v2's fast-clone (linked-clone) feature to significantly speed up the backup.

The stack includes the following components:
1. A dedicated namespace: `gitea-demo`
1. A ConfigMap and a Secret for application configuration and credentials
1. A Deployment for the Gitea application
1. A PVC backed by a Longhorn v2 volume
1. A Service to expose the application

### Deploy the application
Apply the following yaml to deploy the application:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: gitea-demo

---
apiVersion: v1
kind: Secret
metadata:
  name: gitea-admin
  namespace: gitea-demo
type: Opaque
data:
  # echo -n 'admin' | base64
  username: YWRtaW4=
  # echo -n 'ChangeMe123!' | base64
  password: Q2hhbmdlTWUxMjMh
  # echo -n 'admin@example.com' | base64
  email: YWRtaW5AZXhhbXBsZS5jb20=

---
apiVersion: v1
kind: ConfigMap
metadata:
  name: gitea-config
  namespace: gitea-demo
data:
  # This file will be COPIED into the PVC by an initContainer (so Gitea can write to it later).
  app.ini: |
    APP_NAME = Velero Longhorn Demo
    RUN_MODE = prod
    RUN_USER = git

    [server]
    PROTOCOL = http
    DOMAIN = localhost
    HTTP_PORT = 3000
    ROOT_URL = http://localhost:3000/
    DISABLE_SSH = true

    [database]
    DB_TYPE = sqlite3
    PATH = /data/gitea/gitea.db

    [security]
    INSTALL_LOCK = true
    MIN_PASSWORD_LENGTH = 8

    [service]
    REGISTER_EMAIL_CONFIRM = false
    DISABLE_REGISTRATION = true
    SHOW_REGISTRATION_BUTTON = false

---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: gitea-data
  namespace: gitea-demo
spec:
  storageClassName: longhorn-v2-data-engine
  accessModes: ["ReadWriteOnce"]
  resources:
    requests:
      storage: 5Gi
  volumeMode: Filesystem

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: gitea
  namespace: gitea-demo
spec:
  replicas: 1
  selector:
    matchLabels:
      app: gitea
  template:
    metadata:
      labels:
        app: gitea
    spec:
      securityContext:
        runAsUser: 1000
        runAsGroup: 1000
        fsGroup: 1000
      volumes:
        - name: data
          persistentVolumeClaim:
            claimName: gitea-data
        - name: config-src
          configMap:
            name: gitea-config
            items:
              - key: app.ini
                path: app.ini
      initContainers:
        # 1) Seed app.ini from ConfigMap into the PVC (so it is writable/persistent)
        - name: seed-config
          image: docker.gitea.com/gitea:1.24.5-rootless
          command: ["/bin/sh","-c"]
          args:
            - >
              set -euo pipefail;
              mkdir -p /data/gitea/conf;
              if [ ! -f /data/gitea/conf/app.ini ]; then
                cp /config/app.ini /data/gitea/conf/app.ini;
              fi;
          volumeMounts:
            - name: data
              mountPath: /data
            - name: config-src
              mountPath: /config
        # 2) Create the admin user on first run (safe if rerun; it will fail if exists, which is fine)
        - name: create-admin
          image: docker.gitea.com/gitea:1.24.5-rootless
          env:
            - name: USERNAME
              valueFrom:
                secretKeyRef:
                  name: gitea-admin
                  key: username
            - name: PASSWORD
              valueFrom:
                secretKeyRef:
                  name: gitea-admin
                  key: password
            - name: EMAIL
              valueFrom:
                secretKeyRef:
                  name: gitea-admin
                  key: email
          command: ["/bin/sh","-c"]
          args:
            - >
              set -e;
              /usr/local/bin/gitea migrate --config /data/gitea/conf/app.ini;
              /usr/local/bin/gitea admin user create
              --admin --username "$USERNAME" --password "$PASSWORD" --email "$EMAIL"
              --config /data/gitea/conf/app.ini || echo "admin may already exist";
          volumeMounts:
            - name: data
              mountPath: /data
      containers:
        - name: gitea
          image: docker.gitea.com/gitea:1.24.5-rootless
          ports:
            - name: http
              containerPort: 3000
          env:
            # Tell Gitea where the persistent data is
            - name: GITEA_WORK_DIR
              value: /data
            - name: GITEA_APP_INI
              value: /data/gitea/conf/app.ini
          volumeMounts:
            - name: data
              mountPath: /data

---
apiVersion: v1
kind: Service
metadata:
  name: gitea
  namespace: gitea-demo
spec:
  selector:
    app: gitea
  ports:
    - name: http
      port: 3000
      targetPort: 3000
  type: ClusterIP
```

### Generate some data
1. Port forward the application to localhost: `kubectl -n gitea-demo port-forward svc/gitea 3000:3000`
1. Access Gitea by going to: `http://localhost:3000/`.
1. Log in with the username `admin` and password `ChangeMe123!`
1. Create a "hello-world" Git repo and write some data to its `README.md` file.
1. Clone the "hello-world" repo: `git clone http://localhost:3000/admin/hello-world.git`
1. Add an OS image of around 1GiB, then commit and push it.
1. The outcome should be like this:
   <img src="/img/blogs/20250902-k8s-backup-solutions-and-longhorn/gitea_hello_world.png" alt="Descriptive alt text">


## Backup
You'll back up the entire application stack and the PVC data by using CSI Snapshot Data Movement.

How it works under the hood:
1. Velero creates a CSI snapshot of the PVC.
1. Velero creates a temporary backup PVC from that snapshot.
1. A data-mover pod mounts the backup PVC (read-only) and uploads the data to S3.

Since you configured the Node Agent to use a linked-clone StorageClass, step 2 is nearly instant.

Run this command to create a backup:
```bash
velero backup create gitea-bkp \
  --include-namespaces gitea-demo \
  --snapshot-move-data \
  --wait
```
You should observe that the cloning happens very fast. Uploading the data to S3 may take some time.

Once the process is successful, you should see the following output:
```bash
➜  ~  velero backup get
NAME        STATUS      ERRORS   WARNINGS   CREATED                         EXPIRES   STORAGE LOCATION   SELECTOR
gitea-bkp   Completed   0        0          2025-09-03 19:56:14 -0700 PDT   29d       default            <none>
```


## Restore
1. To simulate a disaster case, delete the Gitea namespace so that the application stack is destroyed:
   ```bash
   kubectl delete ns gitea-demo
   ```
1. Restore the entire application stack:
   ```bash
   velero restore create gitea-restore --from-backup gitea-bkp --wait
   ```
1. Wait for the restoration to finish.
1. Port forward the application to localhost:
   ```bash
   kubectl -n gitea-demo port-forward svc/gitea 3000:3000
   ```
1. Access Gitea by going to `http://localhost:3000/`
1. Log in with the username `admin` and password `ChangeMe123!`
1. Verify that you see the same `README.md` file and the ubuntu server image.


## Restore to a different cluster and different storage provider
A very useful feature of Velero is its ability to restore PVC data into a PVC provisioned by a different storage provider. This enables you to migrate data to different clusters and storage providers.

1. Install Velero on the target cluster and point it to the same S3 bucket.
1. Map your source StorageClass to your target StorageClass with this ConfigMap (in the Velero namespace):
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  # any name can be used; Velero uses the labels (below)
  # to identify it rather than the name
  name: change-storage-class-config
  # must be in the velero namespace
  namespace: velero
  # the below labels should be used verbatim in your
  # ConfigMap.
  labels:
    # this value-less label identifies the ConfigMap as
    # config for a plugin (i.e. the built-in restore item action plugin)
    velero.io/plugin-config: ""
    # this label identifies the name and kind of plugin
    # that this ConfigMap is for.
    velero.io/change-storage-class: RestoreItemAction
data:
  # add 1+ key-value pairs here, where the key is the old
  # storage class name and the value is the new storage
  # class name.
  longhorn-v2-data-engine: local-path
```

In this example, PVCs that originally used `longhorn-v2-data-engine` will be restored using `local-path` on the destination cluster.


## Conclusion

You have now built an end-to-end, application-aware backup and restore workflow for a Longhorn v2-backed workload by using Velero and CSI Snapshot Data Movement. This solution provides several key benefits:

- **Fast backups**: Thanks to linked-clone for the temporary backup PVC.
- **Portable, deduplicated data**: Stored in S3 for cross-cluster disaster recovery.
- **Flexible restores**: Including remapping to a different StorageClass on a different cluster.

From here, consider adding scheduled backups with TTLs, namespace label selectors for fine-grained protection, and pre/post hooks for quiescing databases.
