---
title: "Troubleshooting: Open-iSCSI on RHEL based systems"
author: Keith Lucas
draft: false
date: 2022-02-22
categories:
   - "iscsi"
---

## Applicable versions

All Longhorn versions.

## Symptons

The `iscsi.service` systemd service may add about 2-3 minutes to the boot up 
time of a node if the node is restarted with longhorn volumes attached to it.

## Background 

Longhorn uses [open-iscsi](https://www.open-iscsi.com/) to create block devices.
The RPM (`iscsi-initiator-utils`) for open-iscsi on Red Hat Enterprise Linux 
based systems has several system services.  The `iscsi.service` is for 
reestablishing iSCSI connections upon reboot by reading the _database_ stored
in `/var/lib/iscsi/nodes`.

Longhorn uses the `iscsiadm` command to create an 
iSCSI block device individually when a Longhorn volume is attached.  This 
creates a subdirectory in `/var/lib/iscsi/nodes`.  If Longhorn is able to 
detach the volume from the node, it will clean up the subdirectory in 
`/var/lib/iscsi/nodes`.  However, if the node crashes or is rebooted when a
Longhorn volume is attached to a pod running on that node, the subdirectory 
in `/var/lib/iscsi/nodes` will remain there.


## Solution
If the `iscsi.service` is enabled on the node, the service will attempt to 
discover the nodes left in `/var/lib/iscsi/nodes` subdirectories.  In most 
cases, Longhorn would be the only user of iSCSI on the node.  In that case,
it is recommended to disable the `iscsi.service` on the node:

```
systemctl disable iscsi.service
```

It may be possible to use the `iscsi.service` as intended for non-Longhorn
iSCSI devices.  In this case, it is necessary to not change the global 
`/etc/iscsi/iscsid.conf` for the non-Longhorn devices.  Longhorn relies on the
default configuration.   


