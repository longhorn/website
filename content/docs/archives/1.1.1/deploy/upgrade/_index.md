---
title: Upgrade
weight: 5
---

Here we cover how to upgrade to latest Longhorn from all previous releases.

# Upgrading Longhorn

There are normally two steps in the upgrade process: first upgrade Longhorn manager to the latest version, then manually upgrade the Longhorn engine to the latest version using the latest Longhorn manager.

### 1. Upgrade Longhorn manager

- To upgrade from v1.0.x, see [this section.](./longhorn-manager)

### 2. Manually Upgrade Longhorn Engine

After Longhorn Manager is upgraded, Longhorn Engine also needs to be upgraded [using the Longhorn UI.](./upgrade-engine)

### 3. Automatically Upgrade Longhorn Engine
Since Longhorn v1.1.1, we provide an option to help you [automatically upgrade engines](./auto-uprade-engine)

# Extended Reading
Visit [Some old instance manager pods are still running after upgrade](https://longhorn.io/kb/troubleshooting-some-old-instance-manager-pods-are-still-running-after-upgrade) for more information about the cleanup strategy of instance manager pods during upgrade.

# Need Help?

If you have any issues, please report it at
https://github.com/longhorn/longhorn/issues and include your backup yaml files
as well as manager logs.
