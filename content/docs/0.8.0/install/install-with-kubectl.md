---
title: Install With Kubectl
description: Install Longhorn with the kubectl client.
weight: 8
---

## Using `kubectl` {#kubectl}

You can install Longhorn on any Kubernetes cluster using this command:

```shell
kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/master/deploy/longhorn.yaml
```

One way to monitor the progress of the installation is to watch Pods being created in the `longhorn-system` namespace:

```shell
kubectl get pods \
--namespace longhorn-system \
--watch
```

{{< info title="Running Longhorn on Google Kubernetes Engine" >}}
[Google Kubernetes Engine](https://cloud.google.com/kubernetes-engine/) (GKE) requires some additional setup for Longorn to function properly. If you're a GKE user, read [this doc](../../users-guide/cloud-provider-notes/google-kubernetes-engine) before proceeding.
{{< /info >}}