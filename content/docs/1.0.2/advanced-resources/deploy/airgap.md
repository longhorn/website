---
title: Air Gap Installation
weight: 2
--- 

Longhorn can be installed in an air gapped environment by using a manifest file, a Helm chart, or the Rancher UI.

- [Requirements](#requirements)
- [Using a Manifest File](#using-a-manifest-file)
- [Using a Helm chart](#using-a-helm-chart)
- [Using a Rancher app](#using-a-rancher-app)
- [Troubleshooting](#troubleshooting)

## Requirements
  - Deploy Longhorn Components images to your own registry.
  - Deploy Kubernetes CSI driver components images to your own registry.

#### Note:
  - A full list of all needed images is in [longhorn-images.txt](https://raw.githubusercontent.com/longhorn/longhorn/v1.0.2/deploy/longhorn-images.txt). First, download the images list by running:
    ```shell
    wget https://raw.githubusercontent.com/longhorn/longhorn/v1.0.2/deploy/longhorn-images.txt
    ```
  - We provide a script, [save-images.sh](https://raw.githubusercontent.com/longhorn/longhorn/v1.0.2/scripts/save-images.sh), to quickly pull the above `longhorn-images.txt` list. If you specify a `tar.gz` file name for flag `--images`, the script will save all images to the provided filename. In the example below, the script pulls and saves Longhorn images to the file `longhorn-images.tar.gz`. You then can copy the file to your air-gap environment. On the other hand, if you don't specify the file name, the script just pulls the list of images to your computer.
    ```shell
    wget https://raw.githubusercontent.com/longhorn/longhorn/v1.0.2/scripts/save-images.sh
    chmod +x save-images.sh
    ./save-images.sh --image-list longhorn-images.txt --images longhorn-images.tar.gz
    ```
  - We provide another script, [load-images.sh](https://raw.githubusercontent.com/longhorn/longhorn/v1.0.2/scripts/load-images.sh), to push Longhorn images to your private registry. If you specify a `tar.gz` file name for flag `--images`, the script loads images from the `tar` file and pushes them. Otherwise, it will find images in your local Docker and push them. In the example below, the script loads images from the file `longhorn-images.tar.gz` and pushes them to `<YOUR-PRIVATE-REGISTRY>`
    ```shell
    wget https://raw.githubusercontent.com/longhorn/longhorn/v1.0.2/scripts/load-images.sh
    chmod +x load-images.sh
    ./load-images.sh --image-list longhorn-images.txt --images longhorn-images.tar.gz --registry <YOUR-PRIVATE-REGISTRY>
    ```
  - For more options with using the scripts, see flag `--help`:
    ```shell
    ./save-images.sh --help
    ./load-images.sh --help
    ```

## Using a Manifest File

1. Get Longhorn Deployment manifest file

    `wget https://raw.githubusercontent.com/longhorn/longhorn/master/deploy/longhorn.yaml`

2. Create Longhorn namespace

    `kubectl create namespace longhorn-system`


3. If private registry require authentication, Create `docker-registry` secret in `longhorn-system` namespace:

    `kubectl -n longhorn-system create secret docker-registry <SECRET_NAME> --docker-server=<REGISTRY_URL> --docker-username=<REGISTRY_USER> --docker-password=<REGISTRY_PASSWORD>`


    * Add your secret name to `longhorn-default-setting` ConfigMap

      ```yaml
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
      ```yaml
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

      ```yaml
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
      ```yaml
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

## Using a Helm Chart

In v1.0.2, Longhorn automatically adds <REGISTRY_URL> prefix to images. You simply need to set the registryUrl parameters to pull images from your private registry.

> **Note:** Once you set registryUrl to your private registry, Longhorn tries to pull images from the registry exclusively. Make sure all Longhorn components' images are in the registry otherwise Longhorn will fail to pull images.

### Use default image name

If you keep the images' names as recommended [here](./#recommendation), you only need to do the following steps:

1. Clone the Longhorn repo:

    `git clone https://github.com/longhorn/longhorn.git`

2. In `chart/values.yaml`

    * Specify `Private registry URL`. If the registry requires authentication, specify `Private registry user`, `Private registry password`, and `Private registry secret`:

      ```yaml
      defaultSettings:
        registrySecret: <SECRET_NAME>

      privateRegistry:
          registryUrl: <REGISTRY_URL>
          registryUser: <REGISTRY_USER>
          registryPasswd: <REGISTRY_PASSWORD>
      ```

### Use custom image name

If you want to use custom images' names, you can use the following steps:

1. Clone longhorn repo

    `git clone https://github.com/longhorn/longhorn.git`

2. In `chart/values.yaml`

    > **Note:** Do not include the private registry prefix, it will be added automatically. e.g: if your image is `example.com/username/longhorn-manager`, use `username/longhorn-manager` in the following charts.

    - Specify Longhorn images and tag:

        ```yaml
        image:
          longhorn:
            engine: longhornio/longhorn-engine
            engineTag: <LONGHORN_ENGINE_IMAGE_TAG>
            manager: longhornio/longhorn-manager
            managerTag: LONGHORN_MANAGER_IMAGE_TAG<>
            ui: longhornio/longhorn-ui
            uiTag: <LONGHORN_UI_IMAGE_TAG>
            instanceManager: longhornio/longhorn-instance-manager
            instanceManagerTag: <LONGHORN_INSTANCE_MANAGER_IMAGE_TAG>
        ```

    - Specify CSI Driver components images and tag:

        ```yaml
        csi:
          attacherImage: longhornio/csi-attacher
          attacherImageTag: <CSI_ATTACHER_IMAGE_TAG>
          provisionerImage: longhornio/csi-provisioner
          provisionerImageTag: <CSI_PROVISIONER_IMAGE_TAG>
          driverRegistrarImage: longhornio/csi-node-driver-registrar
          nodeDriverRegistrarImageTag: <CSI_NODE_DRIVER_REGISTRAR_IMAGE_TAG>
          resizerImage: longhornio/csi-resizer
          resizerImageTag: <CSI_RESIZER_IMAGE_TAG>
        ```

    - Specify `Private registry URL`. If the registry requires authentication, specify `Private registry user`, `Private registry password`, and `Private registry secret`:

        ```yaml
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

## Using a Rancher App

### Use default image name

If you keep the images' names as recommended [here](./#recommendation), you only need to do the following steps:

- In the `Longhorn Default Settings` section, click **Customize Default Setting** and specify the Private registry secret.
- In the `Private Registry Settings` section specify:
   - Private registry URL
   - Private registry user
   - Private registry password

  ![images](/img/screenshots/airgap-deploy/app-default-images.png)

> The `Private registry secret` must be specified in the default settings so that Longhorn can create a secret under the name. The process for setting up the private registry will be fixed to be less confusing, but not in the v1.0.2 release. More detail is at [this comment.](https://github.com/longhorn/longhorn/issues/1670#issuecomment-670723484)

### Use custom image name

- If you want to use custom images' names, you can set `Use Default Images` to `False` and specify images' names.

  > **Note:** Do not include the private registry prefix, it will be added automatically. e.g: if your image is `example.com/username/longhorn-manager`, use `username/longhorn-manager` in the following charts.

  ![images](/img/screenshots/airgap-deploy/app-custom-images.png)

- Specify `Private registry URL`. If the registry requires authentication, specify `Private registry user`, `Private registry password`, and `Private registry secret`:

  ![images](/img/screenshots/airgap-deploy/app-custom-images-reg.png)

> The `Private registry secret` must be specified in the default settings so that Longhorn can create a secret under the name. The process for setting up the private registry will be fixed to be less confusing, but not in the v1.0.2 release. More detail is at [this comment.](https://github.com/longhorn/longhorn/issues/1670#issuecomment-670723484)

## Troubleshooting

#### For Helm/Rancher installation, if user forgot to submit a secret to authenticate to private registry, `longhorn-manager DaemonSet` will fail to create.


1. Create the Kubernetes secret

    `kubectl -n longhorn-system create secret docker-registry <SECRET_NAME> --docker-server=<REGISTRY_URL> --docker-username=<REGISTRY_USER> --docker-password=<REGISTRY_PASSWORD>`


2. Create `registry-secret` setting object manually.

    ```yaml
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

The images of Longhorn's components are hosted in Dockerhub under the `longhornio` account. For example, `longhornio/longhorn-manager:v1.0.2`. It's recommended to keep the account name, `longhornio`, the same when you push the images to your private registry. This helps avoid unnecessary configuration issues.
