---
title: Install with Helm
weight: 9
---

In this section, you'll learn how to install Longhorn with Helm.

### Prerequisites

- Each node in the Kubernetes cluster where Longhorn will be installed must fulfill [these requirements.](../#installation-requirements)
- Helm v2.0+ must be installed on your workstation.

[This script](https://github.com/longhorn/longhorn/blob/master/scripts/environment_check.sh) can be used to check the Longhorn environment for potential issues.

The initial settings for Longhorn can be [customized using Helm options or by editing the deployment configuration file.](../../../advanced-resources/deploy/customizing-default-settings/#using-helm)

#### Notes on Installing Helm

For help installing Helm, refer to the [official documentation.](https://helm.sh/docs/intro/install/)

If you're using a Helm version prior to version 3.0, you need to [install Tiller in your Kubernetes cluster with role-based access control (RBAC)](https://v2.helm.sh/docs/using_helm/#tiller-namespaces-and-rbac).

### Installing Longhorn

1. Add the Longhorn Helm repository:

    ```shell
   helm repo add longhorn https://charts.longhorn.io
    ```

2. Fetch the latest charts from the repository:

    ```shell
   helm repo update
    ```

3. Install Longhorn in the `longhorn-system` namespace.
    To install Longhorn with Helm 2, use this command:

    ```shell
    helm install longhorn/longhorn --name longhorn --namespace longhorn-system
    ```

    To install Longhorn with Helm 3, use these commands:

    ```shell
    kubectl create namespace longhorn-system
    helm install longhorn longhorn/longhorn --namespace longhorn-system
    ```

4. To confirm that the deployment succeeded, run:

    ```bash
    kubectl -n longhorn-system get pod
    ```
    The result should look like the following:

    ```bash
    NAME                                        READY   STATUS              RESTARTS   AGE
    compatible-csi-attacher-d9fb48bcf-2rzmb     1/1     Running             0          8m58s
    csi-attacher-78bf9b9898-grn2c               1/1     Running             0          32s
    csi-attacher-78bf9b9898-lfzvq               1/1     Running             0          8m59s
    csi-attacher-78bf9b9898-r64sv               1/1     Running             0          33s
    csi-provisioner-8599d5bf97-c8r79            1/1     Running             0          33s
    csi-provisioner-8599d5bf97-fc5pz            1/1     Running             0          33s
    csi-provisioner-8599d5bf97-p9psl            1/1     Running             0          8m59s
    csi-resizer-586665f745-b7p6h                1/1     Running             0          8m59s
    csi-resizer-586665f745-kgdxs                1/1     Running             0          33s
    csi-resizer-586665f745-vsvvq                1/1     Running             0          33s
    engine-image-ei-e10d6bf5-pv2s6              1/1     Running             0          9m30s
    instance-manager-e-379373af                 1/1     Running             0          8m41s
    instance-manager-r-101f13ba                 1/1     Running             0          8m40s
    longhorn-csi-plugin-7v2dc                   4/4     Running             0          8m59s
    longhorn-driver-deployer-775897bdf6-k4sfd   1/1     Running             0          10m
    longhorn-manager-79xgj                      1/1     Running             0          9m50s
    longhorn-ui-9fbb5445-httqf                  0/1     Running             0          33s
    ```

4. To enable access to the Longhorn UI, you will need to set up an Ingress controller. Authentication to the Longhorn UI is not enabled by default. For information on creating an NGINX Ingress controller with basic authentication, refer to [this section.](../../accessing-the-ui/longhorn-ingress)
5. Access the Longhorn UI using [these steps.](../../accessing-the-ui)
