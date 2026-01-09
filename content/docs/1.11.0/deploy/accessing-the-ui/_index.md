---
title: Accessing the UI
weight: 2
---

Exposing the Longhorn UI allows external access to the management console. The choice of Ingress controller (for example, **ingress-nginx**, **Traefik**, or **HAProxy**) affects only how the UI is accessed. It has **no impact on the Longhorn backend, storage operations, or data integrity**.

> **Note**: As of November 2025, the Kubernetes project has announced the retirement of the ingress-nginx controller. For details, [see the official announcement](https://kubernetes.io/blog/2025/11/11/ingress-nginx-retirement/).

## Prerequisites for Access and Authentication

These instructions assume that Longhorn is already installed in the cluster.

If you installed Longhorn using the YAML manifest, you must set up an Ingress controller to allow external traffic into the cluster. Authentication is **not enabled by default**. This applies to both Helm and `kubectl` installations.

For information on creating an NGINX Ingress controller with basic authentication, see [this section](./longhorn-ingress). Alternatively, you can use the [Gateway API HTTPRoute](./longhorn-httproute) as a modern approach to exposing the Longhorn UI.

If Longhorn was installed as a Rancher catalog app, Rancher automatically creates an Ingress controller with access control (the `rancher-proxy`).

## Accessing the Longhorn UI

After Longhorn is installed in your Kubernetes cluster, you can access the UI dashboard by following these steps.

1. Retrieve the Longhorn service information:

    ```shell
    kubectl -n longhorn-system get svc
    ```

    For Longhorn v0.8.0 and later, the output resembles the following. Use the `CLUSTER-IP` of the `longhorn-frontend` service to access the UI:

    ```shell
    NAME                TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
    longhorn-backend    ClusterIP   10.20.248.250   <none>        9500/TCP   58m
    longhorn-frontend   ClusterIP   10.20.245.110   <none>        80/TCP     58m
    ```

    In this example, the UI is accessible at `10.20.245.110`.

    > **Note**: Starting with Longhorn v0.8.0, the UI service type changed from `LoadBalancer` to `ClusterIP`.

2. Open a browser and navigate to the IP address of the `longhorn-frontend` service.

    The Longhorn UI appears as follows:

    {{< figure src="/img/screenshots/getting-started/v1.10.0/longhorn-ui.png" >}}
