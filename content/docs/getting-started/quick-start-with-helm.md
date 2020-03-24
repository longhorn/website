---
title: Quick Start with Helm
description: Run Longhorn on Kubernetes using Helm
weight: 5
---

1. Helm 3.0+
2. Docker v1.13+
3. Kubernetes v1.8+ cluster with 1 or more nodes and Mount Propagation feature enabled. If your Kubernetes cluster was provisioned by Rancher v2.0.7+ or later, MountPropagation feature is enabled by default. [Check your Kubernetes environment now](https://github.com/rancher/longhorn#environment-check-script). If MountPropagation is disabled, the Kubernetes Flexvolume driver will be deployed instead of the default CSI driver. Base Image feature will also be disabled if MountPropagation is disabled.
4. Make sure `curl`, `findmnt`, `grep`, `awk` and `blkid` has been installed in all nodes of the Kubernetes cluster.
5. Make sure `open-iscsi` has been installed in all nodes of the Kubernetes cluster. For GKE, recommended Ubuntu as guest OS image since it contains `open-iscsi` already.

{{< requirement title="Helm setup" >}}
To install Longhorn using Helm, you first need to [install Helm](https://helm.sh/docs/intro/install/) locally. If you're using a version prior to version 3.0, you need to [install Tiller into your Kubernetes cluster with role-based access control (RBAC)](https://v2.helm.sh/docs/using_helm/#tiller-namespaces-and-rbac).
{{< /requirement >}}

Once you have Helm installed, clone the Longhorn repository:

```shell
git clone https://github.com/longhorn/longhorn && cd longhorn
```

Use this `helm` command to install Longhorn:

```shell
helm install ./longhorn/chart --name longhorn --namespace longhorn-system
```

This installs Longorn in the `longhorn-system` namespace. One of two available [drivers](../../architecture/driver)---CSI or FlexVolume---is chosen automatically based on the version of Kubernetes that you're using.

A successful CSI-based deployment, for example, looks like this:

```shell
kubectl -n longhorn-system get pod
NAME                                        READY     STATUS    RESTARTS   AGE
csi-attacher-0                              1/1       Running   0          6h
csi-provisioner-0                           1/1       Running   0          6h
engine-image-ei-57b85e25-8v65d              1/1       Running   0          7d
engine-image-ei-57b85e25-gjjs6              1/1       Running   0          7d
engine-image-ei-57b85e25-t2787              1/1       Running   0          7d
longhorn-csi-plugin-4cpk2                   2/2       Running   0          6h
longhorn-csi-plugin-ll6mq                   2/2       Running   0          6h
longhorn-csi-plugin-smlsh                   2/2       Running   0          6h
longhorn-driver-deployer-7b5bdcccc8-fbncl   1/1       Running   0          6h
longhorn-manager-7x8x8                      1/1       Running   0          6h
longhorn-manager-8kqf4                      1/1       Running   0          6h
longhorn-manager-kln4h                      1/1       Running   0          6h
longhorn-ui-f849dcd85-cgkgg                 1/1       Running   0          5d
```

## Accessing the UI

Once Longhorn has been installed in your Kubernetes cluster, you can access the UI dashboard by getting its external service IP and navigating to it in your browser:

```shell
kubectl -n longhorn-system get svc
```

The output should look something like this:

```shell
NAME                TYPE           CLUSTER-IP      EXTERNAL-IP      PORT(S)        AGE
longhorn-backend    ClusterIP      10.20.248.250   <none>           9500/TCP       58m
longhorn-frontend   LoadBalancer   10.20.245.110   100.200.200.123  80:30697/TCP   58m
```

In the example above, the public IP is `100.200.200.123`.

{{< warning title="No authentication by default" >}}
If you installed Longhorn using the [kubectl instructions](../../install/install-with-kubectl) above, the Longhorn UI does not require authentication.
{{< /warning >}}

### Access the UI

The Longhorn UI looks like this:

{{< figure src="/img/screenshots/getting-started/longhorn-ui.png" >}}

### Volume can be attached/detached from UI, but Kubernetes Pod/StatefulSet etc cannot use it

Check if volume plugin directory has been set correctly. This is automatically detected unless user explicitly set it.

By default, Kubernetes uses `/usr/libexec/kubernetes/kubelet-plugins/volume/exec/`, as stated in the [official document](https://github.com/kubernetes/community/blob/master/contributors/devel/flexvolume.md#prerequisites).

Some vendors choose to change the directory for various reasons. For example, GKE uses `/home/kubernetes/flexvolume` instead.

User can find the correct directory by running `ps aux|grep kubelet` on the host and check the `--volume-plugin-dir` parameter. If there is none, the default `/usr/libexec/kubernetes/kubelet-plugins/volume/exec/` will be used.
