---
title:  Manage Node-Group on GCP GKE
weight: 3
---

See [Migrating workloads to different machine types](https://cloud.google.com/kubernetes-engine/docs/tutorials/migrating-node-pool) for more information.

The following is an example to replace cluster nodes with new storage size.


## Storage Expansion

GKE supports adding additional disk with `local-ssd-count`. However, each local SSD is fixed size to 375 GB. We suggest expanding the node size via node pool replacement.

1. In Longhorn, set `replica-replenishment-wait-interval` to `0`.

2. Add a new node-pool. Later Longhorn components will be automatically deployed on the nodes in this pool.

    ```
    GKE_NODEPOOL_NAME_NEW=<new-nodepool-name>
    GKE_REGION=<gke-region>
    GKE_CLUSTER_NAME=<gke-cluster-name>
    GKE_IMAGE_TYPE=Ubuntu
    GKE_MACHINE_TYPE=<gcp-machine-type>
    GKE_DISK_SIZE_NEW=<new-disk-size-in-gb>
    GKE_NODE_NUM=<number-of-nodes>

    gcloud container node-pools create ${GKE_NODEPOOL_NAME_NEW} \
      --region ${GKE_REGION} \
      --cluster ${GKE_CLUSTER_NAME} \
      --image-type ${GKE_IMAGE_TYPE} \
      --machine-type ${GKE_MACHINE_TYPE} \
      --disk-size ${GKE_DISK_SIZE_NEW} \
      --num-nodes ${GKE_NODE_NUM}
  
    gcloud container node-pools list \
      --zone ${GKE_REGION} \
      --cluster ${GKE_CLUSTER_NAME} 
    ```

3. Using Longhorn UI to disable the disk scheduling and request eviction for nodes in the old node-pool.

4. Cordon and drain Kubernetes nodes in the old node-pool.
    ```
    GKE_NODEPOOL_NAME_OLD=<old-nodepool-name>
    for n in `kubectl get nodes | grep ${GKE_CLUSTER_NAME}-${GKE_NODEPOOL_NAME_OLD}- | awk '{print $1}'`; do
      kubectl cordon $n && \
      kubectl drain $n --ignore-daemonsets --delete-emptydir-data
    done
    ```

5. Delete old node-pool.
    ```
    gcloud container node-pools delete ${GKE_NODEPOOL_NAME_OLD}\
      --zone ${GKE_REGION} \
      --cluster ${GKE_CLUSTER_NAME}
    ```
