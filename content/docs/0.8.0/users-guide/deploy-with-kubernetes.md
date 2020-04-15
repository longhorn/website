---
  title: Deploy Longhorn with Kubernetes
  weight: 35
---

You can install Longhorn on any Kubernetes cluster using kubectl with this command:

```shell
kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/master/deploy/longhorn.yaml
```

One way to monitor the progress of the installation is to watch Pods being created in the `longhorn-system` namespace:

```shell
kubectl get pods \
--namespace longhorn-system \
--watch
```

The following items will be deployed to Kubernetes

## Namespace: longhorn-system

All Longhorn bits will be scoped to this namespace.

## ServiceAccount: longhorn-service-account

Service account is created in the longhorn-system namespace.

## ClusterRole: longhorn-role

This role will have access to:
  - In apiextension.k8s.io (All verbs)
    - customresourcedefinitions
  - In core (All verbs)
    - pods
      - /logs
    - events
    - persistentVolumes
    - persistentVolumeClaims
      - /status
    - nodes
    - proxy/nodes
    - secrets
    - services
    - endpoints
    - configMaps
  - In core
    - namespaces (get, list)
  - In apps (All Verbs)
    - daemonsets
    - statefulSets
    - deployments
  - In batch (All Verbs)
    - jobs
    - cronjobs
  - In storage.k8s.io (All verbs)
    - storageclasses
    - volumeattachments
    - csinodes
    - csidrivers
  - In coordination.k8s.io
    - leases
  - In longhorn.rancher.io (All verbs, deprecated after v0.7.0)
    - volumes
    - engines
    - replicas
    - settings
    - engineimages
    - nodes
    - instancemanagers

## ClusterRoleBinding: longhorn-bind

This connects the longhorn-role to the longhorn-service-account in the  longhorn-system namespace

## CustomResourceDefinitions

The following CustomResourceDefinitions will be installed 

- In longhorn.io
  - engines
  - replicas
  - settings
  - volumes
  - engineimages
  - nodes
  - instancemanagers

## Kubernetes API Objects

- A config map with the default settings
- The longhorn-manager DaemonSet
- The longhorn-backend service exposing the longhorn-manager DaemonSet internally to Kubernetes
- The longhorn-ui Deployment
- The longhorn-fronend service exposing the longhorn-ui internally to Kubernetes
- The longhorn-driver-deployer that deploys the CSI driver 
- The longhorn StorageClass


At this point Longhorn should be ready to use.