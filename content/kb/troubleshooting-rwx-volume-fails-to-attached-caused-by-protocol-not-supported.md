---
title: "Troubleshooting: RWX Volume Fails to Be Attached Caused by `Protocol not supported`"
author: Derek Su
draft: false
date: 2023-10-27
catelogies:
  - "volume"
---

## Applicable versions

All Longhorn versions.

## Symptoms

Attempts to attach an RWX volume are unsuccessful, and the workload using the volume is unable to start. The logs contain the following messages:
```
Oct 11 07:42:23 dev-worker-1 k3s[1294]: Mounting command: /usr/local/sbin/nsmounter
Oct 11 07:42:23 dev-worker-1 k3s[1294]: Mounting arguments: mount -t nfs -o vers=4.1,noresvport,intr,hard 10.43.207.185:/pvc-13538170-4278-4467-b2b0-1f1ba6f54a4c /var/lib/kubelet/plugins/kubernetes.io/csi/driver.longhorn.io/185c34f566c2eca6e8c7c6a2ede2094c076d7d25ddae286dc633eeef80551af0/globalmount
Oct 11 07:42:23 dev-worker-1-autoscaled-small-19baf778f50efd8c k3s[1294]: Output: mount.nfs: Protocol not supported for 10.43.207.185:/pvc-13538170-4278-4467-b2b0-1f1ba6f54a4c on /var/lib/kubelet/plugins/kubernetes.io/csi/driver.longhorn.io/185c34f566c2eca6e8c7c6a2ede2094c076d7d25ddae286dc633eeef80551af0/globalmount
```

The issue applies to RWX volumes on hosts running operating systems that use specific Linux kernel versions with known NFS-related bugs. Among the affected are OpenSUSE MicroOS (from 2023/10/08 to 2023/10/21) and other distributions using kernel version 6.5.6.

## Reason

Longhorn RWX volumes depend on NFS when connecting multiple pods to a shared volume. However, commits to the Linux kernel can occasionally break NFS functionality. A regression of the NFS protocol happened in kernel version 5.15.0-94, and another in version 6.5.6.  Because of the regression, NFS clients are unable to connect to an NFS server inside a share manager pod, and then the attachment operation fails.

#### Solution

To address the issue, you can perform either of the following actions:

- Upgrade the operating system to a version that uses a fixed kernel.
- Downgrade the operating system to a version that uses a kernel released before the regression occurred.

| Broken Version | Downgrade Version | Upgrade Version |
| -------------- | ----------------- | --------------- |
| 5.15.0-94      | 5.15.0-92         | 5.15.0-100      |
| 6.5.6          | 6.5.5             | 6.5.7           |

## Related information

https://github.com/longhorn/longhorn/issues/6857  
https://github.com/longhorn/longhorn/issues/6887
