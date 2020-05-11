---
title: Migrating from the Flexvolume Driver to CSI
weight: 5
---

As of Longhorn v0.8.0, the Flexvolume driver is no longer supported. This guide will show you how to migrate from the Flexvolume driver to CSI using the Longhorn catalog app in Rancher. CSI is the newest out-of-tree Kubernetes storage interface.

The volumes created and used through one driver won't be recognized by Kubernetes using the other driver. So please don't switch the driver (e.g. during an upgrade) if you have existing volumes created using the old driver.

The migration path between drivers requires backing up and restoring each volume and will incur both API and workload downtime. This can be a tedious process. Consider deleting unimportant workloads using the old driver to reduce effort.

> **Prerequisites:**
> - [Back up existing volumes](../../snapshots-and-backups/backup-and-restore/create-a-backup).
> - Ensure your Longhorn app is up to date. Follow the relevant upgrade procedure before proceeding.

1. In the Rancher UI, navigate to the **Catalog Apps** screen, locate the Longhorn app, and click **Up to date.**
2. Under **Kubernetes Driver,** select `flexvolume`. We recommend leaving `Flexvolume Path` empty.
3. Click `Upgrade`.
4. Restore each volume. This [procedure](../../snapshots-and-backups/backup-and-restore/restore-statefulset) is tailored to the StatefulSet workload, but the process is approximately the same for all workloads.