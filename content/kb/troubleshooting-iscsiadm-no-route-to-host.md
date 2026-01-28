---
title: "Troubleshooting: iSCSId has no route to instance manager pod"
authors:
- "Raphanus Lo"
draft: false
date: 2026-01-28
versions:
- "all"
categories:
- "iscsi"
- "network"
- "volume attachment"
---

## Applicable versions

* All Longhorn versions

## Symptoms

* On the affected node, volume attachment always fails.
* On that node, the instance manager pod log shows `iscsiadm: cannot make connection to 10.52.0.55: No route to host` (where `10.52.0.55` is the instance manager pod IP).
    ```
    [pvc-a475fe89-3cf0-4d02-b944-e3c81b166f6e-e-0] time="2026-01-26T10:40:35Z" level=warning
    msg="Failed to discover" func="iscsidev.(*Device).StartInitator"
    file="iscsi.go:161"
    error="failed to execute: /usr/bin/nsenter [nsenter --mount=/host/proc/ 11472/ns/mnt --net=/host/proc/11472/ns/net iscsiadm -m discovery -t sendtargets -p 10.52.0.55], output , stderr iscsiadm:
    cannot make connection to 10.52.0.55: No route to host\n
    iscsiadm: cannot make connection to 10.52.0.55: No route to host\n
    iscsiadm: cannot make connection to 10.52.0.55: No route to host\n
    iscsiadm: cannot make connection to 10.52.0.55: No route to host\n
    iscsiadm: cannot make connection to 10.52.0.55: No route to host\n
    iscsiadm: cannot make connection to 10.52.0.55: No route to host\n
    iscsiadm: connection login retries (reopen_max) 5 exceeded\n
    iscsiadm: Could not perform SendTargets discovery: iSCSI PDU timed out:
    exit status 11"
    ```
* On that node, running `iscsiadm -m discovery -t sendtargets -p 10.52.0.55` also returns `No route to host`.

## Root Cause and Impact on Longhorn

Longhorn relies on a host-to-pod loopback iSCSI path, where the host iSCSI initiator connects directly to the instance manager pod IP. All volume attachments depend on successfully establishing this local iSCSI session.

The failure is caused by stale or misconfigured iSCSI iface entries on the host. When a custom iSCSI iface is created (for example, binding discovery to a specific NIC or MAC address), `iscsiadm` may route discovery and login traffic through an interface that is not reachable from the network namespace used by Longhorn.

Because the instance manager runs inside a pod network namespace, this routing mismatch commonly results in `No route to host` errors during iSCSI discovery or login. As a result, no iSCSI session can be established and the volume attachment fails.

## Environment Correction

The goal of the following steps is to remove stale or misconfigured iSCSI iface and node cache entries that force iSCSI traffic onto an incorrect interface. This allows the iSCSI initiator to fall back to the default interface and routing behavior required for Longhorn's host-to-pod iSCSI connection.

Notice that these steps are disruptive and will log out existing iSCSI sessions.

Replace `${instance_manager_pod_ip}` with the actual instance manager pod IP.
Replace `${some_interface}` only if a custom iSCSI iface was previously created.

1. Reproduce or verify discovery (expected to fail before fixes and succeed after):
    ```
    iscsiadm -m discovery -t sendtargets -p ${instance_manager_pod_ip}
    ```
2. Logout existing sessions (disruptive):
    ```
    iscsiadm -m node --logout
    ```
3. Remove iface cache (use the correct iface name):
    ```
    iscsiadm -m iface -I ${some_interface} --op=delete
    ```
4. Remove node cache:
    ```
    iscsiadm -m node --op=delete
    ```
5. Restart iscsid (systemd example; other init systems vary):
    ```
    systemctl restart iscsid
    ```

After cleanup, ensure that host-to-pod routing and firewall rules allow traffic to the instance manager pod IP. Re-run iSCSI discovery to confirm that the `No route to host` error is resolved.

## Related Information

* [Troubleshooting Orphan iSCSI Session Error](../troubleshooting-orphan-iscsi-session-error)
* [Troubleshooting Open iSCSI on RHEL](../troubleshooting-open-iscsi-on-rhel)
* [Troubleshooting Volume Attachment Fails Due to SELinux Denials](../troubleshooting-volume-attachment-fails-due-to-selinux-denials)

## Not Covered

* CHAP or authentication configuration, SELinux policy tuning beyond basic
mention, multipath specifics, and non-iSCSI attachment failures.
