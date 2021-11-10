---
title: Upgrade
weight: 3
---

Here we cover how to upgrade to latest Longhorn from all previous releases.

# Upgrading Longhorn

There are normally two steps in the upgrade process: first upgrade Longhorn manager to the latest version, then manually upgrade the Longhorn engine to the latest version using the latest Longhorn manager.

### 1. Upgrade Longhorn manager

- To upgrade from v1.2.x, see [this section.](./longhorn-manager)

### 2. Manually Upgrade Longhorn Engine

After Longhorn Manager is upgraded, Longhorn Engine also needs to be upgraded [using the Longhorn UI.](./upgrade-engine)

### 3. Automatically Upgrade Longhorn Engine

Since Longhorn v1.1.1, we provide an option to help you [automatically upgrade engines](./auto-upgrade-engine)

### 4. Automatically Migrate Recurring Jobs

With the introduction of the new label-driven `Recurring Job` feature, Longhorn has removed the `RecurringJobs` field in the Volume Spec and planned to deprecate `RecurringJobs` in the StorageClass.

During the upgrade, Longhorn will automatically:
- Create new recurring job CRs from the `recurringJobs` field in Volume Spec and convert them to the volume labels.
- Create new recurring job CRs from the `recurringJobs` in the StorageClass and convert them to the new `recurringJobSelector` parameter.

Visit [Recurring Snapshots and Backups](../../snapshots-and-backups/scheduling-backups-and-snapshots) for more information about the new `Recurring Job` feature.

# Need Help?

If you have any issues, please report it at
https://github.com/longhorn/longhorn/issues and include your backup yaml files
as well as manager logs.
