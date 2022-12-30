---
  title: Data Locality
  weight: 1
---

The data locality setting is intended to be enabled in situations where at least one replica of a Longhorn volume should be scheduled on the same node as the pod that uses the volume, whenever it is possible. We refer to the property of having a local replica as having `data locality`.

For example, data locality can be useful when the cluster's network is bad, because having a local replica increases the availability of the volume.

Data locality can also be useful for distributed applications (e.g. databases), in which high availability is achieved at the application level instead of the volume level. In that case, only one volume is needed for each pod, so each volume should be scheduled on the same node as the pod that uses it.  In addition, the default Longhorn behavior for volume scheduling could cause a problem for distributed applications. The problem is that if there are two replicas of a pod, and each pod replica has one volume each, Longhorn is not aware that those volumes have the same data and should not be scheduled on the same node. Therefore Longhorn could schedule identical replicas on the same node, therefore preventing them from providing high availability for the workload.

When data locality is disabled, a Longhorn volume can be backed by replicas on any nodes in the cluster and accessed by a pod running on any node in the cluster.

## Data Locality Settings

Longhorn currently supports two modes for data locality settings:

- `disabled`. This is the default option. There may or may not be a replica on the same node as the attached volume (workload).

- `best-effort`. This option instructs Longhorn to try to keep a replica on the same node as the attached volume (workload). Longhorn will not stop the volume, even if it cannot keep a replica local to the attached volume (workload) due to an environment limitation, e.g. not enough disk space, incompatible disk tags, etc.


## How to Set Data Locality For Volumes

There are three ways to set data locality for Longhorn volumes:

### Change the default global setting

You can change the global default setting for data locality inside Longhorn UI settings.
The global setting only functions as a default value, similar to the replica count.
It doesn't change any existing volume's settings.
When a volume is created without specifying data locality, Longhorn will use the global default setting to determine data locality for the volume.

### Change data locality for an individual volume using the Longhorn UI

You can use Longhorn UI to set data locality for volume upon creation.
You can also change the data locality setting for the volume after creation in the volume detail page.

### Set the data locality for individual volumes using a StorageClass
Longhorn also exposes the data locality setting as a parameter in a StorageClass.
You can create a StorageClass with a specified data locality setting, then create PVCs using the StorageClass.
For example, the below YAML file defines a StorageClass which tells the Longhorn CSI driver to set the data locality to `best-effort`:

```yaml
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: hyper-converged
provisioner: driver.longhorn.io
allowVolumeExpansion: true
parameters:
  numberOfReplicas: "2"
  dataLocality: "best-effort"
  staleReplicaTimeout: "2880" # 48 hours in minutes
  fromBackup: ""
```

