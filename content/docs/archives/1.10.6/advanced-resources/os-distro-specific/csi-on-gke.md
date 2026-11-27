---
title:  Longhorn CSI on GKE
weight: 3
---

To operate Longhorn on a cluster provisioned with Google Kubernetes Engine, some additional configuration is required.

1. GKE clusters must use the `Ubuntu` OS instead of `Container-Optimized` OS, in order to satisfy Longhorn's `open-iscsi` dependency.

2. GKE requires a user to manually claim themselves as cluster admin to enable role-based access control. Before installing Longhorn, run the following command:

    ```shell
    kubectl create clusterrolebinding cluster-admin-binding --clusterrole=cluster-admin --user=<name@example.com>
    ```

    where `name@example.com` is the user's account name in GCE.  It's case sensitive. See [this document](https://cloud.google.com/kubernetes-engine/docs/how-to/role-based-access-control) for more information.