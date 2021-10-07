---
title: Important Notes
weight: 4
---

This page lists important notes for Longhorn v{{< current-version >}}.
Please see [here](https://github.com/longhorn/longhorn/releases/tag/v{{< current-version >}}) for the full release note.

## Notes
1. Please ensure your Kubernetes cluster is at least v1.18 before upgrading to Longhorn v{{< current-version >}} because the supported Kubernetes version has been updated (>= v1.18) in v{{< current-version >}}.
1. After the upgrade, the recurring job settings of volumes will be migrated to new recurring job resources, and the `RecurringJobs` field in the volume spec will be deprecated. [[doc](https://longhorn.io/docs/{{< current-version >}}/deploy/upgrade/#4-automatically-migrate-recurring-jobs)]
