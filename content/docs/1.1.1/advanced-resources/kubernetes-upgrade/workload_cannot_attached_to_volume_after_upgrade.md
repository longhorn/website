---
title: "Workload cannot attached to volume after upgrade"
draft: true
weight: 3
---

<!-- TOC -->

- [Relate Issues](#relate-issues)
- [Issue Description](#issue-description)
- [Solution](#solution)
<!-- /TOC -->

## Relate Issues

- [[BUG] Mount RWX volumes doesn't work on k8s nodes supporting only NFS 4.0 - an incorrect mount option was specified
#2457](https://github.com/longhorn/longhorn/issues/2457)
- [[BUG] Volume operations take long time during automatic upgrading the engines in a big cluster #2697](https://github.com/longhorn/longhorn/issues/2697)
- [[BUG] RWX volume unable to mount in rke2 cluster.#2659](https://github.com/longhorn/longhorn/issues/2659#issuecomment-857219535)

## Issue Description

After kubernetes upgrade, workload cannot attached to healthy volume.

- mount point failed to releases
- deadlock
- timeout

## Solution

- restart `longhorn-manager` and `shared-manager`
