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

| Key                     | Type   | Default        | Description                                                                                 |
|-------------------------|--------|----------------|---------------------------------------------------------------------------------------------|
| `httproute.enabled`     | bool   | `false`        | Enables HTTPRoute generation for the Longhorn UI.                                           |
| `httproute.parentRefs`  | list   | `[]`           | List of Gateway references specifying which Gateway(s) should handle this route.            |
| `httproute.hostnames`   | list   | `[]`           | List of hostnames bound to the HTTPRoute.                                                   |
| `httproute.filters`     | list   | `[]`           | List of Gateway API filters to attach to the HTTPRoute rule for the Longhorn UI.            |
| `httproute.path`        | string | `"/"`          | The routing path used to access the Longhorn UI.                                            |
| `httproute.pathType`    | string | `"PathPrefix"` | The path match type. Valid options are `"Exact"`, `"PathPrefix"`, or `"RegularExpression"`. |
| `httproute.annotations` | object | `{}`           | Key-value annotations to apply to the HTTPRoute resource.                                   |

## Basic Installation

Install Longhorn with HTTPRoute enabled:

```shell
helm install longhorn longhorn/longhorn \
  --namespace longhorn-system \
  --create-namespace \
  --set "httproute.enabled=true" \
  --set "httproute.parentRefs[0].name=my-gateway" \
  --set "httproute.parentRefs[0].namespace=default" \
  --set "httproute.hostnames[0]=longhorn.example.com"
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

#### Secure access to Longhorn UI with basic auth integration

To enable authenticated access to the Longhorn UI, reference an existing authentication proxy or middleware resource through the HTTPRoute `filters` field.
The following example assumes a Traefik Middleware resource providing basic authentication is already configured:

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
  filters:
    - type: ExtensionRef
      extensionRef:
        group: traefik.io
        kind: Middleware
        name: oauth-forwardauth
  path: /longhorn
  pathType: PathPrefix
  annotations:
    custom-annotation: "value"
```

> **Note:** `filters` is optional for a standard HTTPRoute. Any referenced resource must be configured separately and exist before the HTTPRoute is created.

Install Longhorn using the same values file:

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
- [HTTPRoute Specification](https://gateway-api.sigs.k8s.io/reference/api-spec/main/spec/#gateway.networking.k8s.io/v1.HTTPRoute)
