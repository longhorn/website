---
title: Install with Helm
weight: 9
---

In this section, you will learn how to install Longhorn with Helm.

### Prerequisites

- Kubernetes cluster: Ensure that each node fulfills the [installation requirements](../#installation-requirements).
- Your workstation: Install [Helm](https://helm.sh/docs/) v3.0 or later.

> [This script](https://github.com/longhorn/longhorn/blob/v{{< current-version >}}/scripts/environment_check.sh) can be used to check the Longhorn environment for potential issues.

### Installing Longhorn


> **Note**:
> * The initial settings for Longhorn can be found in [customized using Helm options or by editing the deployment configuration file.](../../../advanced-resources/deploy/customizing-default-settings/#using-helm)
> * For Kubernetes < v1.25, if your cluster still enables Pod Security Policy admission controller, set the helm value `enablePSP` to `true` to install `longhorn-psp` PodSecurityPolicy resource which allows privileged Longhorn pods to start.


1. Add the Longhorn Helm repository:

    ```shell
   helm repo add longhorn https://charts.longhorn.io
    ```

2. Fetch the latest charts from the repository:

    ```shell
   helm repo update
    ```

3. Install Longhorn in the `longhorn-system` namespace.

    ```shell
    helm install longhorn longhorn/longhorn --namespace longhorn-system --create-namespace --version {{< current-version >}}
    ```

4. To confirm that the deployment succeeded, run:

    ```bash
    kubectl -n longhorn-system get pod
    ```

    The result should look like the following:

    ```bash
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

5. To enable access to the Longhorn UI, you will need to set up an Ingress controller. Authentication to the Longhorn UI is not enabled by default. For information on creating an NGINX Ingress controller with basic authentication, refer to [this section.](../../accessing-the-ui/longhorn-ingress)

6. Access the Longhorn UI using [these steps.](../../accessing-the-ui)
