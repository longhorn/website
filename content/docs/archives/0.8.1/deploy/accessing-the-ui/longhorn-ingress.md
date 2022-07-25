---
  title:  Create NGINX Ingress Controller with Basic Authentication
  weight: 1
---

If you install Longhorn on a Kubernetes cluster with kubectl or Helm, you will need to create an Ingress controller to allow external traffic to reach the Longhorn UI.

Authentication is not enabled by default for kubectl and Helm installations. In these steps, you'll learn how to create an Ingress controller with basic authentication.

1. Create a basic auth file `auth`. It's important the file generated is named auth (actually - that the secret has a key `data.auth`), otherwise the ingress-controller returns a 503.
    ```
    $ USER=<USERNAME_HERE>; PASSWORD=<PASSWORD_HERE>; echo "${USER}:$(openssl passwd -stdin -apr1 <<< ${PASSWORD})" >> auth
    ```
2. Create a secret:
    ```
    $ kubectl -n longhorn-system create secret generic basic-auth --from-file=auth
    ```
3. Create an NGINX Ingress controller manifest `longhorn-ingress.yml` :
    ```
    apiVersion: networking.k8s.io/v1beta1
    kind: Ingress
    metadata:
      name: longhorn-ingress
      namespace: longhorn-system
      annotations:
        # type of authentication
        nginx.ingress.kubernetes.io/auth-type: basic
        # name of the secret that contains the user/password definitions
        nginx.ingress.kubernetes.io/auth-secret: basic-auth
        # message to display with an appropriate context why the authentication is required
        nginx.ingress.kubernetes.io/auth-realm: 'Authentication Required '
    spec:
      rules:
      - http:
          paths:
          - path: /
            backend:
              serviceName: longhorn-frontend
              servicePort: 80
    ```
4. Create the ingress controller:
    ```
    $ kubectl -n longhorn-system apply -f longhorn-ingress.yml
    ```

## Additional Steps for AWS EKS Kubernetes Clusters

You will need to create an ELB (Elastic Load Balancer) to expose the NGINX Ingress controller to the Internet. Additional costs may apply.

1. Create pre-requisite resources according to the [NGINX Ingress Controller documentation.](https://kubernetes.github.io/ingress-nginx/deploy/#prerequisite-generic-deployment-command)

2. Create an ELB by following [these steps.](https://kubernetes.github.io/ingress-nginx/deploy/#aws)
