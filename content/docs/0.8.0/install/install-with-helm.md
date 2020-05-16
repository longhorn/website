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
git clone https://github.com/longhorn/longhorn
```

Now use the following command(s) to install Longhorn in the `longhorn-system` namespace:

* Helm 2:

    ```
    helm install ./longhorn/chart --name longhorn --namespace longhorn-system
    ```
* Helm 3: When installing Longhorn with Helm 3, the namespace is created separately.

    ```
    kubectl create namespace longhorn-system
    helm install longhorn ./longhorn/chart/ --namespace longhorn-system
    ```
---

This installs Longhorn in the `longhorn-system` namespace.

A successful CSI-based deployment looks like this:
```bash
# kubectl -n longhorn-system get pod
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
