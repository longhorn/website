---
title: Use Longhorn Volume as an iSCSI Target
weight: 4
---

Longhorn supports iSCSI target frontend mode. You can connect to it
through any iSCSI client, including `open-iscsi`, and virtual machine
hypervisor like KVM, as long as it's in the same network as the Longhorn system.

The Longhorn CSI driver doesn't support iSCSI mode.

To start a volume with the iSCSI target frontend mode, select `iSCSI` as the frontend when [creating the volume.](../../volumes-and-nodes/create-volumes)

After the volume has been attached, you will see something like the following in the `endpoint` field:

```text
iscsi://10.42.0.21:3260/iqn.2014-09.com.rancher:testvolume/1
```

In this example,

- The IP and port is `10.42.0.21:3260`.
- The target name is `iqn.2014-09.com.rancher:testvolume`.
- The volume name is `testvolume`.
- The LUN number is 1. Longhorn always uses LUN 1.

The above information can be used to connect to the iSCSI target provided by Longhorn using an iSCSI client.
