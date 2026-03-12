---
title: Install with Kubectl
description: Install Longhorn with the kubectl client.
weight: 8
---

## Prerequisites

Each node in the Kubernetes cluster where Longhorn will be installed must fulfill [these requirements.](../#installation-requirements)

[This script](https://github.com/longhorn/longhorn/blob/v{{< current-version >}}/scripts/environment_check.sh) can be used to check the Longhorn environment for potential issues.

The initial settings for Longhorn can be customized by [editing the deployment configuration file.](../../../advanced-resources/deploy/customizing-default-settings/#using-the-longhorn-deployment-yaml-file)

## Installing Longhorn

1. Install Longhorn on any Kubernetes cluster using this command:

    ```shell
    kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/v{{< current-version >}}/deploy/longhorn.yaml
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
    NAME                                                READY   STATUS    RESTARTS   AGE
    longhorn-ui-b7c844b49-w25g5                         1/1     Running   0          2m41s
    longhorn-manager-pzgsp                              1/1     Running   0          2m41s
    longhorn-driver-deployer-6bd59c9f76-lqczw           1/1     Running   0          2m41s
    longhorn-csi-plugin-mbwqz                           2/2     Running   0          100s
    csi-snapshotter-588457fcdf-22bqp                    1/1     Running   0          100s
    csi-snapshotter-588457fcdf-2wd6g                    1/1     Running   0          100s
    csi-provisioner-869bdc4b79-mzrwf                    1/1     Running   0          101s
    csi-provisioner-869bdc4b79-klgfm                    1/1     Running   0          101s
    csi-resizer-6d8cf5f99f-fd2ck                        1/1     Running   0          101s
    csi-provisioner-869bdc4b79-j46rx                    1/1     Running   0          101s
    csi-snapshotter-588457fcdf-bvjdt                    1/1     Running   0          100s
    csi-resizer-6d8cf5f99f-68cw7                        1/1     Running   0          101s
    csi-attacher-7bf4b7f996-df8v6                       1/1     Running   0          101s
    csi-attacher-7bf4b7f996-g9cwc                       1/1     Running   0          101s
    csi-attacher-7bf4b7f996-8l9sw                       1/1     Running   0          101s
    csi-resizer-6d8cf5f99f-smdjw                        1/1     Running   0          101s
    instance-manager-b34d5db1fe1e2d52bcfb308be3166cfc   1/1     Running   0          114s
    engine-image-ei-df38d2e5-cv6nc                      1/1     Running   0          114s
    ```
3. To enable access to the Longhorn UI, you will need to set up an Ingress controller. Authentication to the Longhorn UI is not enabled by default. For information on creating an NGINX Ingress controller with basic authentication, refer to [this section.](../../accessing-the-ui/longhorn-ingress)
4. Access the Longhorn UI using [these steps.](../../accessing-the-ui)

> **Note**:
> For Kubernetes < v1.25, if your cluster still enables Pod Security Policy admission controller, need to apply the [podsecuritypolicy.yaml](https://raw.githubusercontent.com/longhorn/longhorn/master/deploy/podsecuritypolicy.yaml) manifest in addition to applying the `longhorn.yaml` manifests.



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

#### ClusterRoleBinding: longhorn-bind

This connects the longhorn-role to the longhorn-service-account in the  longhorn-system namespace

#### CustomResourceDefinitions

The following CustomResourceDefinitions will be installed

- In longhorn.io
  - backingimagedatasources
  - backingimagemanagers
  - backingimages
  - backups
  - backuptargets
  - backupvolumes
  - engineimages
  - engines
  - instancemanagers
  - nodes
  - recurringjobs
  - replicas
  - settings
  - sharemanagers
  - volumes

#### Kubernetes API Objects

- A config map with the default settings
- The longhorn-manager DaemonSet
- The longhorn-backend service exposing the longhorn-manager DaemonSet internally to Kubernetes
- The longhorn-ui Deployment
- The longhorn-frontend service exposing the longhorn-ui internally to Kubernetes
- The longhorn-driver-deployer that deploys the CSI driver
- The longhorn StorageClass

