---
title: Accessing the UI
weight: 2
---

## Prerequisites for Access and Authentication

These instructions assume that Longhorn is installed.

If you installed Longhorn YAML manifest, you'll need to set up an Ingress controller to allow external traffic into the cluster, and authentication will not be enabled by default. This applies to Helm and kubectl installations. For information on creating an NGINX Ingress controller with basic authentication, refer to [this section.](./longhorn-ingress) Alternatively, you can use [Gateway API HTTPRoute](./longhorn-httproute) as a modern approach to expose the Longhorn UI.

> **Note**: As of November 2025, the Kubernetes project has [announced the retirement of the ingress-nginx controller](https://kubernetes.io/blog/2025/11/11/ingress-nginx-retirement/).

If Longhorn was installed as a Rancher catalog app, Rancher automatically created an Ingress controller for you with access control (the rancher-proxy).

## Accessing the Longhorn UI

Once Longhorn has been installed in your Kubernetes cluster, you can access the UI dashboard.

1. Get the Longhorn's external service IP:

    ```shell
    kubectl -n longhorn-system get svc
    ```

    For Longhorn v0.8.0, the output should look like this, and the `CLUSTER-IP` of the `longhorn-frontend` is used to access the Longhorn UI:

    ```shell
    NAME                TYPE           CLUSTER-IP      EXTERNAL-IP      PORT(S)        AGE
    longhorn-backend    ClusterIP      10.20.248.250   <none>           9500/TCP       58m
    longhorn-frontend   ClusterIP      10.20.245.110   <none>           80/TCP         58m

    ```

    In the example above, the IP is `10.20.245.110`.
    
    > For Longhorn v0.8.0+, UI service type changed from `LoadBalancer` to `ClusterIP.`

2. Navigate to the IP of `longhorn-frontend` in your browser.

    The Longhorn UI looks like this:

    {{< figure src="/img/screenshots/getting-started/v1.10.0/longhorn-ui.png" >}}
