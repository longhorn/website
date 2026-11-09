---
title:  Manage Node-Group on Azure AKS
weight: 2
---

See [Create and manage multiple node pools for a cluster in Azure Kubernetes Service (AKS)](https://docs.microsoft.com/en-us/azure/aks/use-multiple-node-pools) for more information.

Following is an example to replace cluster nodes with a new storage size.


## Storage Expansion

AKS does not support additional disk in its [template](https://docs.microsoft.com/en-us/azure/templates/Microsoft.ContainerService/2022-01-01/managedclusters?tabs=bicep#template-format). It is possible for manual disk attachment. Then raw device needs to be mounted either by manually mounting in VM or during launch with CustomScriptExtension that [is not supported](https://docs.microsoft.com/en-us/azure/aks/support-policies#user-customization-of-agent-nodes) in AKS.

1. In Longhorn, set `replica-replenishment-wait-interval` to `0`.

2. Add a new node-pool. Later Longhorn components will be automatically deployed on the nodes in this pool.

    ```
    AKS_NODEPOOL_NAME_NEW=<new-nodepool-name>
    AKS_RESOURCE_GROUP=<aks-resource-group>
    AKS_CLUSTER_NAME=<aks-cluster-name>
    AKS_DISK_SIZE_NEW=<new-disk-size-in-gb>
    AKS_NODE_NUM=<number-of-nodes>
    AKS_K8S_VERSION=<kubernetes-version>

    az aks nodepool add \
      --resource-group ${AKS_RESOURCE_GROUP} \
      --cluster-name ${AKS_CLUSTER_NAME} \
      --name ${AKS_NODEPOOL_NAME_NEW} \
      --node-count ${AKS_NODE_NUM} \
      --node-osdisk-size ${AKS_DISK_SIZE_NEW} \
      --kubernetes-version ${AKS_K8S_VERSION} \
      --mode System
    ```

3. Using Longhorn UI to disable the disk scheduling and request eviction for nodes in the old node-pool.

4. Cordon and drain Kubernetes nodes in the old node-pool.
    ```
    AKS_NODEPOOL_NAME_OLD=<old-nodepool-name>

    for n in `kubectl get nodes | grep ${AKS_NODEPOOL_NAME_OLD}- | awk '{print $1}'`; do
      kubectl cordon $n && \
      kubectl drain $n --ignore-daemonsets --delete-emptydir-data
    done
    ```

5. Delete old node-pool.
    ```
    az aks nodepool delete \
      --cluster-name ${AKS_CLUSTER_NAME} \
      --name ${AKS_NODEPOOL_NAME_OLD} \
      --resource-group ${AKS_RESOURCE_GROUP}
    ```
