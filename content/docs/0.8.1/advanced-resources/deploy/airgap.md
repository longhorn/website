---
title: Air Gap Installation
weight: 2
---

This section covers multiple ways to deploy Longhorn in an air gapped environment:

- [Using a Manifest File](#using-a-manifest-file)
- [Using a Helm Chart](#using-a-helm-chart)
- [Using the Longhorn Catalog App in Rancher](#using-the-longhorn-catalog-app-in-rancher)
- [Troubleshooting](#troubleshooting)

## Requirements

You will need to deploy Longhorn component images and Kubernetes CSI driver component images to your own Docker registry.

CSI driver components images, names and tags can be found [here.](../../../architecture/#kubernetes-csi-driver-images)

We recommend that image tags should not be manipulated. For more information, see [this section.](#recommendation-for-image-tags)

> **Note:** We recommend using a short registry URL due to a Kubernetes limitation on the length of pod metadata labels. For more information, refer to [this section.](./#longhorn-instance-manager-metadatalabels-must-be-no-more-than-63-characters)

## Using a Manifest File

1. Get the Longhorn Deployment manifest file:
        
    `wget https://raw.githubusercontent.com/longhorn/longhorn/master/deploy/longhorn.yaml`

2. Create the Longhorn namespace:

    `kubectl create namespace longhorn-system`

3. If the private registry requires authentication, create the `docker-registry` secret in the `longhorn-system` namespace:

    `kubectl -n longhorn-system create secret docker-registry <SECRET_NAME> --docker-server=<REGISTRY_URL> --docker-username=<REGISTRY_USER> --docker-password=<REGISTRY_PASSWORD>`

4. Add your secret name to the `longhorn-default-setting` ConfigMap:

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

5. Add your secret name `SECRET_NAME` to `imagePullSecrets.name` in the following resources:

    * `longhorn-driver-deployer` Deployment
    * `longhorn-manager` DaemonSet
    * `longhorn-ui` Deployment

    The following example shows how to add the secret to the `imagePullSecrets` in the `longhorn-ui` Deployment:

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

6. Apply the following modifications to the manifest file:

    6a. Modify the environment variables for the Kubernetes CSI driver components in the `longhorn-driver-deployer` Deployment to point to your private registry images:

      * CSI_ATTACHER_IMAGE
      * CSI_PROVISIONER_IMAGE
      * CSI_NODE_DRIVER_REGISTRAR_IMAGE
      * CSI_RESIZER_IMAGE

      Add the environment variables in this format:

          - name: CSI_ATTACHER_IMAGE
            value: <REGISTRY_URL>/csi-attacher:<CSI_ATTACHER_IMAGE_TAG>
          - name: CSI_PROVISIONER_IMAGE
            value: <REGISTRY_URL>/csi-provisioner:<CSI_PROVISIONER_IMAGE_TAG>
          - name: CSI_NODE_DRIVER_REGISTRAR_IMAGE
            value: <REGISTRY_URL>/csi-node-driver-registrar:<CSI_NODE_DRIVER_REGISTRAR_IMAGE_TAG>
          - name: CSI_RESIZER_IMAGE
            value: <REGISTRY_URL>/csi-resizer:<CSI_RESIZER_IMAGE_TAG>

    6b. Modify the Longhorn image URLs in the manifest file to point to your private registry images:

      | Original Image | Private Registry Image |
      |-----------------|-------------------------|
      | `longhornio/longhorn-manager` | `image: <REGISTRY_URL>/longhorn-manager:<LONGHORN_MANAGER_IMAGE_TAG>` |
      | `longhornio/longhorn-engine` | `image: <REGISTRY_URL>/longhorn-engine:<LONGHORN_ENGINE_IMAGE_TAG>` |
      | `longhornio/longhorn-instance-manager` | `image: <REGISTRY_URL>/longhorn-instance-manager:<LONGHORN_INSTANCE_MANAGER_IMAGE_TAG>` |
      | `longhornio/longhorn-ui` | `image: <REGISTRY_URL>/longhorn-ui:<LONGHORN_UI_IMAGE_TAG>` |

    The following example shows a private registry image for the Longhorn UI being added to the `longhorn-ui` Deployment:

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

5. Deploy Longhorn using the modified manifest file:
   
        kubectl apply -f longhorn.yaml


## Using a Helm Chart

1. Clone the Longhorn repo:

        git clone https://github.com/longhorn/longhorn.git

2. In `chart/values.yaml`, make the following changes:

    2a. Specify Longhorn images:

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

    2b. Specify the CSI Driver components images:

          csi:
            attacherImage: <REGISTRY_URL>/csi-attacher:<CSI_ATTACHER_IMAGE_TAG>
            provisionerImage: <REGISTRY_URL>/csi-provisioner:<CSI_PROVISIONER_IMAGE_TAG>
            driverRegistrarImage: <REGISTRY_URL>/csi-node-driver-registrar:<CSI_NODE_DRIVER_REGISTRAR_IMAGE_TAG>
            resizerImage: <REGISTRY_URL>/csi-resizer:<CSI_RESIZER_IMAGE_TAG>

    2c. Specify the registry secret Name, URL, and Credentials:

          defaultSettings:
            registrySecret: <SECRET_NAME>
          
          privateRegistry: 
              registryUrl: <REGISTRY_URL>
              registryUser: <REGISTRY_USER>
              registryPasswd: <REGISTRY_PASSWORD>

3. Install Longhorn:
    
    With Helm 2:

          helm install ./chart --name longhorn --namespace longhorn-system

    With Helm 3:

          kubectl create namespace longhorn-system
          helm install longhorn ./chart --namespace longhorn-system


## Using the Longhorn Catalog App in Rancher

In the `Longhorn Images Settings` section, specify:

* Longhorn Manager Image Name e.g. `<REGISTRY_URL>/longhorn-manager`
* Longhorn Manager Image Tag 
* Longhorn Engine Image Name e.g. `<REGISTRY_URL>/longhorn-engine`
* Longhorn Engine Image Tag 
* Longhorn UI Image Name e.g. `<REGISTRY_URL>/longhorn-ui` 
* Longhorn UI Image Tag 
* Longhorn Instance Manager Image Name e.g.  `<REGISTRY_URL>/longhorn-instance-manager`
* Longhorn Instance Manager Image Tag 

In the `Longhorn CSI Driver Setting` section, specify:

* Longhorn CSI Attacher Image    e.g.  `<REGISTRY_URL>/csi-attacher:<CSI_ATTACHER_IMAGE_TAG>`
* Longhorn CSI Provisioner Image   e.g. `<REGISTRY_URL>/csi-provisioner:<CSI_PROVISIONER_IMAGE_TAG>`
* Longhorn CSI Driver Registrar Image    e.g. `<REGISTRY_URL>/csi-node-driver-registrar:<CSI_NODE_DRIVER_REGISTRAR_IMAGE_TAG>`
* Longhorn CSI Driver Resizer Image    e.g. `<REGISTRY_URL>/csi-resizer:<CSI_RESIZER_IMAGE_TAG>`

In the `Longhorn Default Settings` section, specify:

*  Private registry secret 

In the `Private Registry Settings` section, specify:

*  Private registry URL 
*  Private registry user 
*  Private registry password 


## Troubleshooting

#### For Helm/Rancher installations, if the user forgot to submit a secret to authenticate to private registry, `longhorn-manager DaemonSet` will fail to create.


1. Create the Kubernetes secret:

    `kubectl -n longhorn-system create secret docker-registry <SECRET_NAME> --docker-server=<REGISTRY_URL> --docker-username=<REGISTRY_USER> --docker-password=<REGISTRY_PASSWORD>`

2. Create the `registry-secret` setting object manually:

    ```
    apiVersion: longhorn.io/v1beta1
    kind: Setting
    metadata:
      name: registry-secret
      namespace: longhorn-system
    value: <SECRET_NAME>
    ```
    

        kubectl apply -f registry-secret.yml


3. Delete Longhorn and re-install it again.

    With Helm 2:

        helm uninstall ./chart --name longhorn --namespace longhorn-system
        helm install ./chart --name longhorn --namespace longhorn-system

    With Helm 3:

        helm uninstall longhorn ./chart --namespace longhorn-system
        helm install longhorn ./chart --namespace longhorn-system

#### longhorn-driver-deployer error: Node is not support mount propagation
If longhorn-instance-manager image name is more than 63 characters long, it will fail to deploy, and longhorn-driver-deployer pod will be in `CrashLoopBackOff`.

Checking Longhorn driver deployer logs will report the following:

    time="2020-03-13T22:49:22Z" level=warning msg="Got an error when checking MountPropagation with node status, Node XXX is not support mount propagation"
    time="2020-03-13T22:49:22Z" level=fatal msg="Error deploying driver: CSI cannot be deployed because MountPropagation is not set: Node <NODE_NAME> is not support mount propagation"

The issue can be conformed by checking the Longhorn manager logs. You should be able to see the following logs:

    "Dropping Longhorn node longhorn-system/**NODE_NAME** out of the queue: fail to sync node for longhorn-system/**NODE_NAME**: 
    InstanceManager.longhorn.io \"instance-manager-e-605e9473\" is invalid: metadata.labels: Invalid value:
    \"**PRIVATE_REGISTRY_URL**-**PREFIX**-longhorn-instance-manager-v1_20200301\": **must be no more than 63 characters**"



#### Longhorn instance manager: metadata.labels must be no more than 63 characters

Using a long registry URL may cause Longhorn installation error.

Longhorn manager reports errors in the log when this happens:

    "instance-manager-e-xxxxxxxx" is invalid: metadata.labels: Invalid value: "<PRIVATE_REGISTRY_URL>-longhornio-longhorn-instance-manager-v1_20200301": must be no more than 63 characters

Longhorn instance manager pods have labels with the key `longhorn.io/instance-manager-image` and the value `REGISTRY_URL-USER-IMAGE_NAME-TAG`, e.g.:

    metadata:
      labels:
        longhorn.io/component: instance-manager
        longhorn.io/instance-manager-image: <PRIVATE_REGISTRY_URL>-longhornio-longhorn-instance-manager-v1_20200301
        longhorn.io/instance-manager-type: engine
        longhorn.io/node: <NODE_NAME>
      name: instance-manager-e-XXXXXXXX


It's a known Kubernetes limitation that label values should be no more than 63 characters [here.](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/#syntax-and-character-set)

##### Recommendation for Image Tags

It's highly recommended **not** to manipulate image tags, especially instance manager image tags such as `v1_20200301`, because we intentionally use the date to avoid associating it with a Longhorn version.

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