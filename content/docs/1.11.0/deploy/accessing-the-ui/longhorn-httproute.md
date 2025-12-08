---
title: Create an HTTPRoute with Gateway API
weight: 2
---

If you install Longhorn on a Kubernetes cluster with kubectl or Helm, you can use [Gateway API](https://gateway-api.sigs.k8s.io/) HTTPRoute as a modern alternative to Ingress for exposing the Longhorn UI to external traffic.

Gateway API is the successor to Ingress, offering more expressive routing capabilities and a standardized approach across different implementations.

## Prerequisites

1. **Gateway API CRDs installed** in your cluster:

    ```shell
    kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.0/standard-install.yaml
    ```

2. **A Gateway controller** running in your cluster (e.g., Istio, Envoy Gateway, Cilium, NGINX Gateway Fabric, Traefik, etc.)

3. **At least one Gateway resource** deployed and configured

## Helm Values Configuration

The following Helm values control HTTPRoute generation:

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `httproute.enabled` | bool | `false` | Enable HTTPRoute generation for Longhorn UI |
| `httproute.parentRefs` | list | `[]` | Gateway references specifying which Gateway(s) should handle this route |
| `httproute.hostnames` | list | `[]` | List of hostnames for the HTTPRoute |
| `httproute.path` | string | `"/"` | Path for accessing Longhorn UI |
| `httproute.pathType` | string | `"PathPrefix"` | Path match type: `Exact` or `PathPrefix` |
| `httproute.annotations` | object | `{}` | Annotations for the HTTPRoute resource |

## Basic Installation

Install Longhorn with HTTPRoute enabled:

```shell
helm install longhorn longhorn/longhorn \
  --namespace longhorn-system \
  --create-namespace \
  --set httproute.enabled=true \
  --set httproute.parentRefs[0].name=my-gateway \
  --set httproute.parentRefs[0].namespace=default \
  --set httproute.hostnames[0]=longhorn.example.com
```

## Advanced Configuration

For more complex setups, create a values file:

```yaml
httproute:
  enabled: true
  parentRefs:
    - name: primary-gateway
      namespace: gateway-system
    - name: secondary-gateway
      namespace: gateway-system
      sectionName: https  # Target specific listener
  hostnames:
    - longhorn.example.com
    - longhorn.example.org
  path: /longhorn
  pathType: PathPrefix
  annotations:
    custom-annotation: "value"
```

Install with the values file:

```shell
helm install longhorn longhorn/longhorn \
  --namespace longhorn-system \
  --create-namespace \
  --values values.yaml
```

## Verification

1. Verify the HTTPRoute was created:

    ```shell
    kubectl get httproute -n longhorn-system
    ```

2. Check HTTPRoute details:

    ```shell
    kubectl describe httproute longhorn-httproute -n longhorn-system
    ```

3. Verify the route is accepted by the Gateway:

    ```shell
    kubectl get httproute longhorn-httproute -n longhorn-system -o jsonpath='{.status.parents[*].conditions}'
    ```

    The output should show `Accepted: True` and `ResolvedRefs: True`.

4. Access the Longhorn UI through your Gateway's external IP or hostname.

## References

- [Gateway API Documentation](https://gateway-api.sigs.k8s.io/)
- [HTTPRoute Specification](https://gateway-api.sigs.k8s.io/reference/spec/#gateway.networking.k8s.io/v1.HTTPRoute)
