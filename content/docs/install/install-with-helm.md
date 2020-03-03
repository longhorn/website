---
title: Install with Helm
weight: 9
---

## Using [Helm](https://helm.sh) {#helm}

{{< requirement title="Helm setup" >}}
To install Longhorn using Helm, you first need to [install Helm](https://helm.sh/docs/intro/install/) locally. If you're using a version prior to version 3.0, you need to [install Tiller into your Kubernetes cluster with role-based access control (RBAC)](https://v2.helm.sh/docs/using_helm/#tiller-namespaces-and-rbac).
{{< /requirement >}}

Once you have Helm installed, clone the Longhorn repository:

```shell
git clone https://github.com/longhorn/longhorn && cd longorn
```

Use this `helm` command to install Longhorn:

```shell
helm install ./longhorn/chart --name longhorn --namespace longhorn-system
```

This installs Longorn in the `longhorn-system` namespace. One of two available [drivers](../driver)---CSI or FlexVolume---is chosen automatically based on the version of Kubernetes that you're using.

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
If you installed Longhorn using the [kubectl instructions](../install-with-kubectl) above, the Longhorn UI does not require authentication.
{{< /warning >}}

The Longhorn UI looks like this:

{{< figure src="/img/screenshots/install/dashboard.png" >}}
