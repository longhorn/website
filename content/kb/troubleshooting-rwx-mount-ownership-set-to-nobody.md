---
title: "Troubleshooting: Longhorn RWX shared mount ownership is shown as nobody in consumer Pod"
author: Chin-Ya Huang
draft: false
date: 2021-03-31
categories:
  - "rwx"
---

## Applicable versions

Longhorn versions = v1.1.0

## Symptoms

When Pod mounts with RWX volume, the Pod share mount directory and all of the ownership of its recurring contents are shown as nobody, but in the share-manager is shown as root.

```
root@ip-172-30-0-139:/home/ubuntu# kubectl exec -it rwx-test-2pml2 -- ls -l /data
total 16
drwx------ 2 nobody 42949672 16384 Mar 31 04:16 lost+found

root@ip-172-30-0-139:~# kubectl -n longhorn-system exec -it share-manager-pvc-f3775852-1e27-423f-96ab-95ccd04e4777 -- ls -l /export/pvc-f3775852-1e27-423f-96ab-95ccd04e4777
total 16
drwx------ 2 root root 16384 Mar 31 04:42 lost+found
```

## Background

The nfs-ganesha in share-manager uses idmapd for NFSv4 ID mapping and is set to use `localdomain` as its export Domain.

## Reason

A result of content mismatch in /etc/idmapd.conf between client(host) and server(share-manager) causes ownership to change.

Let's look at an example:

We assume you have not modified `/etc/idmapd.conf` on your cluster hosts. For some OS, `Domain = localdomain` is commented out and it uses FQDN minus hostname by default. 

When the hostname is `ip-172-30-0-139` and FQDN is `ip-172-30-0-139.lan`, the host idmapd then uses `lan` as the Domain.
```
root@ip-172-30-0-139:/home/ubuntu# hostname
ip-172-30-0-139

root@ip-172-30-0-139:/home/ubuntu# hostname -f
ip-172-30-0-139.lan
```
This caused the domain mismatch between share-manager(`localdomain`) and cluster hosts(`lan`). Hence triggers file permission to change to use nobody.
```
[Mapping] section variables

Nobody-User
Local user name to be used when a mapping cannot be completed.
Nobody-Group
Local group name to be used when a mapping cannot be completed.
```

## Solution

1. Uncomment or add `Domain = localdomain` in `/etc/idmapd.conf` on all cluster hosts.
```
root@ip-172-30-0-139:~# cat /etc/idmapd.conf 
[General]

Verbosity = 0
Pipefs-Directory = /run/rpc_pipefs
# set your own domain here, if it differs from FQDN minus hostname
Domain = localdomain

[Mapping]

Nobody-User = nobody
Nobody-Group = nogroup
```
2. Delete and recreate RWX resource stack (pvc + pod).
```
root@ip-172-30-0-139:/home/ubuntu# kubectl exec -it volume-test -- ls -l /data
total 16
drwx------    2 root     root         16384 Mar 31 04:42 lost+found
```

## Related information

* Related Longhorn issue: https://github.com/longhorn/longhorn/issues/2357
* Related idmapd.conf documentation: https://linux.die.net/man/5/idmapd.conf
