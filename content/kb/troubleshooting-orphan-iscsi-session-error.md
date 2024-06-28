---
title: "Troubleshooting: Orphan ISCSI Session Error"
authors:
- "Phan Le"
draft: false
date: 2024-06-28
versions:
- "All versions"
categories:
- "iscsi"
- "tgt"
---

## Applicable versions

* All longhorn versions

## Symptoms

When an Instance Manager pod crashes, the Open-iSCSI daemon (iscsid) on the host might print error logs every few seconds. You can view these error logs using the command `journalctl -u iscsid -f`.

Example 1:
```
Dec 19 13:19:36 k3s-node-2 iscsid[3160778]: connect to 10.42.3.235:3260 failed (No route to host)
```
Example 2:
```
Jun 28 19:54:59 phan-v672-pool2-1967f397-tprqc iscsid[17303]: cannot make a connection to 10.42.82.31:3260 (-1,22)
```

## Details

When the engine process is crashed without having a chance to logout of the iscsi session and delete the tgt target, it leaves orphan/stale iscsi session on the host.
Furthermore, the instance manager pod is already restarted so its IP has already changed.
However, The iscsid is still trying to connect to the non-existing IP recorded in the orphan/stale iscsi session.
As the result we see the error logs above printed out every few seconds.


While annoying, the logs do not indicate any severe issues.


## Workaround

1. Identify the IP from the logs (`10.42.82.31` in the following example), and verify that the IP is not assigned to any Longhorn Instance Manager pod using the command `k get pods -l longhorn.io/component=instance-manager -o wide -n longhorn-system`.
    Example:
    ```
    Jun 28 19:50:20 phan-v672-pool2-1967f397-tprqc iscsid[17303]: cannot make a connection to 10.42.82.31:3260 (-1,22)
    ```
1. List all active nodes and find the nodes with the same IP as shown in the logs.
    Example:
    ```
    root@phan-v672-pool2-1967f397-tprqc:~# iscsiadm -m node show
    10.42.82.31:3260,1 iqn.2019-10.io.longhorn:testvol
    10.42.82.31:3260,1 iqn.2019-10.io.longhorn:testvol2
    ```
1. Log out of these nodes.
    Example:
    ```
    # Replace the -T and -p with your actual target name and IP

    root@phan-v672-pool2-1967f397-tprqc:~# iscsiadm -m node -T iqn.2019-10.io.longhorn:testvol -p 10.42.82.31 --logout
    Logging out of session [sid: 7, target: iqn.2019-10.io.longhorn:testvol, portal: 10.42.82.31,3260]
    Logout of [sid: 7, target: iqn.2019-10.io.longhorn:testvol, portal: 10.42.82.31,3260] successful.
    root@phan-v672-pool2-1967f397-tprqc:~# iscsiadm -m node -T iqn.2019-10.io.longhorn:testvol2 -p 10.42.82.31 --logout
    Logging out of session [sid: 8, target: iqn.2019-10.io.longhorn:testvol2, portal: 10.42.82.31,3260]
    Logout of [sid: 8, target: iqn.2019-10.io.longhorn:testvol2, portal: 10.42.82.31,3260] successful.
    ```
1. Check if the error logs are no longer printed.

## Related information

- Related Longhorn issue: https://github.com/longhorn/longhorn/issues/7386
