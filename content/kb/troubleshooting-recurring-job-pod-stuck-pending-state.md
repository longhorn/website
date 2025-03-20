---
title: "Troubleshooting: Recurring Job Pod stuck in pending state"
authors:
- "Chin-Ya Huang"
draft: false
date: 2025-03-20
versions:
- "all"
categories:
- "recurring job"
---

## Applicable versions

All Longhorn versions.

## Symptoms

After node reboot, a recurring job pod remains stuck in the `Pending` state, preventing scheduled tasks from running.

## Potential Cause

This issue may occur when a node is not ready at the time of a CronJob execution. The Kubernetes scheduler may attempt to place the job on a node that is still initializing after a reboot, leaving the pod in a `Pending` state.

## Workaround

Manually delete the `Pending` pod. The `CronJob` associated with the recurring job will create a new pod at the next scheduled execution time.

## Related Information

* Longhorn issue: [#7956](https://github.com/longhorn/longhorn/issues/7956)