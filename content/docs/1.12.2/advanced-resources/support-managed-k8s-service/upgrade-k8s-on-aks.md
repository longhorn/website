---
title:  Upgrade Kubernetes on Azure AKS
weight: 5
---

AKS provides `az aks upgrade` for in-places nodes upgrade by node reimaged, but this will cause the original Longhorn disks missing, then there will be no disks allowing replica rebuilding in upgraded nodes anymore.

We suggest using node-pool replacement to upgrade the agent nodes but use `az aks upgrade` for control plane nodes to ensure data safety.

1. In Longhorn, set `replica-replenishment-wait-interval` to `0`.

2. Upgrade AKS control plane.
    ```
    AKS_RESOURCE_GROUP=<aks-resource-group>
    AKS_CLUSTER_NAME=<aks-cluster-name>
    AKS_K8S_VERSION_UPGRADE=<aks-k8s-version>

    az aks upgrade \
        --resource-group ${AKS_RESOURCE_GROUP} \
        --name ${AKS_CLUSTER_NAME} \
        --kubernetes-version ${AKS_K8S_VERSION_UPGRADE} \
        --control-plane-only
    ```

3. Add a new node-pool.

    ```
    AKS_NODEPOOL_NAME_NEW=<new-nodepool-name>
    AKS_DISK_SIZE=<disk-size-in-gb>
    AKS_NODE_NUM=<number-of-nodes>

    az aks nodepool add \
      --resource-group ${AKS_RESOURCE_GROUP} \
      --cluster-name ${AKS_CLUSTER_NAME} \
      --name ${AKS_NODEPOOL_NAME_NEW} \
      --node-count ${AKS_NODE_NUM} \
      --node-osdisk-size ${AKS_DISK_SIZE} \
      --kubernetes-version ${AKS_K8S_VERSION_UPGRADE} \
      --mode System
    ```

4. Using Longhorn UI to disable the disk scheduling and request eviction for nodes in the old node-pool.

5. Cordon and drain Kubernetes nodes in the old node-pool.
    ```
    AKS_NODEPOOL_NAME_OLD=<old-nodepool-name>

    for n in `kubectl get nodes | grep ${AKS_NODEPOOL_NAME_OLD}- | awk '{print $1}'`; do
      kubectl cordon $n && \
      kubectl drain $n --ignore-daemonsets --delete-emptydir-data
    done
    ```

6. Delete old node-pool.
    ```
    az aks nodepool delete \
      --cluster-name ${AKS_CLUSTER_NAME} \
      --name ${AKS_NODEPOOL_NAME_OLD} \
      --resource-group ${AKS_RESOURCE_GROUP}
    ```
