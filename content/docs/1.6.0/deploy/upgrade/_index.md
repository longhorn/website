---
title: Upgrade
weight: 3
---

Here we cover how to upgrade to the latest Longhorn from all previous releases.

# Deprecation & Incompatibility

There are no deprecated or incompatible changes introduced in v{{< current-version >}}.

# Upgrade Path Enforcement

Starting with v1.5.0, Longhorn only allows upgrades from supported versions. When you attempt to upgrade from an unsupported version, the upgrade automatically fails but you can revert to the previously installed version without any service interruption or downtime.

The following table outlines the supported upgrade paths.

  |  Current version |  Target version |  Allowed | Example |
  |    :-:      |    :-:      |   :-:  |    :-:    |
  |  x.y.*      |  x.(y+1).*  |   ✓    |  v1.4.2  to  v1.5.1  |
  |  x.y.*      |  x.y.(*+n)  |   ✓    |  v1.5.0  to  v1.5.1  |
  |  x.y[^lastMinorVersion].*      |  (x+1).y.*  |   ✓    |  v1.30.0 to  v2.0.0  |
  |  x.(y-1).*  |  x.(y+1).*  |   X    |  v1.3.3  to  v1.5.1  |
  |  x.(y-2).*  |  x.(y+1).*  |   X    |  v1.2.6  to  v1.5.1  |
  |  x.y.*      |  x.(y-1).*  |   X    |  v1.6.0  to  v1.5.1  |
  |  x.y.*      |  x.y.(*-1)  |   X    |  v1.5.1  to  v1.5.0  |

[^lastMinorVersion]: Longhorn only allows upgrades from a patch version of the last minor release before the new major version. For example, you can upgrade from v1.3.* to v2.0.* because v1.3.0 is the last minor release before v2.0.

> **Important**:
> When you successfully upgrade to v1.6.0, you will not be allowed to revert to the previously installed version. This restriction helps prevent unexpected system behavior and issues caused by function incompatibility, deprecation, or removal.

# Upgrading Longhorn

There are normally two steps in the upgrade process: first upgrade Longhorn manager to the latest version, then manually upgrade the Longhorn engine to the latest version using the latest Longhorn manager.

## 1. Upgrade Longhorn manager

- To upgrade from v1.4.x, see [this section.](./longhorn-manager)

## 2. Manually Upgrade Longhorn Engine

After Longhorn Manager is upgraded, Longhorn Engine also needs to be upgraded [using the Longhorn UI.](./upgrade-engine)

## 3. Automatically Upgrade Longhorn Engine

Since Longhorn v1.1.1, we provide an option to help you [automatically upgrade engines](./auto-upgrade-engine)

## 4. Automatically Migrate Recurring Jobs

With the introduction of the new label-driven `Recurring Job` feature, Longhorn has removed the `RecurringJobs` field in the Volume Spec and planned to deprecate `RecurringJobs` in the StorageClass.

During the upgrade, Longhorn will automatically:
- Create new recurring job CRs from the `recurringJobs` field in Volume Spec and convert them to the volume labels.
- Create new recurring job CRs from the `recurringJobs` in the StorageClass and convert them to the new `recurringJobSelector` parameter.

Visit [Recurring Snapshots and Backups](../../snapshots-and-backups/scheduling-backups-and-snapshots) for more information about the new `Recurring Job` feature.

# Extended Reading

Visit [Some old instance manager pods are still running after upgrade](https://longhorn.io/kb/troubleshooting-some-old-instance-manager-pods-are-still-running-after-upgrade) for more information about the cleanup strategy of instance manager pods during upgrade.

# Need Help?

If you have any issues, please report it at
https://github.com/longhorn/longhorn/issues and include your backup yaml files
as well as manager logs.
