---
title: Uninstall Longhorn
weight: 6
---

In this section, you'll learn how to uninstall Longhorn.


- [Prerequisite](#prerequisite)
- [Uninstalling Longhorn from the Rancher UI](#uninstalling-longhorn-from-the-rancher-ui)
- [Uninstalling Longhorn using Helm](#uninstalling-longhorn-using-helm)
- [Uninstalling Longhorn using kubectl](#uninstalling-longhorn-using-kubectl)
- [Troubleshooting](#troubleshooting)
  - [Uninstalling using Rancher UI or Helm failed, I am not sure why](#uninstalling-using-rancher-ui-or-helm-failed-i-am-not-sure-why)
  - [I deleted the Longhorn App from Rancher UI instead of following the uninstallation procedure](#i-deleted-the-longhorn-app-from-rancher-ui-instead-of-following-the-uninstallation-procedure)
  - [Problems with CRDs](#problems-with-crds)

### Prerequisite
To prevent Longhorn from being accidentally uninstalled (which leads to data lost),
we introduce a new setting, [deleting-confirmation-flag](../../references/settings/#deleting-confirmation-flag).
If this flag is **false**, the Longhorn uninstallation job will fail.
Set this flag to **true** to allow Longhorn uninstallation.
You can set this flag using setting page in Longhorn UI or `kubectl -n longhorn-system patch -p '{"value": "true"}' --type=merge lhs deleting-confirmation-flag`


To prevent damage to the Kubernetes cluster, we recommend deleting all Kubernetes workloads using Longhorn volumes (PersistentVolume, PersistentVolumeClaim, StorageClass, Deployment, StatefulSet, DaemonSet, etc).

### Uninstalling Longhorn from the Rancher UI

From Rancher UI, navigate to `Catalog Apps` tab and delete Longhorn app.

### Uninstalling Longhorn using Helm

Run this command:

```
helm uninstall longhorn -n longhorn-system
```

### Uninstalling Longhorn using kubectl

1. Create the uninstallation job to clean up CRDs from the system and wait for success:

    ```
    kubectl create -f https://raw.githubusercontent.com/longhorn/longhorn/v{{< current-version >}}/uninstall/uninstall.yaml
    kubectl get job/longhorn-uninstall -n longhorn-system -w
    ```

    Example output:
    ```
    $ kubectl create -f https://raw.githubusercontent.com/longhorn/longhorn/v{{< current-version >}}/uninstall/uninstall.yaml
    serviceaccount/longhorn-uninstall-service-account created
    clusterrole.rbac.authorization.k8s.io/longhorn-uninstall-role created
    clusterrolebinding.rbac.authorization.k8s.io/longhorn-uninstall-bind created
    job.batch/longhorn-uninstall created

    $ kubectl get job/longhorn-uninstall -n longhorn-system -w
    NAME                 COMPLETIONS   DURATION   AGE
    longhorn-uninstall   0/1           3s         3s
    longhorn-uninstall   1/1           20s        20s
    ```

2. Remove remaining components:
    ```
    kubectl delete -f https://raw.githubusercontent.com/longhorn/longhorn/v{{< current-version >}}/deploy/longhorn.yaml
    kubectl delete -f https://raw.githubusercontent.com/longhorn/longhorn/v{{< current-version >}}/uninstall/uninstall.yaml
    ```

> **Tip:** If you try `kubectl delete -f https://raw.githubusercontent.com/longhorn/longhorn/v{{< current-version >}}/deploy/longhorn.yaml` first and get stuck there,
pressing `Ctrl C` then running `kubectl create -f https://raw.githubusercontent.com/longhorn/longhorn/v{{< current-version >}}/uninstall/uninstall.yaml` can also help you remove Longhorn. Finally, don't forget to cleanup remaining components.




### Troubleshooting
#### Uninstalling using Rancher UI or Helm failed, I am not sure why
You might want to check the logs of the `longhorn-uninstall-xxx` pod inside `longhorn-system` namespace to see why it failed.
One reason can be that [deleting-confirmation-flag](../../references/settings/#deleting-confirmation-flag) is `false`.
You can set it to `true` by using setting page in Longhorn UI or `kubectl -n longhorn-system patch -p '{"value": "true"}' --type=merge lhs deleting-confirmation-flag`
then retry the Helm/Rancher uninstallation.

If the uninstallation was an accident (you don't actually want to uninstall Longhorn),
you can cancel the uninstallation as the following.
1. If you use Rancher UI to deploy Longhorn
   1. Open a kubectl shell on Rancher UI
   1. Find the latest revision of Longhorn release
      ```shell
      > helm list -n longhorn-system -a
      NAME            NAMESPACE       REVISION        UPDATED                                 STATUS          CHART                                   APP VERSION
      longhorn        longhorn-system 2               2022-10-14 01:22:36.929130451 +0000 UTC uninstalling    longhorn-100.2.3+up1.3.2-rc1            v1.3.2-rc1
      longhorn-crd    longhorn-system 3               2022-10-13 22:19:05.976625081 +0000 UTC deployed        longhorn-crd-100.2.3+up1.3.2-rc1        v1.3.2-rc1
      ```
   1. Rollback to the latest revision
      ```shell
      > helm rollback longhorn 2 -n longhorn-system
      checking 22 resources for changes
      ...
      Rollback was a success! Happy Helming!
      ```
1. If you use Helm deploy Longhorn
   1. Open a kubectl terminal
   1. Find the latest revision of Longhorn release
      ```shell
      ➜ helm list --namespace longhorn-system -a
      NAME            NAMESPACE       REVISION        UPDATED                                 STATUS          CHART                   APP VERSION
      longhorn        longhorn-system 1               2022-10-14 13:45:25.341292504 -0700 PDT uninstalling    longhorn-1.4.0-dev      v1.4.0-dev
      ```
   1. Rollback to the latest revision
      ```shell
      ➜  helm rollback longhorn 1 -n longhorn-system
      Rollback was a success! Happy Helming!
      ```


#### I deleted the Longhorn App from Rancher UI instead of following the uninstallation procedure

Redeploy the (same version) Longhorn App. Follow the uninstallation procedure above.

#### Problems with CRDs

If your CRD instances or the CRDs themselves can't be deleted for whatever reason, run the commands below to clean up. Caution: this will wipe all Longhorn state!

```shell
# Delete CRD finalizers, instances and definitions
for crd in $(kubectl get crd -o jsonpath={.items[*].metadata.name} | tr ' ' '\n' | grep longhorn.rancher.io); do
  kubectl -n ${NAMESPACE} get $crd -o yaml | sed "s/\- longhorn.rancher.io//g" | kubectl apply -f -
  kubectl -n ${NAMESPACE} delete $crd --all
  kubectl delete crd/$crd
done
```

---
Please see [link](https://github.com/longhorn/longhorn) for more information.
