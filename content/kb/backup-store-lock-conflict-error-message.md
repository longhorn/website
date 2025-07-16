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

- **Informational, not an error:** These messages are for your information. They indicate that the backup resource is currently in use by another operation, not that something has failed.
- **Reason:** Backup operations on the same persistent volume (PV) use the same lock file. For example, saving a new backup acquires volume-scope lock. If one backup operation is in progress and has acquired the lock, any subsequent backup operation attempting to start before the first finishes will generate this message in its CR status.
- **Typical scenarios:** This can often happen with large PVs or when backups are scheduled to run at short intervals.

## What To Do

- **No action required:** The situation resolves itself. Once the ongoing backup operation releases the lock, the next backup will proceed automatically.
- **Best practice:** Consider increasing the interval between backup jobs for large volumes to minimize the chance of lock contention.