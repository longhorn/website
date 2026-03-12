---
  title:  Create an Ingress with Basic Authentication (Traefik)
  weight: 1
---

If you install Longhorn on a Kubernetes cluster with `kubectl` or Helm, you will need to create an Ingress to allow external traffic to reach the Longhorn UI.

Authentication is not enabled by default for `kubectl` and Helm installations. In these steps, you’ll learn how to create an Ingress with basic authentication and configure support for large file uploads (for backing images) using Traefik.

> **Note**: These instructions assume that the Traefik Ingress Controller is installed and running in your cluster. Traefik is the default ingress controller for RKE2 and K3s. If you are using a different environment, ensure Traefik is deployed before proceeding. You can verify its presence by running `kubectl get pods -A | grep traefik`.

### 1. Create a Basic Auth Secret

Create a basic auth file `auth`. It is important that the secret has a key named `auth` for the following steps.

```shell
$ USER=<USERNAME_HERE>; PASSWORD=<PASSWORD_HERE>; echo "${USER}:$(openssl passwd -stdin -apr1 <<< ${PASSWORD})" > auth
```

Create the secret in the `longhorn-system` namespace:

```shell
$ kubectl -n longhorn-system create secret generic basic-auth --from-file=auth
```

### 2. Create Traefik Middlewares

Traefik utilizes Middlewares to handle authentication and request limits. Create a file named `longhorn-middlewares.yml`:

```yaml
apiVersion: traefik.io/v1alpha1
kind: Middleware
metadata:
  name: longhorn-auth
  namespace: longhorn-system
spec:
  basicAuth:
    secret: basic-auth
---
apiVersion: traefik.io/v1alpha1
kind: Middleware
metadata:
  name: longhorn-buffering
  namespace: longhorn-system
spec:
  buffering:
    # Allows backing image uploads up to 10,000MB
    maxRequestBodyBytes: 10485760000 
```

Apply the configuration:

```shell
$ kubectl apply -f longhorn-middlewares.yml
```

### 3. Create the Ingress Manifest

Create an Ingress manifest `longhorn-ingress.yml`. To ensure backing image uploads work as expected, we include the `longhorn-buffering` middleware via annotations.

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: longhorn-ingress
  namespace: longhorn-system
  annotations:
    # Connect the middlewares defined in step 2
    traefik.ingress.kubernetes.io/router.middlewares: 
      longhorn-system-longhorn-auth@kubernetescrd,
      longhorn-system-longhorn-buffering@kubernetescrd
spec:
  ingressClassName: traefik
  rules:
  - http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: longhorn-frontend
            port:
              number: 80
```

### 4. Create the Ingress

```shell
$ kubectl -n longhorn-system apply -f longhorn-ingress.yml
```

#### Example

```shell
$ USER=foo; PASSWORD=bar; echo "${USER}:$(openssl passwd -stdin -apr1 <<< ${PASSWORD})" > auth
$ kubectl -n longhorn-system create secret generic basic-auth --from-file=auth
secret/basic-auth created

# (After applying middlewares and ingress manifests)

$ kubectl -n longhorn-system get ingress
NAME               CLASS     HOSTS   ADDRESS      PORTS   AGE
longhorn-ingress   traefik   * 10.0.2.15    80      15s

$ curl -I http://10.0.2.15/
HTTP/1.1 401 Unauthorized
Www-Authenticate: Basic realm="traefik"

$ curl -u foo:bar -I http://10.0.2.15/
HTTP/1.1 200 OK
```

## Additional Steps for AWS EKS Kubernetes Clusters

To expose the Traefik Ingress controller to the internet on AWS EKS, you must provision an AWS Load Balancer. Additional costs may apply.

1. **Install Traefik**: If Traefik is not already installed in your EKS cluster, follow the [official Traefik Helm Chart installation guide](https://doc.traefik.io/traefik/getting-started/install-traefik/#use-the-helm-chart).
2. **Configure Load Balancer**: By default, setting the Traefik service type to `LoadBalancer` will trigger the creation of an AWS ELB. For advanced configuration (such as using an NLB or specific security groups), refer to the [Traefik AWS Guide](https://doc.traefik.io/traefik/providers/kubernetes-ingress/#annotations).

## References

- [Traefik Documentation](https://doc.traefik.io/traefik/)
- [Traefik Kubernetes Ingress Guide](https://doc.traefik.io/traefik/reference/install-configuration/providers/kubernetes/kubernetes-ingress/)
- [Kubernetes Blog - Ingress-NGINX Retirement](https://kubernetes.io/blog/2025/11/11/ingress-nginx-retirement/)
