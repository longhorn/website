---
title: Air Gap Installation
weight: 2
---

## Requirements:
  - Deploy Longhorn Components images to your own registry.
  - Deploy Kuberntes CSI driver components images to your own registry.

#### Note:
  - A full list of all needed images is in [longhorn-images.txt](https://raw.githubusercontent.com/longhorn/longhorn/v1.0.1/deploy/longhorn-images.txt). First, download the images list by running:
    ```shell
    wget https://raw.githubusercontent.com/longhorn/longhorn/v1.0.1/deploy/longhorn-images.txt
    ```
  - We provide a script, [save-images.sh](https://raw.githubusercontent.com/longhorn/longhorn/v1.0.1/scripts/save-images.sh), to quickly pull the above `longhorn-images.txt` list. If you specify a `tar.gz` file name for flag `--images`, the script will save all images to the provided filename. In the example below, the script pulls and saves Longhorn images to the file `longhorn-images.tar.gz`. You then can copy the file to your air-gap environment. On the other hand, if you don't specify the file name, the script just pulls the list of images to your computer.
    ```shell
    wget https://raw.githubusercontent.com/longhorn/longhorn/v1.0.1/scripts/save-images.sh
    chmod +x save-images.sh
    ./save-images.sh --image-list longhorn-images.txt --images longhorn-images.tar.gz
    ```
  - We provide another script, [load-images.sh](https://raw.githubusercontent.com/longhorn/longhorn/v1.0.1/scripts/load-images.sh), to push Longhorn images to your private registry. If you specify a `tar.gz` file name for flag `--images`, the script loads images from the `tar` file and pushes them. Otherwise, it will find images in your local Docker and push them. In the example below, the script loads images from the file `longhorn-images.tar.gz` and pushes them to `<YOUR-PRIVATE-REGISTRY>`
    ```shell
    wget https://raw.githubusercontent.com/longhorn/longhorn/v1.0.1/scripts/load-images.sh
    chmod +x load-images.sh
    ./load-images.sh --image-list longhorn-images.txt --images longhorn-images.tar.gz --registry <YOUR-PRIVATE-REGISTRY>
    ```
  - For more options with using the scripts, see flag `--help`:
    ```shell
    ./save-images.sh --help
    ./load-images.sh --help
    ```


## Using manifest file.

1. Get Longhorn Deployment manifest file

    `wget https://raw.githubusercontent.com/longhorn/longhorn/master/deploy/longhorn.yaml`

2. Create Longhorn namespace

    `kubectl create namespace longhorn-system`


3. If private registry require authentication, Create `docker-registry` secret in `longhorn-system` namespace:

    `kubectl -n longhorn-system create secret docker-registry <SECRET_NAME> --docker-server=<REGISTRY_URL> --docker-username=<REGISTRY_USER> --docker-password=<REGISTRY_PASSWORD>`


    * Add your secret name to `longhorn-default-setting` ConfigMap

    ```
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: longhorn-default-setting
      namespace: longhorn-system
    data:
      default-setting.yaml: |-
        backup-target:
        backup-target-credential-secret:
        create-default-disk-labeled-nodes:
        default-data-path:
        replica-soft-anti-affinity:
        storage-over-provisioning-percentage:
        storage-minimal-available-percentage:
        upgrade-checker:
        default-replica-count:
        guaranteed-engine-cpu:
        default-longhorn-static-storage-class:
        backupstore-poll-interval:
        taint-toleration:
        registry-secret:  <SECRET_NAME>
    ```

    * Add your secret name  `SECRET_NAME` to `imagePullSecrets.name` in the following resources
      * `longhorn-driver-deployer` Deployment
      * `longhorn-manager` DaemonSet
      * `longhorn-ui` Deployment

      Example:
      ```
      apiVersion: apps/v1
      kind: Deployment
      metadata:
        labels:
          app: longhorn-ui
        name: longhorn-ui
        namespace: longhorn-system
      spec:
        replicas: 1
        selector:
          matchLabels:
            app: longhorn-ui
        template:
          metadata:
            labels:
              app: longhorn-ui
          spec:
            containers:
            - name: longhorn-ui
              image: longhornio/longhorn-ui:v0.8.0
              ports:
              - containerPort: 8000
              env:
                - name: LONGHORN_MANAGER_IP
                  value: "http://longhorn-backend:9500"
            imagePullSecrets:
            - name: <SECRET_NAME>                          ## Add SECRET_NAME here
            serviceAccountName: longhorn-service-account
      ```

4. Apply the following modifications to the manifest file

    * Modify Kubernetes CSI driver components environment variables in `longhorn-driver-deployer` Deployment point to your private registry images
      * CSI_ATTACHER_IMAGE
      * CSI_PROVISIONER_IMAGE
      * CSI_NODE_DRIVER_REGISTRAR_IMAGE
      * CSI_RESIZER_IMAGE

      ```
      - name: CSI_ATTACHER_IMAGE
        value: <REGISTRY_URL>/csi-attacher:<CSI_ATTACHER_IMAGE_TAG>
      - name: CSI_PROVISIONER_IMAGE
        value: <REGISTRY_URL>/csi-provisioner:<CSI_PROVISIONER_IMAGE_TAG>
      - name: CSI_NODE_DRIVER_REGISTRAR_IMAGE
        value: <REGISTRY_URL>/csi-node-driver-registrar:<CSI_NODE_DRIVER_REGISTRAR_IMAGE_TAG>
      - name: CSI_RESIZER_IMAGE
        value: <REGISTRY_URL>/csi-resizer:<CSI_RESIZER_IMAGE_TAG>
      ```

    * Modify Longhorn images to point to your private registry images
      * longhornio/longhorn-manager

        `image: <REGISTRY_URL>/longhorn-manager:<LONGHORN_MANAGER_IMAGE_TAG>`

      * longhornio/longhorn-engine

        `image: <REGISTRY_URL>/longhorn-engine:<LONGHORN_ENGINE_IMAGE_TAG>`

      * longhornio/longhorn-instance-manager

        `image: <REGISTRY_URL>/longhorn-instance-manager:<LONGHORN_INSTANCE_MANAGER_IMAGE_TAG>`

      * longhornio/longhorn-ui

        `image: <REGISTRY_URL>/longhorn-ui:<LONGHORN_UI_IMAGE_TAG>`

    Example:
      ```
      apiVersion: apps/v1
      kind: Deployment
      metadata:
        labels:
          app: longhorn-ui
        name: longhorn-ui
        namespace: longhorn-system
      spec:
        replicas: 1
        selector:
          matchLabels:
            app: longhorn-ui
        template:
          metadata:
            labels:
              app: longhorn-ui
          spec:
            containers:
            - name: longhorn-ui
              image: <REGISTRY_URL>/longhorn-ui:<LONGHORN_UI_IMAGE_TAG>   ## Add image name and tag here
              ports:
              - containerPort: 8000
              env:
                - name: LONGHORN_MANAGER_IP
                  value: "http://longhorn-backend:9500"
            imagePullSecrets:
            - name: <SECRET_NAME>
            serviceAccountName: longhorn-service-account
      ```

5. Deploy Longhorn using modified manifest file
   `kubectl apply -f longhorn.yaml`


## Using Helm Chart
1. Clone longhorn repo

    `git clone https://github.com/longhorn/longhorn.git`

2. In `chart/values.yaml`

* Specify Longhorn images:

    ```
    image:
      longhorn:
        engine: <REGISTRY_URL>/longhorn-engine
        engineTag: <LONGHORN_ENGINE_IMAGE_TAG>
        manager: <REGISTRY_URL>/longhorn-manager
        managerTag: LONGHORN_MANAGER_IMAGE_TAG<>
        ui: <REGISTRY_URL>/longhorn-ui
        uiTag: <LONGHORN_UI_IMAGE_TAG>
        instanceManager: <REGISTRY_URL>/longhorn-instance-manager
        instanceManagerTag: <LONGHORN_INSTANCE_MANAGER_IMAGE_TAG>
    ```


* Specify CSI Driver components images:

    ```
    csi:
      attacherImage: <REGISTRY_URL>/csi-attacher:<CSI_ATTACHER_IMAGE_TAG>
      provisionerImage: <REGISTRY_URL>/csi-provisioner:<CSI_PROVISIONER_IMAGE_TAG>
      driverRegistrarImage: <REGISTRY_URL>/csi-node-driver-registrar:<CSI_NODE_DRIVER_REGISTRAR_IMAGE_TAG>
      resizerImage: <REGISTRY_URL>/csi-resizer:<CSI_RESIZER_IMAGE_TAG>
    ```


* Specify registry secret Name, URL, and Credentials:

    ```
    defaultSettings:
      registrySecret: <SECRET_NAME>

    privateRegistry:
        registryUrl: <REGISTRY_URL>
        registryUser: <REGISTRY_USER>
        registryPasswd: <REGISTRY_PASSWORD>
    ```

3. Install Longhorn
    * **Helm2**

      `helm install ./chart --name longhorn --namespace longhorn-system`

    * **Helm3**

      `kubectl create namespace longhorn-system`

      `helm install longhorn ./chart --namespace longhorn-system`


## Using Rancher App

  * In `Longhorn Images Settings` section specify
    * Longhorn Manager Image Name     e.g. `<REGISTRY_URL>/longhorn-manager`
    * Longhorn Manager Image Tag
    * Longhorn Engine Image Name    e.g. `<REGISTRY_URL>/longhorn-engine`
    * Longhorn Engine Image Tag
    * Longhorn UI Image Name    e.g. `<REGISTRY_URL>/longhorn-ui`
    * Longhorn UI Image Tag
    * Longhorn Instance Manager Image Name    e.g.  `<REGISTRY_URL>/longhorn-instance-manager`
    * Longhorn Instance Manager Image Tag

  * In `Longhorn CSI Driver Setting` section specify
    * Longhorn CSI Attacher Image    e.g.  `<REGISTRY_URL>/csi-attacher:<CSI_ATTACHER_IMAGE_TAG>`
    * Longhorn CSI Provisioner Image   e.g. `<REGISTRY_URL>/csi-provisioner:<CSI_PROVISIONER_IMAGE_TAG>`
    * Longhorn CSI Driver Registrar Image    e.g. `<REGISTRY_URL>/csi-node-driver-registrar:<CSI_NODE_DRIVER_REGISTRAR_IMAGE_TAG>`
    * Longhorn CSI Driver Resizer Image    e.g. `<REGISTRY_URL>/csi-resizer:<CSI_RESIZER_IMAGE_TAG>`

  * In `Longhorn Default Settings` secton specify
    *  Private registry secret

  * In `Private Registry Settings` secton specify
    *  Private registry URL
    *  Private registry user
    *  Private registry password


## Troubleshooting

#### For Helm/Rancher installation, if user forgot to submit a secret to authenticate to private registry, `longhorn-manager DaemonSet` will fail to create.


1. Create the Kubernetes secret

    `kubectl -n longhorn-system create secret docker-registry <SECRET_NAME> --docker-server=<REGISTRY_URL> --docker-username=<REGISTRY_USER> --docker-password=<REGISTRY_PASSWORD>`


2. Create `registry-secret` setting object manually.

    ```
    apiVersion: longhorn.io/v1beta1
    kind: Setting
    metadata:
      name: registry-secret
      namespace: longhorn-system
    value: <SECRET_NAME>
    ```

    `kubectl apply -f registry-secret.yml`


3. Delete Longhorn and re-install it again.

    * **Helm2**

      `helm uninstall ./chart --name longhorn --namespace longhorn-system`

      `helm install ./chart --name longhorn --namespace longhorn-system`

    * **Helm3**

      `helm uninstall longhorn ./chart --namespace longhorn-system`

      `helm install longhorn ./chart --namespace longhorn-system`

## Recommendation:
It's highly recommended not to manipulate image tags, especially instance manager image tags such as v1_20200301, because we intentionally use the date to avoid associating it with a Longhorn version.

e.g
- Longhorn components images
  - longhorn-instance-manager: `hub.example.com/lh/ins-mgr:v1_20200301`
  - longhorn-manager: `hub.example.com/lh/mgr:v0.8.1`
  - longhorn-engine: `hub.example.com/lh/eng:v0.8.1`
  - longhorn-ui: `hub.examples.com/lh/ui:v0.8.1`

- Kubernetes CSI images
  - CSI Attacher: `hub.example.com/csi/attacher:v2.0.0`
  - CSI Provisioner: `hub.example.com/csi/provisioner:v1.4.0`
  - CSI Node Driver Registrar: `hub.example.com/csi/node-driver-reg:v1.2.0`
  - CSI Resizer: `hub.example.com/csi/resizer:v0.3.0`
