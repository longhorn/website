---
title: Install with ArgoCD
weight: 12
---

## Prerequisites
- Your workstation: Install the [Argo CD CLI](https://argo-cd.readthedocs.io/en/stable/cli_installation/).
- Kubernetes cluster:
  - Ensure that each node fulfills the [installation requirements](../#installation-requirements).
  - Install [Argo CD](https://argo-cd.readthedocs.io/en/stable/).

    ```bash
    kubectl create namespace argocd
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/core-install.yaml
    ```
    Allow some time for the deployment of Argo CD components in the `argocd` namespace.

> Use [this script](https://github.com/longhorn/longhorn/blob/v{{< current-version >}}/scripts/environment_check.sh) to check the Longhorn environment for potential issues.

## Installing Longhorn

1. Log in to Argo CD.

    ```bash
    argocd login --core
    ```

1. Set the current namespace to `argocd`.

    ```bash
    kubectl config set-context --current --namespace=argocd
    ```

1. Create the Longhorn Application custom resource.

    ```bash
    cat > longhorn-application.yaml <<EOF
    apiVersion: argoproj.io/v1alpha1
    kind: Application
    metadata:
      name: longhorn
      namespace: argocd
    spec:
      project: default
      sources:
        - chart: longhorn
          repoURL: https://charts.longhorn.io/
          targetRevision: v1.6.0 # Replace with the Longhorn version you'd like to install or upgrade to
          helm:
            values: |
              helmPreUpgradeCheckerJob:
                enabled: false
      destination:
        server: https://kubernetes.default.svc
        namespace: longhorn-system
    EOF
    kubectl apply -f longhorn-application.yaml
    ```

1. Deploy Longhorn with the configured settings.

    ```bash
    argocd app sync longhorn
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
