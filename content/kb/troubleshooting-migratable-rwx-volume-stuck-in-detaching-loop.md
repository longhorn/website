---
title: "Troubleshooting: Migratable RWX volume stuck in detaching/attaching loop"
authors:
- "Sushant Gaurav"
draft: false
date: 2026-01-06
versions:
- ">= v1.4.2 and <= v1.7.0"
categories:
- "Migratable RWX volume"
---

## Applicable versions

**Confirmed working with**:

- Longhorn `v1.4.2` (Harvester `v1.1.x` to `v1.2.x` upgrades)

**Potentially applicable to**:

- Longhorn versions prior to `v1.7.0`
- Environments using Migratable RWX volumes with VM live migration

## Symptoms

During a VM live migration or a cluster upgrade, a volume becomes stuck in an endless loop of flipping between `attaching` and `detaching` states. Unlike standard migration hangs where the volume stays `attached`, this loop prevents the volume from being used or cleanly detached.

**Example volume state**: The volume remains stuck in `detaching` even if no workload is running.

```bash
$ kubectl get volume -n longhorn-system pvc-840804d8-6f11-49fd-afae-54bc5be639de
NAME                                       STATE       ROBUSTNESS   NODE         
pvc-840804d8-6f11-49fd-afae-54bc5be639de   detaching   unknown      ubuntu-lh-2
```

**Longhorn Manager Logs**: The logs on the volume owner node will show failures during the migration finalization phase. The controller is unable to find the engine to complete the switch:

```text
level=warning msg="Failed to finalize the migration" controller=longhorn-volume error="cannot find the current engine for the switching after iterating and cleaning up all engines... all engines may be detached or in a transient state"
level=warning msg="Waiting to confirm migration until migration engine is ready" controller=longhorn-volume-attachment
```

**VolumeAttachment (LHVA) state**: Describing the `volumeattachments.longhorn.io` (LHVA) reveals that the `Spec.Attachment Tickets` and `Status.Attachment Ticket Statuses` are **empty**, yet the resource remains stuck due to a finalizer.

```yaml
Name:         pvc-840804d8-6f11-49fd-afae-54bc5be639de
Namespace:    longhorn-system
Kind:         VolumeAttachment
Metadata:
  Finalizers:
    longhorn.io
Spec:
  Attachment Tickets: <nil>
  Volume:  pvc-840804d8-6f11-49fd-afae-54bc5be639de
Status:
  Attachment Ticket Statuses: <nil>
```

## Reason

This issue occurs when a live migration is interrupted—often by powering off the VM, a node failure, or an upgrade interruption—specifically during the "engine switching" phase.

Longhorn expects to switch the frontend from the source engine to the destination engine. If the workload is stopped during this transition, the engines may vanish, leaving the Volume Controller unable to find a "current" engine to finalize the switch. Because the `VolumeAttachment` CR still exists and holds a finalizer, the controller enters a reconciliation loop it cannot complete, causing the flapping state.

## Workaround

If the workload has been shut down and the volume is stuck flapping, follow these steps to manually clear the migration metadata and "ghost" attachment.

### 1. Clear the Migration Metadata

Force the volume to drop the migration reference in its status subresource. This stops the controller from attempting to finalize a nonexistent migration.

```bash
kubectl patch -n longhorn-system volume <VOLUME_NAME> \
  --type=merge \
  --subresource status \
  -p '{"status":{"currentMigrationNodeID":""}}'
```

### 2. Remove the VolumeAttachment Finalizer

The "ghost" LHVA prevents the volume from reaching a steady `detached` state. Manually remove the finalizer to allow the resource to be cleaned up.

```bash
kubectl patch -n longhorn-system volumeattachments.longhorn.io <VOLUME_NAME> \
  --type=merge \
  -p '{"metadata":{"finalizers":null}}'
```

### 3. Delete the Orphaned LHVA

If the resource does not disappear automatically after stripping the finalizer, delete it manually:

```bash
kubectl delete volumeattachments.longhorn.io -n longhorn-system <VOLUME_NAME>
```

### 4. Verify State

Confirm the volume has transitioned to the `detached` state.

```bash
$ kubectl get volume -n longhorn-system <VOLUME_NAME>
NAME              STATE      ROBUSTNESS   NODE
pvc-840804...     detached   unknown
```

You can now safely restart the VM or workload.

## Related Information

- [KB: Troubleshooting: Migratable RWX volume migration stuck](https://longhorn.io/kb/troubleshooting-rwx-volume-migration-stuck/) - For cases where migration tickets are present and "Satisfied" but the node is stuck in pre-drain.
- [Longhorn Issue #12238](https://github.com/longhorn/longhorn/issues/12238)
- Fixed in **Longhorn v1.7.0+**, which includes more robust handling for orphaned migration engines.
