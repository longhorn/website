---
title: Upgrade
weight: 5
---

Here we cover how to upgrade to latest Longhorn from all previous releases.

# Upgrading Longhorn

There are normally two steps in the upgrade process: first upgrade Longhorn manager to the latest version, then upgrade the Longhorn engine to the latest version using the latest Longhorn manager.

### 1. Upgrade Longhorn manager

- To upgrade from v0.7.0+, see [this section.](./longhorn-manager/#upgrading-longhorn-manager-from-v070)
- To upgrade from v0.6.2 or older to v0.8.1, see [this section.](./longhorn-manager/#upgrading-from-v062-or-older-version-to-v081)
- To upgrade from v0.6.2 to v0.7.0, see [this section.](./longhorn-manager/#upgrading-longhorn-manager-from-v062-to-v070)


### 2. Upgrade Longhorn Engine

After Longhorn Manager is upgraded, Longhorn Engine also needs to be upgraded [using the Longhorn UI.](./upgrade-engine)

# Need Help?

If you have any issues, please report it at
https://github.com/longhorn/longhorn/issues and include your backup yaml files
as well as manager logs.