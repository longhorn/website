---
title: "Troubleshooting: Volumes Stuck in Attach/Detach Loop When Using Longhorn on OKD"
author: Jack Lin
draft: false
date: 2023-02-09
categories:
  - "iscsi"
---

## Applicable versions
All Longhorn versions. 

## Symptoms
All volumes stuck in Attach/Detach loop. By using dmesg on storage nodes you can see errors like the following:
```
[Sat Dec 10 18:52:01 2022] audit: type=1400 audit(1670698321.515:7214): avc:  denied  { dac_override } for  pid=231579 comm="iscsiadm" capability=1  scontext=system_u:system_r:iscsid_t:s0 tcontext=system_u:system_r:iscsid_t:s0 tclass=capability permissive=0
[Sat Dec 10 18:52:01 2022] audit: type=1300 audit(1670698321.515:7214): arch=c000003e syscall=83 success=no exit=-13 a0=55b9035185c0 a1=1f8 a2=ffffffffffffff00 a3=0 items=0 ppid=231163 pid=231579 auid=4294967295 uid=0 gid=0 euid=0 suid=0 fsuid=0 egid=0 sgid=0 fsgid=0 tty=(none) ses=4294967295 comm="iscsiadm" exe="/usr/sbin/iscsiadm" subj=system_u:system_r:iscsid_t:s0 key=(null)
[Sat Dec 10 18:52:01 2022] audit: type=1327 audit(1670698321.515:7214): proctitle=697363736961646D002D6D00646973636F76657279002D740073656E6474617267657473002D700031302E3133312E312E31363
```

## Reason

Caused by the [permission issue](https://github.com/open-iscsi/open-iscsi/pull/244/commits/6df400925cfa9e723375c6f61524473703054220) related to the host SELinux policies which prevent iscsiadm from operating correctly. This issue is likely to happen if the open-iscsi version is before or equal to `2.1.4` and in some [OKD versions](https://github.com/longhorn/longhorn/issues/4988#issuecomment-1345575281)


## Solution

There are three ways to resolve the issue. 

1. Upgrade your OKD to a newer version which is after 4.12.0-0.okd-2022-12-10.
2. Upgrade open-iscsi to a newer version including the fix of the permission issue if possible.
3. If in the existing non-working environment, applying `dac_override` using a local CIL via MachineConfig is also a workaround. Please take a look at the below reference links.

## Related information

- Testing results
    - https://github.com/longhorn/longhorn/issues/4988#issuecomment-1345575281
- Comment related to workaround
    - https://github.com/longhorn/longhorn/issues/4988#issuecomment-1345676772
- Upstream discussion
    - https://github.com/okd-project/okd/issues/1438
