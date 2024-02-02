---
title: Storage Class Parameters
weight: 1
---

## Overview

Storage Class as a resource object has a number of settable parameters.  Here's a sample YAML:
```yaml
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: longhorn-test
provisioner: driver.longhorn.io
allowVolumeExpansion: true
reclaimPolicy: Delete
volumeBindingMode: Immediate
parameters:
  numberOfReplicas: "3"
  staleReplicaTimeout: "2880"
  fromBackup: ""
  fsType: "ext4"
#  mkfsParams: ""
#  migratable: false
#  encrypted: false
#  dataLocality: "disabled"
#  replicaAutoBalance: "ignored"
#  diskSelector: "ssd,fast"
#  nodeSelector: "storage,fast"
#  recurringJobSelector: '[{"name":"snap-group", "isGroup":true},
#                          {"name":"backup", "isGroup":false}]'
#  backingImageName: ""
#  backingImageChecksum: ""
#  backingImageDataSourceType: ""
#  backingImageDataSourceParameters: ""
#  unmapMarkSnapChainRemoved: "ignored"
#  disableRevisionCounter: false
#  replicaSoftAntiAffinity: "ignored"
#  replicaZoneSoftAntiAffinity: "ignored"
#  replicaDiskSoftAntiAffinity: "ignored"
#  nfsOptions: "soft,timeo=150,retrans=3"
#  v1DataEngine: true
#  v2DataEngine: false
```

