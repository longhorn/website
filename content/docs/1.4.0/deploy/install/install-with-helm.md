---
title: Install with Helm
weight: 9
---

In this section, you will learn how to install Longhorn with Helm.

### Prerequisites

- Each node in the Kubernetes cluster where Longhorn will be installed must fulfill [these requirements.](../#installation-requirements)
- Helm v2.0+ must be installed on your workstation.
  - 1. Refer to the official documentation for help installing Helm.
  - 2. If you're using a Helm version prior to version 3.0, you need to [install Tiller in your Kubernetes cluster with role-based access control (RBAC)](https://v2.helm.sh/docs/using_helm/#tiller-namespaces-and-rbac).

> [This script](https://github.com/longhorn/longhorn/blob/v{{< current-version >}}/scripts/environment_check.sh) can be used to check the Longhorn environment for potential issues.

### Installing Longhorn


> **Note**: The initial settings for Longhorn can be found in [customized using Helm options or by editing the deployment configuration file.](../../../advanced-resources/deploy/customizing-default-settings/#using-helm)


1. Add the Longhorn Helm repository:

    ```shell
   helm repo add longhorn https://charts.longhorn.io
    ```

2. Fetch the latest charts from the repository:

    ```shell
   helm repo update
    ```

3. Install Longhorn in the `longhorn-system` namespace.

    To install Longhorn with Helm 2, use the command:

    ```shell
    helm install longhorn/longhorn --name longhorn --namespace longhorn-system --version {{< current-version >}}
    ```

    To install Longhorn with Helm 3, use the commands:

    ```shell
    helm install longhorn longhorn/longhorn --namespace longhorn-system --create-namespace --version {{< current-version >}}
    ```

4. To confirm that the deployment succeeded, run:

    ```bash
    kubectl -n longhorn-system get pod
    ```
    
    The result should look like the following:

    ```bash
    NAME                                           READY   STATUS    RESTARTS   AGE
    longhorn-ui-b7c844b49-w25g5                    1/1     Running   0          2m41s
    longhorn-conversion-webhook-5dc58756b6-9d5w7   1/1     Running   0          2m41s
    longhorn-conversion-webhook-5dc58756b6-jp5fw   1/1     Running   0          2m41s
    longhorn-admission-webhook-8b7f74576-rbvft     1/1     Running   0          2m41s
    longhorn-admission-webhook-8b7f74576-pbxsv     1/1     Running   0          2m41s
    longhorn-manager-pzgsp                         1/1     Running   0          2m41s
    longhorn-driver-deployer-6bd59c9f76-lqczw      1/1     Running   0          2m41s
    longhorn-csi-plugin-mbwqz                      2/2     Running   0          100s
    csi-snapshotter-588457fcdf-22bqp               1/1     Running   0          100s
    csi-snapshotter-588457fcdf-2wd6g               1/1     Running   0          100s
    csi-provisioner-869bdc4b79-mzrwf               1/1     Running   0          101s
    csi-provisioner-869bdc4b79-klgfm               1/1     Running   0          101s
    csi-resizer-6d8cf5f99f-fd2ck                   1/1     Running   0          101s
    csi-provisioner-869bdc4b79-j46rx               1/1     Running   0          101s
    csi-snapshotter-588457fcdf-bvjdt               1/1     Running   0          100s
    csi-resizer-6d8cf5f99f-68cw7                   1/1     Running   0          101s
    csi-attacher-7bf4b7f996-df8v6                  1/1     Running   0          101s
    csi-attacher-7bf4b7f996-g9cwc                  1/1     Running   0          101s
    csi-attacher-7bf4b7f996-8l9sw                  1/1     Running   0          101s
    csi-resizer-6d8cf5f99f-smdjw                   1/1     Running   0          101s
    instance-manager-r-371b1b2e                    1/1     Running   0          114s
    instance-manager-e-7c5ac28d                    1/1     Running   0          114s
    engine-image-ei-df38d2e5-cv6nc                 1/1     Running   0          114s
    ```

5. To enable access to the Longhorn UI, you will need to set up an Ingress controller. Authentication to the Longhorn UI is not enabled by default. For information on creating an NGINX Ingress controller with basic authentication, refer to [this section.](../../accessing-the-ui/longhorn-ingress)

6. Access the Longhorn UI using [these steps.](../../accessing-the-ui)
