---
title: Install with Flux
weight: 11
---

## Prerequisites
- Your workstation: Install [Helm](https://helm.sh/docs/) v3.0 or later.
- Kubernetes cluster:
  - Ensure that each node fulfills the [installation requirements](../#installation-requirements).
  - [Install the Flux CLI](https://fluxcd.io/flux/installation/#install-the-flux-cli).
  - [Bootstrap Flux with GitHub](https://fluxcd.io/flux/installation/bootstrap/github/) using the Flux CLI.
    Run the following commands to export your GitHub personal access token (PAT) as an environment variable, deploy the Flux controllers on your cluster, and configure the controllers to sync the cluster state from the specified GitHub repository.

    ```bash
    export GITHUB_TOKEN=<gh-token>
    flux bootstrap github \
      --token-auth \
      --owner=<github_username> \
      --repository=<github_repo_name> \
      --branch=<branch_name> \
      --path=<folder_path_within_repo> \
      --personal
    ```

> Use [this script](https://github.com/longhorn/longhorn/blob/v{{< current-version >}}/scripts/environment_check.sh) to check the Longhorn environment for potential issues.

## Installing Longhorn

1. Create a HelmRepository custom resource (CR) that points to the Longhorn Helm chart URL.

    ```bash
    kubectl create ns longhorn-system
    flux create source helm longhorn-repo \
      --url=https://charts.longhorn.io \
      --namespace=longhorn-system \
      --export > helmrepo.yaml
    ```

1. Create a HelmRelease CR that references the HelmRepository and specifies the version of the Longhorn Helm chart to be installed.

    ```bash
    flux create helmrelease longhorn-release \
      --chart=longhorn \
      --source=HelmRepository/longhorn-repo \
      --chart-version=1.6.0 \
      --namespace=longhorn-system \
      --export > helmrelease.yaml
    ```

1. Verify that the HelmRelease CR was created and synced successfully.

    ```bash
    flux get helmrelease longhorn-release -n longhorn-system
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

## Continuous Operations via GitOps

You can commit and push exported manifests to your GitOps repository.

    ```bash
    git add helmrepo.yaml helmrelease.yaml
    git commit -m "Add HelmRepository and HelmRelease for Longhorn installation"
    git push origin <branch_name>
    ```

Afterwards, you can modify the HelmRelease and HelmRepository CRs by editing the YAML manifests in your GitOps repository. Flux automatically detects and applies the changes without requiring direct access to your Kubernetes cluster.
