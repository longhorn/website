---
  title:  Create an Ingress with Basic Authentication
  weight: 1
---

If you install Longhorn on a Kubernetes cluster with kubectl or Helm, you will need to create an Ingress to allow external traffic to reach the Longhorn UI.

Authentication is not enabled by default for kubectl and Helm installations. In these steps, you'll learn how to create an Ingress with basic authentication. 

> **Note**: For Helm installations, you can reconfigure the Ingress object by adjusting the `ingress` section in the [Longhorn Helm chart values.yaml](https://github.com/longhorn/longhorn/blob/master/chart/values.yaml).

### Prerequisites

The following steps use examples for the **ingress-nginx** controller. If you are using a different Ingress controller (for example, **Traefik**), you will need to use the specific annotations required by that controller for basic authentication.

1. Create a basic auth file `auth`. It's important the file generated is named auth (specifically, that the secret has a key `data.auth`), otherwise the Ingress may return a 503.
    ```bash
    $ USER=<USERNAME_HERE>; PASSWORD=<PASSWORD_HERE>; echo "${USER}:$(openssl passwd -stdin -apr1 <<< ${PASSWORD})" >> auth
    ```
2. Create a secret in the `longhorn-system` namespace:
    ```bash
    $ kubectl -n longhorn-system create secret generic basic-auth --from-file=auth
    ```
3. Create an Ingress manifest `longhorn-ingress.yml`:
    > **Note**: Since v1.2.0, Longhorn supports uploading backing images from the UI. Ensure your Ingress controller is configured to allow large body sizes (for example, `nginx.ingress.kubernetes.io/proxy-body-size: 10000m` for Nginx).

    ```yaml
    apiVersion: networking.k8s.io/v1
    kind: Ingress
    metadata:
      name: longhorn-ingress
      namespace: longhorn-system
      annotations:
        # Type of authentication
        nginx.ingress.kubernetes.io/auth-type: basic
        # Name of the secret that contains the user/password definitions
        nginx.ingress.kubernetes.io/auth-secret: basic-auth
        # Message to display with an appropriate context why the authentication is required
        nginx.ingress.kubernetes.io/auth-realm: 'Authentication Required'
        # Custom max body size for file uploading like backing image uploading
        nginx.ingress.kubernetes.io/proxy-body-size: 10000m
        # Prevent the controller from redirecting (308) to HTTPS if not using SSL
        nginx.ingress.kubernetes.io/ssl-redirect: 'false'
    spec:
      ingressClassName: nginx                   # ingressClassName: <your-ingress-class>
      rules:
      - http:
          paths:
          - pathType: Prefix
            path: "/"
            backend:
              service:
                name: longhorn-frontend
                port:
                  number: 80
    ```
4. Create the Ingress:
    ```bash
    $ kubectl -n longhorn-system apply -f longhorn-ingress.yml
    ```

### Verification Example

After creating the Ingress, you can verify that the authentication is working using `curl`. Replace `<EXTERNAL_IP>` with your Ingress IP or hostname.

#### 1. Test access without credentials:
You should receive a `401 Unauthorized` response.
```bash
$ curl -I http://<EXTERNAL_IP>/
HTTP/1.1 401 Unauthorized
WWW-Authenticate: Basic realm="Authentication Required"
```

#### 2. Test access with credentials:
You should receive a `200 OK` response.
```bash
$ curl -I http://<EXTERNAL_IP>/ -u foo:bar
HTTP/1.1 200 OK
```

## Additional Steps for AWS EKS Kubernetes Clusters

You may need to create an ELB (Elastic Load Balancer) to expose your Ingress controller to the Internet.

1. Create pre-requisite resources according to your specific [Ingress controller documentation](https://kubernetes.io/docs/concepts/services-networking/ingress-controllers/).
2. If using Nginx on AWS, follow the [AWS deployment guide](https://kubernetes.github.io/ingress-nginx/deploy/#aws) to create an ELB.

## References

- [Kubernetes Ingress Documentation](https://kubernetes.io/docs/concepts/services-networking/ingress/)
- [Longhorn Helm Chart Ingress Values](https://github.com/longhorn/longhorn/blob/master/chart/values.yaml)
