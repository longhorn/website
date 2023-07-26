---
title: "Troubleshooting: Volume attachment fails due to SELinux denials in Fedora downstream distributions"
author: Eric Weber
draft: false
date: 2023-06-07
categories:
  - "iscsi"
  - "selinux"
  - "rhel"
  - "rocky"
---

## Applicable versions
All Longhorn versions.

## Likely environment
Commonly seen in Fedora downstream distributions (e.g. Fedora, RHEL, Rocky, CentOS, etc.) when `container-selinux` is
updated beyond version `2.189.0`. This can happen unexpectedly and can catch administrators off guard.

## Symptoms
Symptoms are the same as those discussed in a [previous KB article that focused on
OKD](../troubleshooting-volumes-stuck-in-attach-detach-loop-when-using-longhorn-on-okd/).

All volumes are stuck in an attach/detach loop. `dmesg` and `ausearch` on storage nodes reveal SELinux issues:
```
-> dmesg
...
[Sat Dec 10 18:52:01 2022] audit: type=1400 audit(1670698321.515:7214): avc:  denied  { dac_override } for  pid=231579 comm="iscsiadm" capability=1  scontext=system_u:system_r:iscsid_t:s0 tcontext=system_u:system_r:iscsid_t:s0 tclass=capability permissive=0
[Sat Dec 10 18:52:01 2022] audit: type=1300 audit(1670698321.515:7214): arch=c000003e syscall=83 success=no exit=-13 a0=55b9035185c0 a1=1f8 a2=ffffffffffffff00 a3=0 items=0 ppid=231163 pid=231579 auid=4294967295 uid=0 gid=0 euid=0 suid=0 fsuid=0 egid=0 sgid=0 fsgid=0 tty=(none) ses=4294967295 comm="iscsiadm" exe="/usr/sbin/iscsiadm" subj=system_u:system_r:iscsid_t:s0 key=(null)
[Sat Dec 10 18:52:01 2022] audit: type=1327 audit(1670698321.515:7214): proctitle=697363736961646D002D6D00646973636F76657279002D740073656E6474617267657473002D700031302E3133312E312E31363

-> ausearch -m AVC -ts recent
...
----
time->Wed Jun  7 19:33:17 2023
type=PROCTITLE msg=audit(1686166397.967:2849): proctitle=697363736961646D002D6D00646973636F76657279002D740073656E6474617267657473002D700031302E38382E302E39
type=PATH msg=audit(1686166397.967:2849): item=1 name="/var/lib/iscsi/nodes/iqn.2019-10.io.longhorn:vol-name/10.88.0.9,3260,1" nametype=CREATE cap_fp=0 cap_fi=0 cap_fe=0 cap_fver=0 cap_frootid=0
type=PATH msg=audit(1686166397.967:2849): item=0 name="/var/lib/iscsi/nodes/iqn.2019-10.io.longhorn:vol-name/" inode=54532024 dev=fc:01 mode=040600 ouid=0 ogid=0 rdev=00:00 obj=unconfined_u:object_r:iscsi_var_lib_t:s0 nametype=PARENT cap_fp=0 cap_fi=0 cap_fe=0 cap_fver=0 cap_frootid=0
type=CWD msg=audit(1686166397.967:2849): cwd="/"
type=SYSCALL msg=audit(1686166397.967:2849): arch=c000003e syscall=83 success=no exit=-13 a0=562f10bf5540 a1=1f8 a2=fffffffffffffef0 a3=0 items=2 ppid=53345 pid=53577 auid=0 uid=0 gid=0 euid=0 suid=0 fsuid=0 egid=0 sgid=0 fsgid=0 tty=(none) ses=1 comm="iscsiadm" exe="/usr/sbin/iscsiadm" subj=unconfined_u:system_r:iscsid_t:s0 key=(null)
type=AVC msg=audit(1686166397.967:2849): avc:  denied  { dac_override } for  pid=53577 comm="iscsiadm" capability=1  scontext=unconfined_u:system_r:iscsid_t:s0 tcontext=unconfined_u:system_r:iscsid_t:s0 tclass=capability permissive=0
```

## Reason

The root cause is the same as was discussed in a [previous KB article that focused on
OKD](../troubleshooting-volumes-stuck-in-attach-detach-loop-when-using-longhorn-on-okd/). A permissions issue in
`open-iscsi` causes `iscsiadm` to create directories under `/var/lib/iscsi` without the execute bit. When it later
needs to access these directories, it cannot do so without the `dac_override` capability. Updated versions of
`container-selinux` do not grant `iscsiadm` this capability when run from a container.

This issue was fixed in `open-iscsi`
[v2.1.4](https://github.com/open-iscsi/open-iscsi/pull/244/commits/6df400925cfa9e723375c6f61524473703054220), but a
patch used to build the `iscsi-initiator-utils` RPM overrode the change in a couple of lines, leaving Fedora
downstream distributions affected. Now that many of these distributions are running with an updated `container-selinux`
package, a workaround is required.


## Solution

### Short term

It is generally not recommended (and difficult) to install an out-of-band version of `open-iscsi` not provided by your
distribution maintainers. Instead, the `dac_override` permission must be provided to `iscsid_t`. This can be done by
running the following command (or similar) on all nodes before using Longhorn.

```
echo '(allow iscsid_t self (capability (dac_override)))' > local_longhorn.cil && semodule -vi local_longhorn.cil
```

While it is not ideal to have to grant the `dac_override` capability, it is important to recognize that affected
versions of `iscsi-initiator-utils` cannot run without it, even outside of Longhorn. Usually, `iscsiadm` is executed
by an unconfined `root` user, and uses this capability implicitly.

Multiple Kubernetes distributions already apply this fix by default:
- https://github.com/openshift/okd-machine-os/blob/master/overlay.d/99okd/usr/lib/okd/selinux-fixes.cil
- https://github.com/rancher/rke2-selinux/blob/master/policy/centos9/rke2.te

If you are running an affected OS with an up-to-date `container-selinux` and your Kubernetes distribution doesn't
already apply the fix for you, we provide a DaemonSet that can make the necessary change on all nodes.

```
git clone https://github.com/longhorn/longhorn.git
cd longhorn
kubectl apply -f deploy/prerequisite/longhorn-iscsi-selinux-workaround.yaml
```

### Long term

A [PR](https://src.fedoraproject.org/rpms/iscsi-initiator-utils/pull-request/13) was submitted to the Fedora project.
If it is accepted, additional capabilities will no longer be required as downstream distributions adopt the changes.

## Related information

- Previous KB article focused on OKD:
  https://longhorn.io/kb/troubleshooting-volumes-stuck-in-attach-detach-loop-when-using-longhorn-on-okd/
- Analysis of the issue:
  https://github.com/longhorn/longhorn/issues/5627#issuecomment-1577498183
- Original `open-iscsi` fix:
  https://github.com/open-iscsi/open-iscsi/pull/244/commits/6df400925cfa9e723375c6f61524473703054220
- Testing for the workaround DaemonSet:
  https://github.com/longhorn/longhorn/pull/6082#issuecomment-1581142425
- Fedora Project PR:
  https://src.fedoraproject.org/rpms/iscsi-initiator-utils/pull-request/13
