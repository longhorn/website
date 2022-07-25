---
title: Accessing the UI
weight: 10
---

> For Longhorn v0.8.0+, UI service type has been changed from `LoadBalancer` to `ClusterIP`

You can run `kubectl -n longhorn-system get svc` to get Longhorn UI service:

```
NAME                TYPE           CLUSTER-IP      EXTERNAL-IP      PORT(S)        AGE
longhorn-backend    ClusterIP      10.20.248.250   <none>           9500/TCP       58m
longhorn-frontend   ClusterIP      10.20.245.110   <none>           80/TCP         58m

```

To access Longhorn UI when installed from YAML manifest, you need to create an ingress controller.

See more about how to create an Nginx ingress controller with basic authentication [here](../../users-guide/longhorn-ingress)