---
title: "Troubleshooting: Volume cannot be cleaned up after the node of the workload pod is down and recovered"
author: Derek Su
draft: false
date: 2021-11-08
categories:
  - "Pod Cleanup"
---

## Applicable versions

All Longhorn versions.

## Symptoms

Volume cannot be cleaned up after the node of the workload pod is down and recovered.

## Solution

The root cause is a race condition in the pod cleanup process of Kubernetes.
It is fixed since Kubernetes 1.22.0+ according to this [commit](https://github.com/kubernetes/kubernetes/commit/3eadd1a9ead7a009a9abfbd603a5efd0560473cc).

## Related information

[Longhorn issue #3080](https://github.com/longhorn/longhorn/issues/3080)
