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

After instance manager pod crashes, you might see the error logs of iscsid on the host (by running `journalctl -u iscsid -f`) printed out every few seconds:
```
Dec 19 13:19:36 k3s-node-2 iscsid[3160778]: connect to 10.42.3.235:3260 failed (No route to host)
```
Or
```
Jun 28 19:54:59 phan-v672-pool2-1967f397-tprqc iscsid[17303]: cannot make a connection to 10.42.82.31:3260 (-1,22)
```

## Details

When the engine process is crashed without having a chance to logout of the iscsi session and delete the tgt target, it leaves orphan/stale iscsi session on the host.
Furthermore, the instance manager pod is already restarted so its IP has already changed.
The iscsid is still trying to connect to the non-existing IP recorded in the orphan/stale iscsi session.
As the result we see the error logs above printed out every few seconds.


These logs seem to be harmless, but might be a bit annoying.


## Workaround

1. Identify the IP from the log. For example, `10.42.82.31` from this log. Confirm that this IP is not the IP of any longhorn instance manager pod (shown by `k get pods -l longhorn.io/component=instance-manager -o wide -n longhorn-system`)
    ```
    Jun 28 19:50:20 phan-v672-pool2-1967f397-tprqc iscsid[17303]: cannot make a connection to 10.42.82.31:3260 (-1,22)
    ```
1. List all active nodes and find the one with the same IP as shown in the logs. For example:
    ```
    root@phan-v672-pool2-1967f397-tprqc:~# iscsiadm -m node show
    10.42.82.31:3260,1 iqn.2019-10.io.longhorn:testvol
    10.42.82.31:3260,1 iqn.2019-10.io.longhorn:testvol2
    ```
1. Log out of these nodes:
    ```
    # Replace the -T and -p with your actual target name and IP

    root@phan-v672-pool2-1967f397-tprqc:~# iscsiadm -m node -T iqn.2019-10.io.longhorn:testvol -p 10.42.82.31 --logout
    Logging out of session [sid: 7, target: iqn.2019-10.io.longhorn:testvol, portal: 10.42.82.31,3260]
    Logout of [sid: 7, target: iqn.2019-10.io.longhorn:testvol, portal: 10.42.82.31,3260] successful.
    root@phan-v672-pool2-1967f397-tprqc:~# iscsiadm -m node -T iqn.2019-10.io.longhorn:testvol2 -p 10.42.82.31 --logout
    Logging out of session [sid: 8, target: iqn.2019-10.io.longhorn:testvol2, portal: 10.42.82.31,3260]
    Logout of [sid: 8, target: iqn.2019-10.io.longhorn:testvol2, portal: 10.42.82.31,3260] successful.
    ```
1. Check if the error log disappears

## Related information

- Related Longhorn issue: https://github.com/longhorn/longhorn/issues/7386
