---
title: "Troubleshooting: Use Traefik 2.x as ingress controller"
author: JenTing Hsiao
draft: false
date: 2021-04-20
categories:
  - "longhorn-ui"
---

## Applicable versions

All Longhorn versions with Traefik 2.x as ingress controller.

Note that, the CORS problem would not happen with Traefik 1.x as ingress controller.

## Symptoms

The Longhorn GUI frontend API requests sometimes failed to reach longhorn-manager backend.

## Reason

The API requests would change the protocol between HTTPS/WSS, and the change would lead to a CORS problem.

## Solution

The Traefik 2.x ingress controller does not set the WebSocket headers.

1. Adds the following middleware to the route for the Longhorn frontend service.
   ```yaml
   apiVersion: traefik.containo.us/v1alpha1
   kind: Middleware
   metadata:
     name: svc-longhorn-headers
     namespace: longhorn-system
   spec:
     headers:
       customRequestHeaders:
         X-Forwarded-Proto: "https"
   ```

2. Updates the ingress to use the middleware rule.
   ```yaml
   apiVersion: networking.k8s.io/v1beta1
   kind: Ingress
   metadata:
     name: longhorn-ingress
     namespace: longhorn-system
     annotations:
       traefik.ingress.kubernetes.io/router.entrypoints: websecure
       traefik.ingress.kubernetes.io/router.tls: "true"       
       traefik.ingress.kubernetes.io/router.middlewares: longhorn-system-svc-longhorn-headers@kubernetescrd
   spec:
     rules:
     - http:
         paths:
         - path: /
           backend:
             serviceName: longhorn-frontend
             servicePort: 80
   ```

## Related information

* Longhorn issue comment: https://github.com/longhorn/longhorn/issues/1442#issuecomment-639761799
