---
title: Node Conditions
weight: 7
---

Node conditions describe the status of all worker nodes and are used to check the environment settings of worker nodes to identify potential issues before any system impact.

Node conditions:

- `Ready`:  
  Indicates that the node is ready for Longhorn operations, including that a `longhorn-manager` pod is running on this node, the Kubernetes node is ready, and there is no physical resources pressure.  

- `Schedulable`:  
  Indicated that the node is not cordoned and workload can be scheduled to this node.

- `MountPropagation`:  
  Indicates that the node supports mount propagation. This is necessary for sharing of volumes mounted by a container with other containers in the same Longhorn pod, or to other Longhorn pods on the same node.  

- `Multipathd`:  
  Confirms if the `multipathd` service is not running on the node, which may affect the pod with the volume startup. See [Troubleshooting: `MountVolume.SetUp failed for volume` due to multipathd on the node](../../../../../../kb/troubleshooting-volume-with-multipath).  

- `RequiredPackages`:  
  Checks if all required packages ([NFS client](../../../deploy/install/#installing-nfsv4-client), [iSCSI tool](../../../deploy/install/#installing-open-iscsi), [cryptsetup](../../../deploy/install/#installing-cryptsetup-and-luks), [dmsetup](../../../deploy/install/#installing-device-mapper-userspace-tool)) exist for Longhorn  

- `NFSClientInstalled`:  
  Identifies if any of the following NFS clients are supported: `v4.2`, `v4.1`, or `v4.0`. NFS client is required for RWX volume and backup.  

Node conditions do not block the Longhorn deployment but they result in warnings in the Longhorn `Node` resource.
For more information, see [Longhorn Installation Requirements](../../../deploy/install/#installation-requirements).
