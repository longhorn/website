---
title: Storage Network
weight: 8
---

By Default, Longhorn uses the default Kubernetes cluster CNI network that is limited to a single interface and shared with other workloads cluster-wide. In case you have a situation where network segregation is needed, Longhorn supports isolating Longhorn in-cluster data traffic with the Storage Network setting.

The Storage Network setting takes Multus NetworkAttachmentDefinition in `<NAMESPACE>/<NAME>` format.

You can refer to [Comprehensive Document](https://github.com/k8snetworkplumbingwg/multus-cni#comprehensive-documentation) for how to install and set up Multus NetworkAttachmentDefinition.

Applying the setting will add `k8s.v1.cni.cncf.io/networks` annotation and recreate all existing instance-manager, and backing-image-manager pods.
Longhorn will apply the same annotation to any new instance-manager, backing-image-manager, and backing-image-data-source pods.

> **Important**: To ensure that your preferred settings are immediately applied, stop all workloads and detach all Longhorn volumes before configuring the settings.
>
> When all volumes are detached, Longhorn attempts to restart all Instance Manager and Backing Image Manager pods to apply the setting.
> When one or more Longhorn volumes are still attached, the customized setting is applied to the Instance Manager only when no engines and replica instances are running. You are required to reconfigure the setting after detaching the remaining volumes. Alternatively, you can wait for the next setting synchronization, which will occur in an hour.

# Setting Storage Network

## Prerequisite

The Multus NetworkAttachmentDefinition network for the storage network setting must be reachable in pods across different cluster nodes.

You can verify by creating a simple DaemonSet and try ping between pods.

### Setting Storage Network During Longhorn Installation
Follow the [Customize default settings](../customizing-default-settings/) to set Storage Network by changing the value for the `storage-network` default setting

> **Warning:** Longhorn instance-manager will not start if the Storage Network setting is invalid.
>
> You can check the events of the instance-manager Pod to see if it is related to an invalid NetworkAttachmentDefinition with `kubectl -n longhorn-system describe pods -l longhorn.io/component=instance-manager`.
>
> If this is the case, provide a valid `NetworkAttachmentDefinition` and re-run Longhorn install.

### Setting Storage Network After Longhorn Installation

Set the setting [Storage Network](../../../references/settings#storage-network).

> **Warning:** Do not modify the NetworkAttachmentDefinition custom resource after applying it to the setting.
>
> Longhorn is not aware of the updates. Hence this will cause malfunctioning and error. Instead, you can create a new NetworkAttachmentDefinition custom resource and update it to the setting.

### Setting Storage Network For RWX Volumes

Configure the setting [Storage Network For RWX Volume Enabled](../../../references/settings#storage-network-for-rwx-volume-enabled).

# Limitation

When an RWX volume is created with the storage network, the NFS mount point connection must be re-established when the CSI plugin pod restarts. Longhorn provides the [Automatically Delete Workload Pod when The Volume Is Detached Unexpectedly](../../../references/settings#automatically-delete-workload-pod-when-the-volume-is-detached-unexpectedly) setting, which automatically deletes RWX volume workload pods when the CSI plugin pod restarts. However, the workload pod's NFS mount point could become unresponsive when the setting is disabled or the pod is not managed by a controller. In such cases, you must manually restart the CSI plugin pod.

For more information, see [Storage Network Support for Read-Write-Many (RWX) Volume](../../../../1.7.0/important-notes/#storage-network-support-for-read-write-many-rwx-volumes) in Important Notes.

# History
- [Original Feature Request (since v1.3.0)](https://github.com/longhorn/longhorn/issues/2285)
- [[FEATURE] Support storage network for RWX volumes (since v1.7.0)](https://github.com/longhorn/longhorn/issues/8184)
- [[FEATURE] Storage network with V2 data engine (since v1.9.0)](https://github.com/longhorn/longhorn/issues/6450)
