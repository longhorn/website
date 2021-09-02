---
title: Important Notes
weight: 4
---

This page lists important notes and known issues for Longhorn v1.2.0.
Please see [here](https://github.com/longhorn/longhorn/releases/tag/v1.2.0) for the full release note.

## Notes
1. Please ensure your Kubernetes cluster is at least v1.18 before upgrading to Longhorn v1.2.0
   because the supported Kubernetes version has been updated (>= v1.18) in v1.2.0.
1. After the upgrade, the recurring job settings of volumes will be migrated to new recurring job
   resources and the `RecurringJobs` field in the volume spec will be deprecated.
   [[doc](https://longhorn.io/docs/1.2.0/deploy/upgrade/#4-automatically-migrate-recurring-jobs)]

## Known Issues
1. After installing/upgrading to Longhorn v1.2.0, you will probably encounter a `fsGroup` ineffective
   issue when creating a new fs volume. This is due to the default fs setting being removed from the
   new upstream CSI external-provisioner. The workaround has been provided (ref: https://github.com/longhorn/longhorn/issues/2964#issuecomment-910969543).
