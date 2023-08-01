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
  diskSelector: "ssd,fast"
  nodeSelector: "storage,fast"
#  recurringJobSelector: '[{"name":"snap-group", "isGroup":true},
#                          {"name":"backup", "isGroup":false}]'
```

Some fields are common to all Kubernetes storage classes.
See also [Kubernetes Storage Class](https://kubernetes.io/docs/concepts/storage/storage-classes).  

#### Provisioner
Specifies the plugin that will be used for dynamic creation of persistent volumes.  For Longhorn, that is always "driver.longhorn.io"

#### Allow Volume Expansion
> Default: `true`

#### Reclaim Policy
> Default: `Delete`

#### Volume Binding Mode
> Default `Immediate`

## Longhorn-specific Parameters
Note that some of these parameters also exist and may be specified in global settings.  When a volume is provisioned with Kubernetes against a particular StorageClass, StorageClass parameters override the global settings.

#### Number Of Replicas
> Default: `3`  

The desired number of copies (replicas) for redundancy.  
  - Must be between 1 and 20.  
  - Replicas will be placed across the widest possible set of zones, nodes, and disks in a cluster, subject to other constraints, such as [Node Selector](#node-selector).  

> Global setting: [Default Replica Count](../settings#default-replica-count).

#### Stale Replica Timeout
> Default: `30`

Minutes after a replica is marked unhealthy before it is deemed useless for rebuilds and is just deleted.

#### From Backup
> Default: `""`  
> Example: `"s3://backupbucket@us-east-1?volume=minio-vol01&backup=backup-eeb2782d5b2f42bb"`

URL of a backup to be restored from.

#### FS Type
> Default: `ext4`  
> For more details, see [Creating Longhorn Volumes with Kubernetes](../../volumes-and-nodes/create-volumes#creating-longhorn-volumes-with-kubectl)

#### Mkfs Params
> Default: `""`  
> For more details, see [Creating Longhorn Volumes with Kubernetes](../../volumes-and-nodes/create-volumes#creating-longhorn-volumes-with-kubectl)

#### Migratable
> Default: `false`  

Allows for a Longhorn volume to be live migrated from one node to another.  Useful for volumes used by Harvester.
	  
#### Encrypted
> Default: `false`  
> More details in [Encrypted Volumes](../../advanced-resources/security/volume-encryptiom)

#### Data Locality
> Default: `disabled`  

If enabled, try to keep the data on the same node as the workload for better performance.  
  - For "best-effort", a replica will be co-located if possible, but is permitted to find another node if not.  
  - For "strict-local" the Replica count should be 1, or volume creation will fail with a parameter validation error.  
  - If "strict-local" is not possible for whatever other reason, volume creation will be failed.  A "strict-local" replica that becomes displaced from its workload will be marked as "Stopped".  

>  Global setting: [Default Data Locality](../settings#default-data-locality)  
>  More defails in [Data Locality](../../high-availability/data-locality).

#### Replica Auto-Balance
> Default: `ignored`  

If enabled, move replicas to more lightly-loaded nodes.  
  - "ignored" means use the global setting.  
  - Other options are "disabled", "least-effort", "best-effort."  

> Global setting: [Replica Auto Balance](../settings#replica-auto-balance)  
> More details in [Auto Balance Replicas](../../high-availability/auto-balance-replicas).

#### Disk Selector
> Default: `""`  
> Example: `"ssd,fast"`  

A list of tags to select which disks are candidates for replica placement.  
> More details in [Storage Tags](../../volumes-and-nodes/storage-tags)

#### Node Selector
> Default: `""`  
> Example: `"storage,fast"`  

A list of tags to select which nodes are candidates for replica placement.  
> More details in [Storage Tags](../../volumes-and-nodes/storage-tags)

#### Recurring Jobs Selector
A list of recurring jobs that are to be run on a volume.  
> Default: `""`  
> Example:  `[{"name":"backup", "isGroup":true}]`  

>  More details in [Recurring Snapshots and Backups](../../snapshots-and-backups/scheduling-backups-and-snapshots) 
	
#### Backing Image Name
> Default: `""`  
> See [Backing Images](../../advanced-resources/backing-images#create-and-use-a-backing-image-via-storageclass-and-pvc)

#### Backing Image Checksum
> Default: `""`  
> See [Backing Images](../../advanced-resources/backing-images#create-and-use-a-backing-image-via-storageclass-and-pvc)

#### Backing Image Data Source Type
> Default: `""`  
> See [Backing Images](../../advanced-resources/backing-images#create-and-use-a-backing-image-via-storageclass-and-pvc)

#### Backing Image Data Source Parameters
> Default: `""`  
> See [Backing Images](../../advanced-resources/backing-images#create-and-use-a-backing-image-via-storageclass-and-pvc)

#### Remove Snapshots During Filesystem Trim
> Default: `ignored`  

  - "ignored" means use the global setting.  
  - Other values are "enabled" and "disabled.  

> Global setting: [Remove Snapshots During Filesystem Trim](../settings#remove-snapshots-during-filesystem-trim).  
> More details in [Trim Filesystem](../../volumes-and-nodes/trim-filesystem).

## Helm Installs

If Longhorn is installed via Helm, values in the default storage class can be set by editing the corresponding item in [values.yaml](https://github.com/longhorn/longhorn/blob/v{{< current-version >}}/chart/values.yaml).  All of the Storage Class parameters have a prefix of "persistence".  For example, `persistence.defaultNodeSelector`.

