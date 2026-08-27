---
title: Longhorn System Backup And Restore
weight: 10
---

> Before v1.4.0, you can restore Longhorn with third-party tools.

- [Restore to a cluster contains data using Rancher snapshot](./restore-to-a-cluster-contains-data-using-rancher-snapshot)
- [Restore to a new cluster using Velero](./restore-to-a-new-cluster-using-velero)

> Since v1.4.0, Longhorn introduced out-of-the-box Longhorn system backup and restore.
> - Longhorn's custom resources will be backed up and bundled into a single system backup file, then saved to the remote backup target.
> - Later, you can choose a system backup to restore to a new cluster or restore to an existing cluster.

- [Backup Longhorn system](./backup-longhorn-system)
- [Restore Longhorn system](./restore-longhorn-system)
