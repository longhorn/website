---
title: Install with Helm Controller
weight: 10
---

In this section, you will learn how to install Longhorn with the HelmChart controller built into RKE2 and K3s.

### Prerequisites

- Kubernetes cluster: Ensure that each node fulfills the [installation requirements](../#installation-requirements).  Cluster should be running RKE2 or K3s.

> [Longhorn Command Line Tool](../../../advanced-resources/longhornctl/) can be used to check the Longhorn environment for potential issues.

### Installing Longhorn


> **Note**:
> * The initial settings for Longhorn can be [customized using Helm options or by editing the deployment configuration file.](../../../advanced-resources/deploy/customizing-default-settings/#using-helm)
> * For Kubernetes < v1.25, if your cluster still enables Pod Security Policy admission controller, set the helm value `enablePSP` to `true` to install `longhorn-psp` PodSecurityPolicy resource which allows privileged Longhorn pods to start.


1. Create a HelmChart yaml file similar to this:

    ```yaml
   apiVersion: helm.cattle.io/v1
    kind: HelmChart
    metadata:
      annotations:
        helmcharts.cattle.io/managed-by: helm-controller
      finalizers:
      - wrangler.cattle.io/on-helm-chart-remove
      generation: 1
      name: longhorn-install
      namespace: default
    spec:
      version: v{{< current-version >}}
      chart: longhorn
      repo: https://charts.longhorn.io
      failurePolicy: abort
      targetNamespace: longhorn-system
      createNamespace: true

    ```

    > **IMPORTANT!** Ensure that `spec.failurePolicy` is set to "abort".  The only other value is the default: "reinstall", which performs an uninstall of Longhorn.  With "abort", it retries periodically, giving the user a chance to fix the problem.

    > **Note:** Rather than specify the repo, version, and chart name, the yaml can also use an image of the charts themselves:
    ```yaml
    spec:
      chartContent:  <tarball of chart directory | base64 -w 0>
    ```
    > For full details see the HelmChart controller docs:  https://docs.rke2.io/helm or https://docs.k3s.io/helm.

2. Apply it to create the HelmChart CR and an installation job:

    ```shell
    $ kubectl apply -f helmchart_repo_install.yaml
    helmchart.helm.cattle.io/longhorn-install created

    ```

    > **Note:** Deleting the helmchart CR will initiate an uninstall of Longhorn.

3. To show the created resources:

    ```shell
    $ kubectl get jobs
    NAME                            COMPLETIONS   DURATION   AGE
    helm-install-longhorn-install   0/1           8s         8s

    $ kubectl get pods
    NAME                                  READY   STATUS      RESTARTS   AGE
    helm-install-longhorn-install-lngm8   0/1     Completed   0          25s

    $ kubectl get helmcharts
    NAME               JOB                     CHART      TARGETNAMESPACE   VERSION   REPO                         HELMVERSION   BOOTSTRAP
    longhorn-install   helm-install-longhorn   longhorn   longhorn-system   v{{< current-version >}}    https://charts.longhorn.io

    ```

4. To confirm that the deployment succeeded, run:

    ```bash
    kubectl -n longhorn-system get pod
    ```

    The result should look like the following:

    ```bash
    NAME                                                READY   STATUS    RESTARTS      AGE
    csi-attacher-85c7684cfd-67kqc                       1/1     Running   0             29m
    csi-attacher-85c7684cfd-jbddj                       1/1     Running   0             29m
    csi-attacher-85c7684cfd-t85bw                       1/1     Running   0             29m
    csi-provisioner-68cdb8b96-46d9q                     1/1     Running   0             29m
    csi-provisioner-68cdb8b96-dgf5f                     1/1     Running   0             29m
    csi-provisioner-68cdb8b96-mh8q7                     1/1     Running   0             29m
    csi-resizer-86dd765b9-d27cs                         1/1     Running   0             29m
    csi-resizer-86dd765b9-scqxm                         1/1     Running   0             29m
    csi-resizer-86dd765b9-zpcv7                         1/1     Running   0             29m
    csi-snapshotter-65b46b8749-dtvh2                    1/1     Running   0             29m
    csi-snapshotter-65b46b8749-g67fn                    1/1     Running   0             29m
    csi-snapshotter-65b46b8749-nfgzm                    1/1     Running   0             29m
    engine-image-ei-221c9c21-gd5d6                      1/1     Running   0             29m
    engine-image-ei-221c9c21-v6clp                      1/1     Running   0             29m
    engine-image-ei-221c9c21-zzdrt                      1/1     Running   0             29m
    instance-manager-77d11dda6091967f9b30011c9876341b   1/1     Running   0             29m
    instance-manager-870c250b69a4fe01382ed46156d33f47   1/1     Running   0             29m
    instance-manager-a4099c5ce28b423c3cc2667906f4b0b4   1/1     Running   0             29m
    longhorn-csi-plugin-jfbh5                           3/3     Running   0             29m
    longhorn-csi-plugin-w768w                           3/3     Running   0             29m
    longhorn-csi-plugin-xcghm                           3/3     Running   0             29m
    longhorn-driver-deployer-586bc86bf9-bkwk6           1/1     Running   0             30m
    longhorn-manager-c4xtv                              1/1     Running   1 (30m ago)   30m
    longhorn-manager-kgqts                              1/1     Running   0             30m
    longhorn-manager-n8xdr                              1/1     Running   0             30m
    longhorn-ui-69667f9678-2lvxn                        1/1     Running   0             30m
    longhorn-ui-69667f9678-2xmc9                        1/1     Running   0             30m

    ```

5. To enable access to the Longhorn UI, you need to set up an Ingress controller. Authentication to the Longhorn UI is not enabled by default. For information on creating an NGINX Ingress controller with basic authentication, refer to [this section.](../../accessing-the-ui/longhorn-ingress)

6. Access the Longhorn UI using [these steps.](../../accessing-the-ui)

