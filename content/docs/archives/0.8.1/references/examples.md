---
title: Examples
weight: 5
---

For reference, this page provides examples of Kubernetes resources that use Longhorn storage.

- [Block volume](#block-volume)
- [CSI persistent volume](#csi-persistent-volume)
- [Deployment](#deployment)
- [Pod with PersistentVolumeClaim](#pod-with-persistentvolumeclaim)
- [Restore to file](#restore-to-file)
- [Simple Pod](#simple-pod)
- [Simple PersistentVolumeClaim](#simple-persistentvolumeclaim)
- [StatefulSet](#statefulset)
- [StorageClass](#storageclass)

### Block Volume


    apiVersion: v1
    kind: PersistentVolumeClaim
    metadata:
      name: longhorn-block-vol
    spec:
      accessModes:
        - ReadWriteOnce
      volumeMode: Block
      storageClassName: longhorn
      resources:
        requests:
          storage: 2Gi
    ---
    apiVersion: v1
    kind: Pod
    metadata:
      name: block-volume-test
      namespace: default
    spec:
      containers:
        - name: block-volume-test
          image: nginx:stable-alpine
          imagePullPolicy: IfNotPresent
          volumeDevices:
            - devicePath: /dev/longhorn/testblk
              name: block-vol
          ports:
            - containerPort: 80
      volumes:
        - name: block-vol
          persistentVolumeClaim:
            claimName: longhorn-block-vol



### CSI Persistent Volume

    apiVersion: v1
    kind: PersistentVolume
    metadata:
      name: longhorn-vol-pv
    spec:
      capacity:
        storage: 2Gi
      volumeMode: Filesystem
      accessModes:
        - ReadWriteOnce
      persistentVolumeReclaimPolicy: Delete
      storageClassName: longhorn
      csi:
        driver: driver.longhorn.io
        fsType: ext4
        volumeAttributes:
          numberOfReplicas: '3'
          staleReplicaTimeout: '2880'
        volumeHandle: existing-longhorn-volume
    ---
    apiVersion: v1
    kind: PersistentVolumeClaim
    metadata:
      name: longhorn-vol-pvc
    spec:
      accessModes:
        - ReadWriteOnce
      resources:
        requests:
          storage: 2Gi
      volumeName: longhorn-vol-pv
      storageClassName: longhorn
    ---
    apiVersion: v1
    kind: Pod
    metadata:
      name: volume-pv-test
      namespace: default
    spec:
      restartPolicy: Always
      containers:
      - name: volume-pv-test
        image: nginx:stable-alpine
        imagePullPolicy: IfNotPresent
        livenessProbe:
          exec:
            command:
              - ls
              - /data/lost+found
          initialDelaySeconds: 5
          periodSeconds: 5
        volumeMounts:
        - name: vol
          mountPath: /data
        ports:
        - containerPort: 80
      volumes:
      - name: vol
        persistentVolumeClaim:
          claimName: longhorn-vol-pvc


### Deployment


    apiVersion: v1
    kind: Service
    metadata:
      name: mysql
      labels:
        app: mysql
    spec:
      ports:
        - port: 3306
      selector:
        app: mysql
      clusterIP: None
    ---
    apiVersion: v1
    kind: PersistentVolumeClaim
    metadata:
      name: mysql-pvc
    spec:
      accessModes:
        - ReadWriteOnce
      storageClassName: longhorn
      resources:
        requests:
          storage: 2Gi
    ---
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: mysql
      labels:
        app: mysql
    spec:
      selector:
        matchLabels:
          app: mysql # has to match .spec.template.metadata.labels
      strategy:
        type: Recreate
      template:
        metadata:
          labels:
            app: mysql
        spec:
          restartPolicy: Always
          containers:
          - image: mysql:5.6
            name: mysql
            livenessProbe:
              exec:
                command:
                  - ls
                  - /var/lib/mysql/lost+found
              initialDelaySeconds: 5
              periodSeconds: 5
            env:
            - name: MYSQL_ROOT_PASSWORD
              value: changeme
            ports:
            - containerPort: 3306
              name: mysql
            volumeMounts:
            - name: mysql-volume
              mountPath: /var/lib/mysql
            env:
            - name: MYSQL_ROOT_PASSWORD
              value: "rancher"
          volumes:
          - name: mysql-volume
            persistentVolumeClaim:
              claimName: mysql-pvc


### Pod with PersistentVolumeClaim


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
    ---
    apiVersion: v1
    kind: Pod
    metadata:
      name: volume-test
      namespace: default
    spec:
      restartPolicy: Always
      containers:
      - name: volume-test
        image: nginx:stable-alpine
        imagePullPolicy: IfNotPresent
        livenessProbe:
          exec:
            command:
              - ls
              - /data/lost+found
          initialDelaySeconds: 5
          periodSeconds: 5
        volumeMounts:
        - name: volv
          mountPath: /data
        ports:
        - containerPort: 80
      volumes:
      - name: volv
        persistentVolumeClaim:
          claimName: longhorn-volv-pvc

### Restore to File

For more information about restoring to file, refer to [this section.](../../high-availability/recover-without-system)

    apiVersion: v1
    kind: Pod
    metadata:
      name: restore-to-file
      namespace: longhorn-system
    spec:
      nodeName: <NODE_NAME>
      containers:
      - name: restore-to-file
        command:
        # set restore-to-file arguments here
        - /bin/sh
        - -c
        - longhorn backup restore-to-file
          '<BACKUP_URL>'
          --output-file '/tmp/restore/<OUTPUT_FILE>'
          --output-format <OUTPUT_FORMAT>
        # the version of longhorn engine should be v0.4.1 or higher
        image: longhorn/longhorn-engine:v0.4.1
        imagePullPolicy: IfNotPresent
        securityContext:
          privileged: true
        volumeMounts:
        - name: disk-directory
          mountPath: /tmp/restore  # the argument <output-file> should be in this directory
        env:
        # set Backup Target Credential Secret here.
        - name: AWS_ACCESS_KEY_ID
          valueFrom:
            secretKeyRef:
              name: <S3_SECRET_NAME>
              key: AWS_ACCESS_KEY_ID
        - name: AWS_SECRET_ACCESS_KEY
          valueFrom:
            secretKeyRef:
              name: <S3_SECRET_NAME>
              key: AWS_SECRET_ACCESS_KEY
        - name: AWS_ENDPOINTS
          valueFrom:
            secretKeyRef:
              name: <S3_SECRET_NAME>
              key: AWS_ENDPOINTS
      volumes:
        # the output file can be found on this host path
        - name: disk-directory
          hostPath:
            path: /tmp/restore
      restartPolicy: Never


### Simple Pod


    apiVersion: v1
    kind: Pod
    metadata:
      name: longhorn-simple-pod
      namespace: default
    spec:
      restartPolicy: Always
      containers:
        - name: volume-test
          image: nginx:stable-alpine
          imagePullPolicy: IfNotPresent
          livenessProbe:
            exec:
              command:
                - ls
                - /data/lost+found
            initialDelaySeconds: 5
            periodSeconds: 5
          volumeMounts:
            - name: volv
              mountPath: /data
          ports:
            - containerPort: 80
      volumes:
        - name: volv
          persistentVolumeClaim:
            claimName: longhorn-simple-pvc



### Simple PersistentVolumeClaim


    apiVersion: v1
    kind: PersistentVolumeClaim
    metadata:
      name: longhorn-simple-pvc
    spec:
      accessModes:
        - ReadWriteOnce
      storageClassName: longhorn
      resources:
        requests:
          storage: 1Gi



### StatefulSet


    apiVersion: v1
    kind: Service
    metadata:
      name: nginx
      labels:
        app: nginx
    spec:
      ports:
      - port: 80
        name: web
      selector:
        app: nginx
      type: NodePort
    ---
    apiVersion: apps/v1
    kind: StatefulSet
    metadata:
      name: web
    spec:
      selector:
        matchLabels:
          app: nginx # has to match .spec.template.metadata.labels
      serviceName: "nginx"
      replicas: 2 # by default is 1
      template:
        metadata:
          labels:
            app: nginx # has to match .spec.selector.matchLabels
        spec:
          restartPolicy: Always
          terminationGracePeriodSeconds: 10
          containers:
          - name: nginx
            image: k8s.gcr.io/nginx-slim:0.8
            livenessProbe:
              exec:
                command:
                  - ls
                  - /usr/share/nginx/html/lost+found
              initialDelaySeconds: 5
              periodSeconds: 5
            ports:
            - containerPort: 80
              name: web
            volumeMounts:
            - name: www
              mountPath: /usr/share/nginx/html
      volumeClaimTemplates:
      - metadata:
          name: www
        spec:
          accessModes: [ "ReadWriteOnce" ]
          storageClassName: "longhorn"
          resources:
            requests:
              storage: 1Gi

### StorageClass

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
    #  recurringJobs: '[
    #   {
    #     "name":"snap", 
    #     "task":"snapshot", 
    #     "cron":"*/1 * * * *", 
    #     "retain":1
    #   },
    #   {
    #     "name":"backup", 
    #     "task":"backup", 
    #     "cron":"*/2 * * * *", 
    #     "retain":1,
    #     "labels": {
    #       "interval":"2m"
    #      }
    #   }
    #  ]'
