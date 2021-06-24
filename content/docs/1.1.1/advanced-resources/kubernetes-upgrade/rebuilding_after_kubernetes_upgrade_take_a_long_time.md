---
title: "Rebuilding after Kubernetes upgrade take a long time"
draft: true
weight: 2
---

<!-- TOC -->

- [Relate Issues](#relate-issues)
- [Issue Description](#issue-description)
- [Solution](#solution)
<!-- /TOC -->

## Relate Issues

- [[BUG] Volume operations take long time during automatic upgrading the engines in a big cluster #2697](https://github.com/longhorn/longhorn/issues/2697)

## Issue Description

After Kubernetes upgrade, replicas of volume in different nodes are in degraded sate and is required to be rebuild. Depending on the numbers of replica of volume and the size of volume, the rebuild time would increase proportionally.

## Solution

To avoid rebuild, if workloads scale down to `0` before Kubernetes upgrade, their volumes will not be changed. After Kubernetes upgrade, when workloads scale up, no rebuild is required.
