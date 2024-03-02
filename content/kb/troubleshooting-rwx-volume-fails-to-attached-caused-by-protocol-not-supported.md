---
title: "Troubleshooting: RWX Volume Fails to Be Attached Caused by `Protocol not supported`"
authors:
- "Derek Su"
draft: false
date: 2023-10-27
versions:
- "all"
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

The issue applies to RWX volumes on hosts running operating systems that use specific Linux kernel versions with known NFS-related bugs. Among the affected are OpenSUSE MicroOS (from 2023/10/08 to 2023/10/21) and other distributions using kernel version **6.5.6**.

## Reason

Longhorn RWX volumes depend on NFS when connecting multiple pods to a shared volume. However, commits to the Linux kernel can occasionally break NFS functionality. A regression in the NFS protocol is identified in this [kernel commit](https://github.com/torvalds/linux/commit/51d674a5e4889f1c8e223ac131cf218e1631e423). Because of the regression, NFS clients are unable to connect to an NFS server inside a share manager pod, and then the attachment operation fails.

#### Solution

The regression has been addressed in the [kernel commit](https://github.com/torvalds/linux/commit/379e4adfddd6a2f95a4f2029b8ddcbacf92b21f9) within the vanilla kernel version **6.5.7**. Since the commit leading to the regression might be backported to older kernel versions in various distributions, to resolve the issue, it's advisable to inspect the source code of your Linux kernel to determine if the error stems from the [commit](https://github.com/torvalds/linux/commit/51d674a5e4889f1c8e223ac131cf218e1631e423). For instance, Ubuntu users can check it within the [code repository](https://git.launchpad.net/~ubuntu-kernel/ubuntu/+source/linux/). If confirmed, you can then proceed with either of the following actions:

- Upgrade the operating system to a version that uses a fixed kernel.
- Downgrade the operating system to a version that uses a kernel released before the regression occurred.

| Distro         | Broken Version |
| -------------- | -------------- |
| Vanilla kernel | 6.5.6          |
| Ubuntu         | [5.15.0-94](https://git.launchpad.net/~ubuntu-kernel/ubuntu/+source/linux/+git/jammy/log/?h=Ubuntu-5.15.0-94.104) |
| Ubuntu         | [6.5.0-21](https://git.launchpad.net/~ubuntu-kernel/ubuntu/+source/linux/+git/jammy/tag/?h=Ubuntu-hwe-6.5-6.5.0-21.21_22.04.1) |

## Related information

https://github.com/longhorn/longhorn/issues/6857  
https://github.com/longhorn/longhorn/issues/6887
