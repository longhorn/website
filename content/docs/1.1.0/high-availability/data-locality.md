---
  title: Data Locality
  weight: 1
---

A Longhorn volume can be backed by replicas on some nodes in the cluster and accessed by a pod running on any node in the cluster.
In some cases, it is desired to have a local replica on the same node as the pod which uses the volume.
We refer to the property of having a local replica as having `data locality`

For example, when the cluster's network is bad, having a local replica increase the availability of the volume.
Another example is that an application workload can do replication itself (e.g. database) and it wants to have a volume of 1 replica for each pod.
Without the `data locality` turned on, multiple replicas may end up on the same node which destroys the replication intention of the workload.


## Data Locality Settings

Longhorn currently supports 2 modes for data locality settings:
- `disabled`. This is the default option.
   There may or may not be a replica on the same node as the attached volume (workload).

- `best-effort`. This option instructs Longhorn to try to keep a replica on the same node as the attached volume (workload).
   Longhorn will not stop the volume, even if it cannot keep a replica local to the attached volume (workload) due to environment limitation, e.g. not enough disk space, incompatible disk tags, etc.


## How to Set Data Locality For Volumes

There are 3 ways to set data locality for Longhorn volumes:

### Change the default global setting

You can change the global default setting for data locality inside Longhorn UI settings.
The global setting only functions as a default value, similar replica count.
It doesn't change any existing volume's setting
When a volume is created without specifying data locality, Longhorn will use the global default setting to determine data locality for the volume.

### Change data locality for individual volume using Longhorn UI

You can use Longhorn UI to set data locality for volume upon creation.
You can also change the data locality setting for the volume after creation in the volume detail page.

### Set data locality for individual volume using Storage Class
Longhorn also exposes the data locality setting as a parameter in storage class.
You can create a storage class with a specified data locality setting, then create PVCs using the storage class.
For example, the below yaml file defines a storage class which tells Longhorn CSI driver to set data locality to `best-effort`:

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

