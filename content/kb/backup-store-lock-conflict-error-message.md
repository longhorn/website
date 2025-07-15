---
title: "Backup store lock conflict error message"
authors:
- "Pratik Jagrut"
draft: false
date: 2025-07-15
versions:
- All
categories:
- "Backup"
---

## Applicable versions

All Longhorn versions

## Overview

When performing Longhorn backups, you might see messages in the `status.messages` section of your backup custom resource (CR) similar to the following:

```sh
Failed to delete the backup s3://prod-xyz@vhbkp-backup/?backup=backup-fbec0b48b7c348d6&volume=pvc-3f3bd369-2ab6-43ea-aff5-c8455a1dca9a in the backupstore, err error deleting backup s3://prod-xyz@vhbkp-backup/?backup=backup-fbec0b48b7c348d6&volume=pvc-3f3bd369-2ab6-43ea-aff5-c8455a1dca9a: failed to execute: /var/lib/longhorn/engine-binaries/rancher-mirrored-longhornio-longhorn-engine-v1.8.1/longhorn [backup rm s3://prod-xyz@vhbkp-backup/?backup=backup-fbec0b48b7c348d6&volume=pvc-3f3bd369-2ab6-43ea-aff5-c8455a1dca9a], output failed to acquire lock backupstore/volumes/97/d4/pvc-3f3bd369-2ab6-43ea-aff5-c8455a1dca9a/locks/lock-be9e2e87f33f40cb.lck when performing backup delete, please try again later.
```

## What This Message Means

- **Informational, not an error**: These messages are informational. They indicate that the backup resource is currently in use by another operation, not that the operation has failed.
- **Reason**: Backup operations on the same Persistent Volume (PV) use the same lock file. For example, saving a new backup acquires a volume-scoped lock. If one backup operation is already in progress and has acquired the lock, any subsequent operation that starts before the first one finishes will generate this message in its CR status.
- **Typical scenarios**: This can occur with large PVs or when backups are scheduled at short intervals.

## What to Do
- **No action required**: This situation typically resolves itself. Once the ongoing backup operation releases the lock, the next backup will proceed automatically.
- **Best practice**: For large volumes, consider increasing the interval between backup jobs to minimize the chance of lock contention.