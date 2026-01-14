---
title: "Troubleshooting: Migratable RWX volume stuck in detaching/attaching loop"
authors:
- "Sushant Gaurav"
draft: false
date: 2026-01-06
versions:
- "< v1.10.0"
categories:
- "Migratable RWX volume"
---

## Symptoms

During a VM live migration or a cluster upgrade, a volume becomes stuck in an endless loop of flipping between `attaching` and `detaching` states.

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

## Root Cause

This issue occurs when a Migratable RWX live migration is interrupted commonly due to a VM being powered off, a node failure, or an upgrade event - specifically during the engine switching phase of the migration.

During this phase, Longhorn expects to switch the frontend from the source engine to the destination engine. If the workload is stopped while this transition is in progress, both engines may be cleaned up or enter transient states.

As a result:

- The Volume object retains a non-empty `status.currentMigrationNodeID`.
- The Volume Controller continues attempting to finalize a migration that no longer exists.
- The controller cannot identify a valid current engine.
- The volume enters an endless attach/detach reconciliation loop.

In this scenario, the presence of a `VolumeAttachment` resource is a symptom rather than the root cause.

## Workaround

If the workload or VM has already been shut down and the volume is stuck flapping, manually clear the stale migration metadata from the Volume status.

### 1. Clear the `volume.status.currentMigrationNodeID`

Force the volume to drop the migration reference in its status subresource. This stops the controller from attempting to finalize a nonexistent migration.

```bash
kubectl patch -n longhorn-system volume <VOLUME_NAME> \
  --type=merge \
  --subresource status \
  -p '{"status":{"currentMigrationNodeID":""}}'
```

### 2. Verify State

Confirm the volume has transitioned to the `detached` state.

```bash
$ kubectl get volume -n longhorn-system <VOLUME_NAME>
NAME              STATE      ROBUSTNESS   NODE
pvc-840804...     detached   unknown
```

You can now safely restart the VM or workload.

## References

- [KB: Troubleshooting: Migratable RWX volume migration stuck](https://longhorn.io/kb/troubleshooting-rwx-volume-migration-stuck/) - For cases where migration tickets are present and "Satisfied" but the node is stuck in pre-drain.
- [Longhorn Issue #12238](https://github.com/longhorn/longhorn/issues/12238), and [Longhorn Issue #11479](https://github.com/longhorn/longhorn/issues/11479).
- Fixed in **Longhorn v1.7.0+**, which includes more robust handling for orphaned migration engines.
