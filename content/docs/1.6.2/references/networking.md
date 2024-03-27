---
title: Longhorn Networking
weight: 3
---

### Overview

This page documents the networking communication between components in the Longhorn system. Using this information, users can write Kubernetes NetworkPolicy
to control the inbound/outbound traffic to/from Longhorn components. This helps to reduce the damage when a malicious pod breaks into the in-cluster network.

We have provided some NetworkPolicy example yamls at [here](https://github.com/longhorn/longhorn/tree/master/examples/network-policy).
Or you can enable the setting in the helm chart to install these NetworkPolicy [https://github.com/longhorn/longhorn/blob/master/chart/values.yaml]
Note that depending on the deployed [CNI](https://kubernetes.io/docs/concepts/extend-kubernetes/compute-storage-net/network-plugins/), not all Kubernetes clusters support NetworkPolicy.
See [here](https://kubernetes.io/docs/concepts/services-networking/network-policies/) for more detail.

> Note: If you are writing network policies, please revisit this page before upgrading Longhorn to make the necessary adjustments to your network policies.
> Note: Depending on your CNI for cluster network, there might be some delay when Kubernetes applying netowk policies to the pod. This delay may fail Longhorn recurring job for taking Snapshot or Backup of the Volume since it cannot access longhorn-manager in the beginning. This is a known issue found in K3s with Traefik and is beyond Longhorn control.

### Longhorn Manager
#### Ingress:
From | Port | Protocol
--- | --- | ---
`Other Longhorn Manager` | 9500 | TCP
`UI` | 9500 | TCP
`Longhorn CSI plugin` | 9500 | TCP
`Backup/Snapshot Recurring Job Pod` | 9500 | TCP
`Longhorn Driver Deployer` | 9500 | TCP
`Conversion Webhook Server` | 9501 | TCP
`Admission Webhook Server` | 9502 | TCP
`Recovery Backend Server` | 9503 | TCP

#### Egress:
To | Port | Protocol
--- | --- | ---
`Other Longhorn Manager` | 9500 | TCP
`Instance Manager` | 8500; 8501 | TCP
`Backing Image Manager` | 8000 | TCP
`Backing Image Data Source` | 8000 | TCP
`External Backupstore` | User defined | TCP
`Kubernetes API server` | `Kubernetes API server port` | TCP

### UI
#### ingress:
Users defined
#### egress:
To | Port | Protocol
--- | --- | ---
`Longhorn Manager` | 9500 | TCP

### Instance Manager
#### ingress
From | Port | Protocol
--- | --- | ---
`Longhorn Manager` | 8500; 8501 | TCP
`Other Instance Manager` | 10000-30000 | TCP
`Node in the Cluster` | 3260 | TCP
`Backing Image Data Source` | 10000-30000 | TCP

#### egress:
To | Port | Protocol
--- | --- | ---
`Other Instance Manager` | 10000-30000 | TCP
`Backing Image Data Source` |  8002 | TCP
`External Backupstore` | User defined | TCP

### Longhorn CSI plugin
#### ingress
None

#### egress:
To | Port | Protocol
--- | --- | ---
`Longhorn Manager` | 9500 | TCP

#### Additional Info
`Longhorn CSI plugin` pods communitate with `CSI sidecar` pods over the Unix Domain Socket at `<Kuberlet-Directory>/plugins/driver.longhorn.io/csi.sock`


### CSI sidecar (csi-attacher, csi-provisioner, csi-resizer, csi-snapshotter)
#### ingress:
None
#### egress:
To | Port | Protocol
--- | --- | ---
`Kubernetes API server` | `Kubernetes API server port` | TCP

#### Additional Info
`CSI sidecar` pods communitate with `Longhorn CSI plugin` pods over the Unix Domain Socket at `<Kuberlet-Directory>/plugins/driver.longhorn.io/csi.sock`

### Driver deployer
#### ingress:
None
#### egress:
To | Port | Protocol
--- | --- | ---
`Longhorn Manager` | 9500 | TCP
`Kubernetes API server` | `Kubernetes API server port` | TCP

### Engine Image
#### ingress:
None
#### egress:
None

### Backing Image Manager
#### ingress:
From | Port | Protocol
--- | --- | ---
`Longhorn Manager` | 8000 | TCP
`Other Backing Image Manager` | 30001-31000 | TCP

#### egress:
To | Port | Protocol
--- | --- | ---
`Instance Manager` | 10000-30000 | TCP
`Other Backing Image Manager` | 30001-31000 | TCP
`Backing Image Data Source` | 8000 | TCP

### Backing Image Data Source
#### ingress:
From | Port | Protocol
--- | --- | ---
`Longhorn Manager` | 8000 | TCP
`Instance Manager` | 8002 | TCP
`Backing Image Manager` | 8000 | TCP

#### egress:
To | Port | Protocol
--- | --- | ---
`Instance Manager` | 10000-30000 | TCP
`User provided server IP to download the images from` | user defined | TCP

### Share Manager
#### ingress
From | Port | Protocol
--- | --- | ---
`Node in the cluster` | 2049  | TCP

#### egress:
None

### Backup/Snapshot Recurring Job Pod
#### ingress:
None
#### egress:
To | Port | Protocol
--- | --- | ---
`Longhorn Manager` | 9500  | TCP

### Uninstaller
#### ingress:
None
#### egress:
To | Port | Protocol
--- | --- | ---
`Kubernetes API server` | `Kubernetes API server port` | TCP

### Discover Proc Kubelet Cmdline
#### ingress:
None
#### egress:
None

---
Original GitHub issue:
https://github.com/longhorn/longhorn/issues/1805
