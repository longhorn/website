---
title: Install With Kubectl
description: Install Longhorn with the kubectl client.
weight: 8
---

## Prerequisites

Each node in the Kubernetes cluster where Longhorn will be installed must fulfill [these requirements.](../#installation-requirements)

[This script](https://github.com/longhorn/longhorn/blob/master/scripts/environment_check.sh) can be used to check the Longhorn environment for potential issues.

The initial settings for Longhorn can be customized by [editing the deployment configuration file.](../../../advanced-resources/deploy/customizing-default-settings/#using-the-longhorn-deployment-yaml-file)

## Installing Longhorn

1. Install Longhorn on any Kubernetes cluster using this command:

    ```shell
    kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/master/deploy/longhorn.yaml
    ```

    One way to monitor the progress of the installation is to watch pods being created in the `longhorn-system` namespace:

    ```shell
    kubectl get pods \
    --namespace longhorn-system \
    --watch
    ```

2. Check that the deployment was successful:

    ```shell
    $ kubectl -n longhorn-system get pod
    NAME                                        READY     STATUS    RESTARTS   AGE
    csi-attacher-6fdc77c485-8wlpg               1/1       Running   0          9d
    csi-attacher-6fdc77c485-psqlr               1/1       Running   0          9d
    csi-attacher-6fdc77c485-wkn69               1/1       Running   0          9d
    csi-provisioner-78f7db7d6d-rj9pr            1/1       Running   0          9d
    csi-provisioner-78f7db7d6d-sgm6w            1/1       Running   0          9d
    csi-provisioner-78f7db7d6d-vnjww            1/1       Running   0          9d
    engine-image-ei-6e2b0e32-2p9nk              1/1       Running   0          9d
    engine-image-ei-6e2b0e32-s8ggt              1/1       Running   0          9d
    engine-image-ei-6e2b0e32-wgkj5              1/1       Running   0          9d
    longhorn-csi-plugin-g8r4b                   2/2       Running   0          9d
    longhorn-csi-plugin-kbxrl                   2/2       Running   0          9d
    longhorn-csi-plugin-wv6sb                   2/2       Running   0          9d
    longhorn-driver-deployer-788984b49c-zzk7b   1/1       Running   0          9d
    longhorn-manager-nr5rs                      1/1       Running   0          9d
    longhorn-manager-rd4k5                      1/1       Running   0          9d
    longhorn-manager-snb9t                      1/1       Running   0          9d
    longhorn-ui-67b9b6887f-n7x9q                1/1       Running   0          9d
    ```
3. To enable access to the Longhorn UI, you will need to set up an Ingress controller. Authentication to the Longhorn UI is not enabled by default. For information on creating an NGINX Ingress controller with basic authentication, refer to [this section.](../../accessing-the-ui/longhorn-ingress)
4. Access the Longhorn UI using [these steps.](../../accessing-the-ui)




### List of Deployed Resources


The following items will be deployed to Kubernetes:

#### Namespace: longhorn-system

All Longhorn bits will be scoped to this namespace.

#### ServiceAccount: longhorn-service-account

Service account is created in the longhorn-system namespace.

#### ClusterRole: longhorn-role

This role will have access to:
  - In apiextension.k8s.io (All verbs)
    - customresourcedefinitions
  - In core (All verbs)
    - pods
      - /logs
    - events
    - persistentVolumes
    - persistentVolumeClaims
      - /status
    - nodes
    - proxy/nodes
    - secrets
    - services
    - endpoints
    - configMaps
  - In core
    - namespaces (get, list)
  - In apps (All Verbs)
    - daemonsets
    - statefulSets
    - deployments
  - In batch (All Verbs)
    - jobs
    - cronjobs
  - In storage.k8s.io (All verbs)
    - storageclasses
    - volumeattachments
    - csinodes
    - csidrivers
  - In coordination.k8s.io
    - leases
  - In longhorn.rancher.io (All verbs, deprecated after v0.7.0)
    - volumes
    - engines
    - replicas
    - settings
    - engineimages
    - nodes
    - instancemanagers

#### ClusterRoleBinding: longhorn-bind

This connects the longhorn-role to the longhorn-service-account in the  longhorn-system namespace

#### CustomResourceDefinitions

The following CustomResourceDefinitions will be installed 

- In longhorn.io
  - engines
  - replicas
  - settings
  - volumes
  - engineimages
  - nodes
  - instancemanagers

#### Kubernetes API Objects

- A config map with the default settings
- The longhorn-manager DaemonSet
- The longhorn-backend service exposing the longhorn-manager DaemonSet internally to Kubernetes
- The longhorn-ui Deployment
- The longhorn-frontend service exposing the longhorn-ui internally to Kubernetes
- The longhorn-driver-deployer that deploys the CSI driver 
- The longhorn StorageClass

