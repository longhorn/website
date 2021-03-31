---
title: "Troubleshooting: Longhorn volumes take a long time to finish mounting"
author: Phan Le
draft: false
date: 2021-02-26
categories:
  - "csi"
---

## Applicable versions
All Longhorn versions.

## Symptoms

When starting a workload pod that uses Longhorn volumes,
the Longhorn UI shows that the Longhorn volumes are attached quickly,
but it takes a long time for the volumes to finish mounting and for the workload to be able to start.

This issue only happens when the Longhorn volumes have many files/directories and `securityContext.fsGroup` is set in the workload pod as shown below:
```yaml
spec:
  securityContext:
    runAsUser: 1000
    runAsGroup: 3000
    fsGroup: 2000
```

## Reason

By default, when seeing `fsGroup` field, each time a volume is mounted, Kubernetes recursively calls `chown()` and `chmod()` on all the files and directories inside the volume.
This happens even if group ownership of the volume already matches the requested `fsGroup`,
and can be pretty expensive for larger volumes with lots of small files, which causes pod startup to take a long time.

#### Solution
There is no workaround for this problem in Kubernetes version v1.19.x and before.

Since version v1.20.x, Kubernetes introduces a new beta feature: the field `fsGroupChangePolicy`. I.e.,
```yaml
spec:
  securityContext:
    runAsUser: 1000
    runAsGroup: 3000
    fsGroup: 2000
    fsGroupChangePolicy: "OnRootMismatch"
```
When `fsGroupChangePolicy` is set to `OnRootMismatch`, if the root of the volume already has the correct permissions,
the recursive permission and ownership change will be skipped.
It means that if users don't change the `pod.spec.securityContext.fsGroup` between pod's startups,
K8s will only have to check the permissions and ownership of the root and the mounting process will be much faster compared to always recursively changing the volumes' ownership and permissions.


## Related information

* Related Longhorn issue: https://github.com/longhorn/longhorn/issues/2131
* Related Kubernetes documentation: https://kubernetes.io/blog/2020/12/14/kubernetes-release-1.20-fsgroupchangepolicy-fsgrouppolicy/#allow-users-to-skip-recursive-permission-changes-on-mount
