---
title: Uninstall Longhorn
weight: 10
---

In this section, you'll learn how to uninstall Longhorn.


- [Prerequisite](#prerequisite)
- [Uninstalling Longhorn from the Rancher UI](#uninstalling-longhorn-from-the-rancher-ui)
- [Uninstalling Longhorn using Helm](#uninstalling-longhorn-using-helm)
- [Uninstalling Longhorn using kubectl](#uninstalling-longhorn-using-kubectl)
- [Troubleshooting](#troubleshooting)

### Prerequisite

To prevent damage to the Kubernetes cluster, we recommend deleting all Kubernetes workloads using Longhorn volumes (PersistentVolume, PersistentVolumeClaim, StorageClass, Deployment, StatefulSet, DaemonSet, etc).

### Uninstalling Longhorn from the Rancher UI

From Rancher UI, navigate to `Catalog Apps` tab and delete Longhorn app.

### Uninstalling Longhorn using Helm

Run this command:

```
helm delete longhorn --purge
```

### Uninstalling Longhorn using kubectl

1. Create the uninstallation job to clean up CRDs from the system and wait for success:

    ```
    kubectl create -f https://raw.githubusercontent.com/longhorn/longhorn/master/uninstall/uninstall.yaml
    kubectl get job/longhorn-uninstall -w
    ```

    Example output:
    ```
    $ kubectl create -f https://raw.githubusercontent.com/longhorn/longhorn/master/uninstall/uninstall.yaml
    serviceaccount/longhorn-uninstall-service-account created
    clusterrole.rbac.authorization.k8s.io/longhorn-uninstall-role created
    clusterrolebinding.rbac.authorization.k8s.io/longhorn-uninstall-bind created
    job.batch/longhorn-uninstall created

    $ kubectl get job/longhorn-uninstall -w
    NAME                 COMPLETIONS   DURATION   AGE
    longhorn-uninstall   0/1           3s         3s
    longhorn-uninstall   1/1           20s        20s
    ^C
    ```

2. Remove remaining components:
    ```
    kubectl delete -f https://raw.githubusercontent.com/longhorn/longhorn/master/deploy/longhorn.yaml
    kubectl delete -f https://raw.githubusercontent.com/longhorn/longhorn/master/uninstall/uninstall.yaml
    ```
 
> **Tip:** If you try `kubectl delete -f https://raw.githubusercontent.com/longhorn/longhorn/master/deploy/longhorn.yaml` first and get stuck there, 
pressing `Ctrl C` then running `kubectl create -f https://raw.githubusercontent.com/longhorn/longhorn/master/uninstall/uninstall.yaml` can also help you remove Longhorn. Finally, don't forget to cleanup remaining components.




### Troubleshooting

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

#### Volume can be attached/detached from UI, but Kubernetes Pod/StatefulSet etc cannot use it

Check if volume plugin directory has been set correctly. This is automatically detected unless user explicitly set it. Note: The FlexVolume plugin is deprecated as of Longhorn v0.8.0 and should no longer be used.

By default, Kubernetes uses `/usr/libexec/kubernetes/kubelet-plugins/volume/exec/`, as stated in the [official document](https://github.com/kubernetes/community/blob/master/contributors/devel/sig-storage/flexvolume.md/#prerequisites).

Some vendors choose to change the directory for various reasons. For example, GKE uses `/home/kubernetes/flexvolume` instead.

User can find the correct directory by running `ps aux|grep kubelet` on the host and check the `--volume-plugin-dir` parameter. If there is none, the default `/usr/libexec/kubernetes/kubelet-plugins/volume/exec/` will be used.

---
Please see [link](https://github.com/longhorn/longhorn) for more information.
