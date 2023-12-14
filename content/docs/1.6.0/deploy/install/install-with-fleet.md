---
title: Install with Fleet
weight: 10
---

## Prerequisites
- Your workstation: Install [Helm](https://helm.sh/docs/) v3.0 or later.
- Kubernetes cluster:
  - Ensure that each node fulfills the [installation requirements](../#installation-requirements).
  - Install [Fleet](https://fleet.rancher.io/) using Helm.

    ```bash
    helm repo add fleet https://rancher.github.io/fleet-helm-charts/
    helm -n cattle-fleet-system install --create-namespace --wait fleet-crd fleet/fleet-crd
    helm -n cattle-fleet-system install --create-namespace --wait fleet fleet/fleet
    ```
    Allow some time for the deployment of Fleet components in the `cattle-fleet-system` namespace.

> Use [this script](https://github.com/longhorn/longhorn/blob/v{{< current-version >}}/scripts/environment_check.sh) to check the Longhorn environment for potential issues.

## Installing Longhorn

1. In your GitOps repository, create a [fleet.yaml](https://fleet.rancher.io/ref-fleet-yaml) file that includes the following:

    - Parameter for installing Longhorn in the `longhorn-system` namespace

    ```yaml
    defaultNamespace: longhorn-system
    ```

    - Parameters for [ignoring modified CRDs](https://fleet.rancher.io/bundle-diffs)

    ```yaml
    diff:
      comparePatches:
      - apiVersion: apiextensions.k8s.io/v1
        kind: CustomResourceDefinition
        name: engineimages.longhorn.io
        operations:
        - {"op": "replace", "path": "/status"}
      - apiVersion: apiextensions.k8s.io/v1
        kind: CustomResourceDefinition
        name: nodes.longhorn.io
        operations:
        - {"op": "replace", "path": "/status"}
      - apiVersion: apiextensions.k8s.io/v1
        kind: CustomResourceDefinition
        name: volumes.longhorn.io
        operations:
        - {"op": "replace", "path": "/status"}
    ```

    - Parameters for specifying the version of the Longhorn Helm chart to be installed

    ```yaml
    helm:
      repo: https://charts.longhorn.io
      chart: longhorn
      version: v1.6.0 # Replace with the Longhorn version you'd like to install or upgrade to
      releaseName: longhorn
    ```

    Example of a complete `fleet.yaml` file:

    ```yaml
    defaultNamespace: longhorn-system
    helm:
      repo: https://charts.longhorn.io
      chart: longhorn
      version: 1.6.0
      releaseName: longhorn
    diff:
      comparePatches:
      - apiVersion: apiextensions.k8s.io/v1
        kind: CustomResourceDefinition
        name: engineimages.longhorn.io
        operations:
        - {"op": "replace", "path": "/status"}
      - apiVersion: apiextensions.k8s.io/v1
        kind: CustomResourceDefinition
        name: nodes.longhorn.io
        operations:
        - {"op": "replace", "path": "/status"}
      - apiVersion: apiextensions.k8s.io/v1
        kind: CustomResourceDefinition
        name: volumes.longhorn.io
        operations:
        - {"op": "replace", "path": "/status"}
    ```

1. Create a GitRepo custom resource (CR) that points to your GitOps repository.

    ```bash
    cat > longhorn-gitrepo.yaml << "EOF"
    apiVersion: fleet.cattle.io/v1alpha1
    kind: GitRepo
    metadata:
      name: longhorn
      namespace: fleet-local
    spec:
      repo: https://github.com/your-username/your-gitops-repo.git
      revision: main
      paths:
      - .
    EOF
    ```

1. Apply the GitRepo CR.

    ```bash
    kubectl apply -f longhorn-gitrepo.yaml
    ```

1. Verify that the GitRepo CR was created and synced successfully.

    ```bash
    kubectl -n fleet-local get fleet -w
    ```

1. Verify that Longhorn was installed successfully.

    ```bash
    kubectl -n longhorn-system get pod
    ```

    Example of a successful Longhorn installation:

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

1. [Create an NGINX Ingress controller with basic authentication](../../accessing-the-ui/longhorn-ingress) to access the Longhorn UI. Authentication to the Longhorn UI is not enabled by default.

1. [Access the Longhorn UI](../../accessing-the-ui).
