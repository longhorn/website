---
title: Upgrade
weight: 5
---

Here we cover how to upgrade to latest Longhorn from all previous releases.

# Upgrading Longhorn

There are normally two steps in the upgrade process: first upgrade Longhorn manager to the latest version, then manually upgrade the Longhorn engine to the latest version using the latest Longhorn manager.

### 1. Upgrade Longhorn manager

- To upgrade from v1.1.x, see [this section.](./longhorn-manager)

### 2. Manually Upgrade Longhorn Engine

After Longhorn Manager is upgraded, Longhorn Engine also needs to be upgraded [using the Longhorn UI.](./upgrade-engine)

### 3. Automatically Upgrade Longhorn Engine
Since Longhorn v1.1.1, we provide an option to help you [automatically upgrade engines](./auto-uprade-engine)

> **Note:**
> There is a bug in the instance manager image `v1_20201216` shipped in Longhorn v1.1.0 and v1.1.1
> which can lead to a deadlock in a big cluster with hundreds of volumes.
> See more details [here](https://github.com/longhorn/longhorn/issues/2697).
> Longhorn v1.1.2 is shipped with a new instance manager image `v1_20210621` which fixed the deadlock
> but engine/replica processes of volumes don't migrate from the old instance manager to the new instance manager
> until the next time the volumes are detached/attached. Longhorn does it because we don't want to interrupt the
> data plane of the volumes.
>
> If you hit the deadlock in the old instance manager, please follow the recovering steps [here](https://github.com/longhorn/longhorn/issues/2697#issuecomment-879374809)

# Need Help?

If you have any issues, please report it at
https://github.com/longhorn/longhorn/issues and include your backup yaml files
as well as manager logs.

