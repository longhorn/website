---
title: "Troubleshooting: Two active engines during volume live migration"
authors:
- "Phan Le"
draft: false
date: 2025-02-07
versions:
- "v1.4.3"
- "v1.5.1"
categories:
- "live migration"
---

## Applicable versions

- <= v1.4.3
- <= v1.5.1

## Symptoms

Cannot perform any operation (detach/attach/snapshotting/etc...) on a Longhorn volume.
The longhorn-manager logs is showing repeated errors like:
`
[longhorn-manager-v65nc longhorn-manager] time="2023-09-12T00:41:43Z" level=warning msg="Error syncing Longhorn volume longhorn-system/testvol" controller=longhorn-volume error="failed to sync longhorn-system/testvol: failed to reconcile engine/replica state for testvol: BUG: found the second active engine testvol-e-be829d4a besides testvol-e-6c787758" node=phan-v400-two-active-engines-pool2-de9b2523-jd6hd
`

## Details

This is a bug which could happen during Longhorn volume live migration.
Longhorn manager accidentally marked the new engine as active but failed to delete the old engine.
This leads to two active engines during volume live migration and blocks volume operations.

### Troubleshooting

If you observe that Longhorn volume cannot perform operation like attach/detach.
Checking if there are multiple active engine CRs belong to the volume.
Check all longhorn-manager log to see if there are errors similar to `BUG: found the second active engine testvol-e-be829d4a besides testvol-e-6c787758`.
If yes, you have hit the bug.

#### Workaround
The bug has been fixed in Longhorn version >= v1.4.4 and >= v1.5.2.
However, if you are hitting it in older Longhorn version. You can:
1. Look up the volume CR by `kubectl get volumes <volume-name> -n longhorn-system -oyaml`
1. Look up the 2 engine CRs by `kubectl get engines -n longhorn-system | grep -i <volume-name>`
1. Delete the engine CR which is NOT on the same node as `volume.Status.CurrentNodeID`


## Related information

- Related Longhorn issue: https://github.com/longhorn/longhorn/issues/6642
