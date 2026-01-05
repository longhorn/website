---
  title:  Exposing the Longhorn UI
  weight: 1
---

Exposing the Longhorn UI allows external access to the management console. It is important to note that the choice of Ingress controller (for example, **ingress-nginx**, **Traefik**, **HAProxy**) only affects how the UI is accessed; it has **no impact on the Longhorn backend, storage operations, or data integrity**.

If you change your Ingress controller, you only need to reconfigure the Ingress object or the corresponding Helm values to match the new controller's requirements.

> **Note**: For Helm installations, the preferred method is to configure the `ingress` section in the [Longhorn Helm chart values.yaml](https://github.com/longhorn/longhorn/blob/master/chart/values.yaml).

### Basic Authentication Example (NGINX)

The following steps demonstrate how to expose the UI with Basic Authentication using the **ingress-nginx** controller as an example. If you use a different controller, refer to its specific documentation for authentication annotations.

> **Note**: As of November 2025, the Kubernetes project has [announced the retirement of the ingress-nginx controller](https://kubernetes.io/blog/2025/11/11/ingress-nginx-retirement/). While it is used here as a configuration example, users are encouraged to explore maintained alternatives such as Traefik, HAProxy, or other Gateway API-compliant controllers.

1. **Create a basic auth file**: The file must be named `auth` so the secret key is correctly identified.
    ```bash
    $ USER=<USERNAME_HERE>; PASSWORD=<PASSWORD_HERE>; echo "${USER}:$(openssl passwd -stdin -apr1 <<< ${PASSWORD})" >> auth
    ```
2. **Create the secret**:
    ```bash
    $ kubectl -n longhorn-system create secret generic basic-auth --from-file=auth
    ```
3. **Create the Ingress manifest** (`longhorn-ingress.yml`):
    > **Note**: Since v1.2.0, Longhorn supports uploading backing images via the UI. Ensure your controller is configured for large body sizes. For Nginx, use `proxy-body-size`.

    ```yaml
    apiVersion: networking.k8s.io/v1
    kind: Ingress
    metadata:
      name: longhorn-ingress
      namespace: longhorn-system
      annotations:
        # NGINX Example Annotations
        nginx.ingress.kubernetes.io/auth-type: basic
        nginx.ingress.kubernetes.io/auth-secret: basic-auth
        nginx.ingress.kubernetes.io/auth-realm: 'Authentication Required'
        nginx.ingress.kubernetes.io/proxy-body-size: 10000m
        nginx.ingress.kubernetes.io/ssl-redirect: 'false'
    spec:
      ingressClassName: nginx # Replace with your controller's class (for example, traefik)
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

<details>
<summary><b>Click to see a full CLI example (NGINX)</b></summary>

```bash
$ USER=foo; PASSWORD=bar; echo "${USER}:$(openssl passwd -stdin -apr1 <<< ${PASSWORD})" >> auth
$ cat auth
foo:$apr1$FnyKCYKb$6IP2C45fZxMcoLwkOwf7k0

$ kubectl -n longhorn-system create secret generic basic-auth --from-file=auth
secret/basic-auth created
$ kubectl -n longhorn-system get secret basic-auth -o yaml
apiVersion: v1
data:
  auth: Zm9vOiRhcHIxJEZueUtDWUtiJDZJUDJDNDVmWnhNY29Md2tPd2Y3azAK
kind: Secret
metadata:
  creationTimestamp: "2020-05-29T10:10:16Z"
  name: basic-auth
  namespace: longhorn-system
  resourceVersion: "2168509"
  selfLink: /api/v1/namespaces/longhorn-system/secrets/basic-auth
  uid: 9f66233f-b12f-4204-9c9d-5bcaca794bb7
type: Opaque

$ echo "
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: longhorn-ingress
  namespace: longhorn-system
  annotations:
    # type of authentication
    nginx.ingress.kubernetes.io/auth-type: basic
    # prevent the controller from redirecting (308) to HTTPS
    nginx.ingress.kubernetes.io/ssl-redirect: 'false'
    # name of the secret that contains the user/password definitions
    nginx.ingress.kubernetes.io/auth-secret: basic-auth
    # message to display with an appropriate context why the authentication is required
    nginx.ingress.kubernetes.io/auth-realm: 'Authentication Required '
spec:
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
" | kubectl -n longhorn-system create -f -
ingress.networking.k8s.io/longhorn-ingress created

$ kubectl -n longhorn-system get ingress
NAME               HOSTS   ADDRESS                                     PORTS   AGE
longhorn-ingress   *       45.79.165.114,66.228.45.37,97.107.142.125   80      2m7s

$ curl -v http://97.107.142.125/
*   Trying 97.107.142.125...
* TCP_NODELAY set
* Connected to 97.107.142.125 (97.107.142.125) port 80 (#0)
> GET / HTTP/1.1
> Host: 97.107.142.125
> User-Agent: curl/7.64.1
> Accept: */*
>
< HTTP/1.1 401 Unauthorized
< Server: openresty/1.15.8.1
< Date: Fri, 29 May 2020 11:47:33 GMT
< Content-Type: text/html
< Content-Length: 185
< Connection: keep-alive
< WWW-Authenticate: Basic realm="Authentication Required"
<
<html>
<head><title>401 Authorization Required</title></head>
<body>
<center><h1>401 Authorization Required</h1></center>
<hr><center>openresty/1.15.8.1</center>
</body>
</html>
* Connection #0 to host 97.107.142.125 left intact
* Closing connection 0

$ curl -v http://97.107.142.125/ -u foo:bar
*   Trying 97.107.142.125...
* TCP_NODELAY set
* Connected to 97.107.142.125 (97.107.142.125) port 80 (#0)
* Server auth using Basic with user 'foo'
> GET / HTTP/1.1
> Host: 97.107.142.125
> Authorization: Basic Zm9vOmJhcg==
> User-Agent: curl/7.64.1
> Accept: */*
>
< HTTP/1.1 200 OK
< Date: Fri, 29 May 2020 11:51:27 GMT
< Content-Type: text/html
< Content-Length: 1118
< Last-Modified: Thu, 28 May 2020 00:39:41 GMT
< ETag: "5ecf084d-3fd"
< Cache-Control: max-age=0
<
<!DOCTYPE html>
<html lang="en">
......
```
</details>

### Verification

Regardless of the controller used, you can verify authentication via `curl`. Replace `<EXTERNAL_IP>` with your access point.

* **Unauthorized Access (Expected)**:
    ```bash
    $ curl -I http://<EXTERNAL_IP>/
    HTTP/1.1 401 Unauthorized
    ```
* **Authorized Access (Expected)**:
    ```bash
    $ curl -I http://<EXTERNAL_IP>/ -u foo:bar
    HTTP/1.1 200 OK
    ```

## Additional Steps for AWS EKS

Exposing the UI on AWS usually requires a Load Balancer. Additional costs may apply.

1. Refer to your specific [Ingress controller's AWS guide](https://kubernetes.io/docs/concepts/services-networking/ingress-controllers/).
2. For Nginx, see the [official Nginx AWS deployment documentation](https://kubernetes.github.io/ingress-nginx/deploy/#aws).

## References

- [Longhorn Helm Chart Ingress Configuration](https://github.com/longhorn/longhorn/blob/master/chart/values.yaml)
- [Kubernetes Ingress Overview](https://kubernetes.io/docs/concepts/services-networking/ingress/)
- [Ingress-NGINX Retirement Announcement](https://kubernetes.io/blog/2025/11/11/ingress-nginx-retirement/)