## Built-in Fields
Some fields are common to all Kubernetes storage classes.
See also [Kubernetes Storage Class](https://kubernetes.io/docs/concepts/storage/storage-classes).  

#### Provisioner *(field: `provisioner`)*
Specifies the plugin that will be used for dynamic creation of persistent volumes.  For Longhorn, that is always "driver.longhorn.io".
> See [Kubernetes Storage Class: Provisioner](https://kubernetes.io/docs/concepts/storage/storage-classes/#provisioner).  

#### Allow Volume Expansion *(field: `allowVolumeExpansion`)*
> Default: `true`  
> See [Kubernetes Storage Class: Allow Volume Expansion](https://kubernetes.io/docs/concepts/storage/storage-classes/#allow-volume-expansion).  

#### Reclaim Policy *(field: `reclaimPolicy`)*
> Default: `Delete`  
> See [Kubernetes Storage Class: Reclaim Policy](https://kubernetes.io/docs/concepts/storage/storage-classes/#reclaim-policy).  

#### Mount Options *(field: `mountOptions`)*
> Default `[]`  
> See [Kubernetes Storage Class: Mount Options](https://kubernetes.io/docs/concepts/storage/storage-classes/#mount-options).  

#### Volume Binding Mode *(field: `volumeBindingMode`)*
> Default `Immediate`  
> See [Kubernetes Storage Class: Volume Binding Mode](https://kubernetes.io/docs/concepts/storage/storage-classes/#volume-binding-mode).  

## Longhorn-specific Parameters
Note that some of these parameters also exist and may be specified in global settings.  When a volume is provisioned with Kubernetes against a particular StorageClass, StorageClass parameters override the global settings.  
These fields will be applied for new volume creation only.  If a StorageClass is modified, neither Longhorn nor Kubernetes is responsible for propagating changes to its parameters back to volumes previously created with it.

#### Number Of Replicas *(field: `parameters.numberOfReplicas`)*
> Default: `3`  

The desired number of copies (replicas) for redundancy.  
  - Must be between 1 and 20.  
  - Replicas will be placed across the widest possible set of zones, nodes, and disks in a cluster, subject to other constraints, such as NodeSelector.

> Global setting: [Default Replica Count](../settings#default-replica-count).

#### Stale Replica Timeout *(field: `parameters.staleReplicaTimeout`)*
> Default: `30`

Minutes after a replica is marked unhealthy before it is deemed useless for rebuilds and is just deleted.

#### From Backup *(field: `parameters.fromBackup`)*
> Default: `""`  
> Example: `"s3://backupbucket@us-east-1?volume=minio-vol01&backup=backup-eeb2782d5b2f42bb"`

URL of a backup to be restored from.

#### FS Type *(field: `parameters.fsType`)*
> Default: `ext4`  
> For more details, see [Creating Longhorn Volumes with Kubernetes](../../nodes-and-volumes/volumes/create-volumes#creating-longhorn-volumes-with-kubectl)

#### Mkfs Params *(field: `parameters.mkfsParams`)*
> Default: `""`  
> For more details, see [Creating Longhorn Volumes with Kubernetes](../../nodes-and-volumes/volumes/create-volumes#creating-longhorn-volumes-with-kubectl)

#### Migratable *(field: `parameters.migratable`)*
> Default: `false`  

Allows for a Longhorn volume to be live migrated from one node to another.  Useful for volumes used by Harvester.

#### Encrypted *(field: `parameters.encrypted`)*
> Default: `false`  
> More details in [Encrypted Volumes](../../advanced-resources/security/volume-encryption)

#### Data Locality *(field: `parameters.dataLocality`)*
> Default: `disabled`  

If enabled, try to keep the data on the same node as the workload for better performance.  
  - For "best-effort", a replica will be co-located if possible, but is permitted to find another node if not.  
  - For "strict-local" the Replica count should be 1, or volume creation will fail with a parameter validation error.  
  - If "strict-local" is not possible for whatever other reason, volume creation will be failed.  A "strict-local" replica that becomes displaced from its workload will be marked as "Stopped".  

>  Global setting: [Default Data Locality](../settings#default-data-locality)  
>  More details in [Data Locality](../../high-availability/data-locality).

#### Replica Auto-Balance *(field: `parameters.replicaAutoBalance`)*
> Default: `ignored`  

If enabled, move replicas to more lightly-loaded nodes.  
  - "ignored" means use the global setting.  
  - Other options are "disabled", "least-effort", "best-effort".  

> Global setting: [Replica Auto Balance](../settings#replica-auto-balance)  
> More details in [Auto Balance Replicas](../../high-availability/auto-balance-replicas).

#### Disk Selector *(field: `parameters.diskSelector`)*
> Default: `""`  
> Example: `"ssd,fast"`  

A list of tags to select which disks are candidates for replica placement.  
> More details in [Storage Tags](../../nodes-and-volumes/nodes/storage-tags)

#### Node Selector *(field: `parameters.nodeSelector`)*
> Default: `""`  
> Example: `"storage,fast"`  

A list of tags to select which nodes are candidates for replica placement.  
> More details in [Storage Tags](../../nodes-and-volumes/nodes/storage-tags)

#### Recurring Jobs Selector *(field: `parameters.recurringJobsSelector`)*
> Default: `""`  
> Example:  `[{"name":"backup", "isGroup":true}]`  

A list of recurring jobs that are to be run on a volume.  
>  More details in [Recurring Snapshots and Backups](../../snapshots-and-backups/scheduling-backups-and-snapshots) 

#### Backing Image Name *(field: `parameters.backingImageName`)*
> Default: `""`  
> See [Backing Image](../../advanced-resources/backing-image/backing-image#create-and-use-a-backing-image-via-storageclass-and-pvc)

#### Backing Image Checksum *(field: `parameters.backingImageChecksum`)*
> Default: `""`  
> See [Backing Image](../../advanced-resources/backing-image/backing-image#create-and-use-a-backing-image-via-storageclass-and-pvc)

#### Backing Image Data Source Type *(field: `parameters.backingImageDataSourceType`)*
> Default: `""`  
> See [Backing Image](../../advanced-resources/backing-image/backing-image#create-and-use-a-backing-image-via-storageclass-and-pvc)

#### Backing Image Data Source Parameters *(field: `parameters.backingImageDataSourceParameters`)*
> Default: `""`  
> See [Backing Image](../../advanced-resources/backing-image/backing-image#create-and-use-a-backing-image-via-storageclass-and-pvc)

#### Unmap Mark Snap Chain Removed *(field: `parameters.unmapMarkSnapChainRemoved`)*
> Default: `ignored`  

  - "ignored" means use the global setting.  
  - Other values are "enabled" and "disabled".  

> Global setting: [Remove Snapshots During Filesystem Trim](../settings#remove-snapshots-during-filesystem-trim).  
> More details in [Trim Filesystem](../../nodes-and-volumes/volumes/trim-filesystem).

#### Disable Revision Counter *(field: `parameters.disableRevisionCounter`)*
> Default: `false`  

> Global setting: [Disable Revision Counter](../settings#disable-revision-counter).  
> More details in [Revision Counter](../../advanced-resources/deploy/revision_counter).  

#### Replica Soft Anti-Affinity *(field: `parameters.replicaSoftAntiAffinity`)*
> Default: `ignored`  

  - "ignored" means use the global setting.  
  - Other values are "enabled" and "disabled".  

> Global setting: [Replica Node Level Soft Anti-Affinity](../settings#replica-node-level-soft-anti-affinity).  
> More details in [Scheduling](../../nodes-and-volumes/nodes/scheduling) and [Best Practices](../../best-practices#replica-node-level-soft-anti-affinity).

#### Replica Zone Soft Anti-Affinity *(field: `parameters.replicaZoneSoftAntiAffinity`)*
> Default: `ignored`  

  - "ignored" means use the global setting.  
  - Other values are "enabled" and "disabled".  

> Global setting: [Replica Zone Level Soft Anti-Affinity](../settings#replica-zone-level-soft-anti-affinity).  
> More details in [Scheduling](../../nodes-and-volumes/nodes/scheduling).

#### Replica Disk Soft Anti-Affinity *(field: `parameters.replicaDiskSoftAntiAffinity`)*
> Default: `ignored`  

  - "ignored" means use the global setting.  
  - Other values are "enabled" and "disabled".  

> Global setting: [Replica Disk Level Soft Anti-Affinity](../settings#replica-disk-level-soft-anti-affinity).  
> More details in [Scheduling](../../nodes-and-volumes/nodes/scheduling).

#### NFS Options *(field: `parameters.nfsOptions`)*
> Default: `""`
> Example: `"hard,sync"`  

  - Overrides for NFS mount of RWX volumes to the share-manager.  Use this field with caution.  
  - Note:  Built-in options vary by release.  Check your release details before setting this.  
 
> More details in [RWX Workloads](../../nodes-and-volumes/volumes/rwx-volumes#configuring-volume-mount-options)

#### Data Engine *(field: `parameters.dataEngine`)*
> Default: `"v1"`  

  - Specify "v2" to enable the V2 Data Engine (preview feature in v1.6.0). When unspecified, Longhorn uses the default value ("v1").

> Global setting: [V2 Data Engine](../settings#v2-data-engine).  
> More details in [V2 Data Engine Quick Start](../../v2-data-engine/quick-start#create-a-storageclass).

## Helm Installs

If Longhorn is installed via Helm, values in the default storage class can be set by editing the corresponding item in [values.yaml](https://github.com/longhorn/longhorn/blob/v{{< current-version >}}/chart/values.yaml).  All of the Storage Class parameters have a prefix of "persistence".  For example, `persistence.defaultNodeSelector`.

