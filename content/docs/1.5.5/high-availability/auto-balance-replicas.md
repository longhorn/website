---
  title: Auto Balance Replicas
  weight: 1
---

When replicas are scheduled unevenly on nodes or zones, Longhorn `Replica Auto Balance` setting enables the replicas for automatic balancing when a new node is available to the cluster.

## Replica Auto Balance Settings

### Global setting
Longhorn supports 3 options for global replica auto-balance setting:

- `disabled`. This is the default option, no replica auto-balance will be done.

- `least-effort`. This option instructs Longhorn to balance replicas for minimal redundancy.
  For example, after adding node-2, a volume with 4 off-balanced replicas will only rebalance 1 replica.
    ```
    node-1
    +-- replica-a
    +-- replica-b
    +-- replica-c
    node-2
    +-- replica-d
    ```

- `best-effort`. This option instructs Longhorn to try balancing replicas for even redundancy.
  For example, after adding node-2, a volume with 4 off-balanced replicas will rebalance 2 replicas.
    ```
    node-1
    +-- replica-a
    +-- replica-b
    node-2
    +-- replica-c
    +-- replica-d
    ```
  Longhorn does not forcefully re-schedule the replicas to a zone that does not have enough nodes
  to support even balance. Instead, Longhorn will re-schedule to balance at the node level.

### Volume specific setting
Longhorn also supports setting individual volume for `Replica Auto Balance`. The setting can be specified in `volume.spec.replicaAutoBalance`, this overrules the global setting.

There are 4 options available for individual volume setting:

- `Ignored`. This is the default option that instructs Longhorn to inherit from the global setting.

- `disabled`. This option instructs Longhorn no replica auto-balance should be done.

- `least-effort`. This option instructs Longhorn to balance replicas for minimal redundancy.
  For example, after adding node-2, a volume with 4 off-balanced replicas will only rebalance 1 replica.
    ```
    node-1
    +-- replica-a
    +-- replica-b
    +-- replica-c
    node-2
    +-- replica-d
    ```

- `best-effort`. This option instructs Longhorn to try balancing replicas for even redundancy.
  For example, after adding node-2, a volume with 4 off-balanced replicas will rebalance 2 replicas.
    ```
    node-1
    +-- replica-a
    +-- replica-b
    node-2
    +-- replica-c
    +-- replica-d
    ```
  Longhorn does not forcefully re-schedule the replicas to a zone that does not have enough nodes
  to support even balance. Instead, Longhorn will re-schedule to balance at the node level.


## How to Set Replica Auto Balance For Volumes

There are 3 ways to set `Replica Auto Balance` for Longhorn volumes:

### Change the global setting

You can change the global default setting for `Replica Auto Balance` inside Longhorn UI settings.
The global setting only functions as a default value, similar to the replica count.
It doesn't change any existing volume settings.
When a volume is created without specifying `Replica Auto Balance`, Longhorn will automatically set to `ignored` to inherit from the global setting.

### Set individual volumes to auto-balance replicas using the Longhorn UI

You can change the `Replica Auto Balance` setting for individual volume after creation on the volume detail page, or do multiple updates on the listed volume page.

### Set individual volumes to auto-balance replicas using a StorageClass
Longhorn also exposes the `Replica Auto Balance` setting as a parameter in a StorageClass.
You can create a StorageClass with a specified `Replica Auto Balance` setting, then create PVCs using this StorageClass.

For example, the below YAML file defines a StorageClass which tells the Longhorn CSI driver to set the `Replica Auto Balance` to `least-effort`:

```yaml
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: hyper-converged
provisioner: driver.longhorn.io
allowVolumeExpansion: true
parameters:
  numberOfReplicas: "3"
  replicaAutoBalance: "least-effort"
  staleReplicaTimeout: "2880" # 48 hours in minutes
  fromBackup: ""
```
