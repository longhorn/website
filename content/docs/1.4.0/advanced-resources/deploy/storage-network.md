---
title: Storage Network
weight: 8
---

By Default, Longhorn uses the default Kubernetes cluster CNI network that is limited to a single interface and shared with other workloads cluster-wide. In case you have a situation where network segregation is needed, Longhorn supports isolating Longhorn in-cluster data traffic with the Storage Network setting.

The Storage Network setting takes Multus NetworkAttachmentDefinition in `<NAMESPACE>/<NAME>` format.

You can refer to [Comprehensive Document](https://github.com/k8snetworkplumbingwg/multus-cni#comprehensive-documentation) for how to install and set up Multus NetworkAttachmentDefintion.

Applying the setting will add `k8s.v1.cni.cncf.io/networks` annotation and recreate all existing instance-manager, and backing-image-manager pods.
Longhorn will apply the same annotation to any new instance-manager, backing-image-manager, and backing-image-data-source pods.

> **Warning**: Do not change this setting with volumes attached.
>
> Longhorn will try to block this setting update when there are attached volumes.

# Setting Storage Network

## Prerequisite

The Multus NetworkAttachmentDefinition network for the storage network setting must be reachable in pods across different cluster nodes.

You can verify by creating a simple DaemonSet and try ping between pods.

### Setting Storage Network During Longhorn Installation
Follow the [Customize default settings](../customizing-default-settings/) to set Storage Network by changing the value for the `storage-network` default setting

> **Warning:** Longhorn instance-manager will not start if the Storage Network setting is invalid.
>
> You can check the events of the instance-manager Pod to see if it is related to an invalid NetworkAttachmentDefintion with `kubectl -n longhorn-system describe pods -l longhorn.io/component=instance-manager`.
>
> If this is the case, provide a valid `NetworkAttachmentDefinition` and re-run Longhorn install.

### Setting Storage Network After Longhorn Installation

Set the setting [Storage Network](../../../references/settings#storage-network).

> **Warning:** Do not modify the NetworkAttachmentDefinition custom resource after applying it to the setting.
>
> Longhorn is not aware of the updates. Hence this will cause malfunctioning and error. Instead, you can create a new NetworkAttachmentDefinition custom resource and update it to the setting.

## History
[Original Feature Request](https://github.com/longhorn/longhorn/issues/2285)

Available since v1.3.0
