---
title: "Troubleshooting: Backing Image Manager CR naming collisions"
authors:
- "Raphanus Lo"
draft: false
date: 2025-11-04
versions:
- "v1.7.x and earlier"
- "v1.8.0 to v1.8.2"
- "v1.9.0 to v1.9.1"
categories:
- "backing image"
- "troubleshooting"
---

## Applicable versions

- v1.7.x and earlier
- v1.8.0 to v1.8.2
- v1.9.0 to v1.9.1

## Symptom

A Backing Image copy fails to be created on the target disk because the Backing Image's `spec.diskFileSpecMap` lists a disk UUID for the desired copy, but the corresponding disk UUID is missing from `status.diskFileStatusMap`. As a result, Longhorn is unable to schedule the Backing Image to the target disk, and replica creation is blocked.

**Example**: Inspect the Backing Image to see that the desired disk is present under `spec.diskFileSpecMap` but absent from `status.diskFileStatusMap`:

```bash
kubectl -n longhorn-system get backingimage.longhorn.io rhel-9-5-comops-4249-v2
```

```yaml
apiVersion: longhorn.io/v1beta2
kind: BackingImage
metadata:
  name: rhel-9-5-comops-4249-v2
  namespace: longhorn-system
  ...
spec:
  diskFileSpecMap:
    c012eb76-f8eb-4ea1-b81d-472eac9d98bf:
      dataEngine: v1
      evictionRequested: false
    ...
status:
  diskFileStatusMap:
      # the desired disk c012eb76-f8eb-4ea1-b81d-472eac9d98bf is not listed
      ...
```

In the Longhorn manager logs, you will often see repeated reconciliation errors when the controller tries to create the Backing Image manager, but a resource with the same name already exists (example):

```
2025-08-20T12:11:52.737583600-07:00 time="2025-08-20T19:11:52Z" level=info msg="Creating default backing image manager for disk c012eb76-f8eb-4ea1-b81d-472eac9d98bf" func="controller.(*BackingImageController).handleBackingImageManagers" file="backing_image_controller.go:1254" backingImageName=rhel-9-5-comops-4249-v2 controller=longhorn-backing-image node=my-node-1
2025-08-20T12:11:52.743318619-07:00 time="2025-08-20T19:11:52Z" level=error msg="Failed to sync Longhorn backing image" func=controller.handleReconcileErrorLogging file="utils.go:79" BackingImage=longhorn-system/rhel-9-5-comops-4249-v2 controller=longhorn-backing-image error="failed to sync backing image for my-backing-image: failed to handle backing image managers: backingimagemanagers.longhorn.io \"backing-image-manager-4407-c012\" already exists" node=my-node-1
2025-08-20T12:11:52.749833935-07:00 time="2025-08-20T19:11:52Z" level=info msg="Creating default backing image manager for disk c012eb76-f8eb-4ea1-b81d-472eac9d98bf" func="controller.(*BackingImageController).handleBackingImageManagers" file="backing_image_controller.go:1254" backingImageName=rhel-9-5-comops-4249-v2 controller=longhorn-backing-image node=my-node-1
2025-08-20T12:11:52.754803903-07:00 time="2025-08-20T19:11:52Z" level=error msg="Failed to sync Longhorn backing image" func=controller.handleReconcileErrorLogging file="utils.go:79" BackingImage=longhorn-system/rhel-9-5-comops-4249-v2 controller=longhorn-backing-image error="failed to sync backing image for my-backing-image: failed to handle backing image managers: backingimagemanagers.longhorn.io \"backing-image-manager-4407-c012\" already exists" node=my-node-1
2025-08-20T12:11:52.766880728-07:00 time="2025-08-20T19:11:52Z" level=info msg="Creating default backing image manager for disk c012eb76-f8eb-4ea1-b81d-472eac9d98bf" func="controller.(*BackingImageController).handleBackingImageManagers" file="backing_image_controller.go:1254" backingImageName=rhel-9-5-comops-4249-v2 controller=longhorn-backing-image node=my-node-1
2025-08-20T12:11:52.772209602-07:00 time="2025-08-20T19:11:52Z" level=error msg="Failed to sync Longhorn backing image" func=controller.handleReconcileErrorLogging file="utils.go:79" BackingImage=longhorn-system/rhel-9-5-comops-4249-v2 controller=longhorn-backing-image error="failed to sync backing image for my-backing-image: failed to handle backing image managers: backingimagemanagers.longhorn.io \"backing-image-manager-4407-c012\" already exists" node=my-node-1
```

## Root cause

Longhorn previously generated Backing Image Manager names using shortened portions of disk and image identifiers (for example, the first 4 hexadecimal digits of the disk UUID). These truncated prefixes are not unique at the cluster level. When two disks share the same short prefix, the controller attempts to create a Backing Image Manager with a name that already exists. This leads to a failure in the creation process, and the controller is unable to reconcile the expected resource for the target disk. Consequently, the desired copy remains in `spec.diskFileSpecMap`, but there is no corresponding entry in `status.diskFileStatusMap`, preventing the Backing Image from being delivered to the disk and blocking replica creation.

To identify the issue, check the prefix of each disk in the cluster. A small Python script is available to help find colliding disk UUIDs:

```python
import subprocess
import json
from collections import defaultdict

NAMESPACE = 'longhorn-system'

cmd = [
  'kubectl', '-n', NAMESPACE,
  'get', 'nodes.longhorn.io',
  '-o', 'json'
]
result = subprocess.run(cmd, capture_output=True, text=True)
data = json.loads(result.stdout)

disks = defaultdict(list)
for node in data.get('items', []):
  node_name = node.get('metadata', {}).get('name')
  disk_status = node.get('status', {}).get('diskStatus', {})
  for disk_name, disk_info in disk_status.items():
    uuid = disk_info.get('diskUUID', '')
    if uuid:
      disks[uuid[:4]].append((node_name, disk_name, uuid))

conflicts = [(prefix, nname, dname, uuid)
  for (prefix, dlist) in disks.items() if len(dlist) > 1
  for (nname, dname, uuid) in dlist]

print('Conflict disks:')
for (prefix, nname, dname, uuid) in conflicts:
  print(f'    Prefix "{prefix}": node {nname}, disk {dname} ({uuid})')
```

And the conflict disks will be listed:

```
Conflict disks:
    Prefix "c012": node my-node-1, disk disk-7 (c01200da-8a5c-4692-92e6-c4a983087951)
    Prefix "c012": node my-node-2, disk default-disk-a0c5d780fe32c91c (c012eb76-f8eb-4ea1-b81d-472eac9d98bf)
```

## Mitigation

To address the Backing Image Manager name collisions, there are two potential approaches. Choose the approach that best suits your needs based on your current environment and urgency:

### Temporary reschedule affected replicas

This is the safer approach, which moves affected workloads to disks without UUID conflicts.

1. Identify disks with colliding UUID prefixes using the Python script shown above.
2. Find affected Backing Images and their problematic disks:
    ```bash
    kubectl -n longhorn-system get backingimages.longhorn.io -o yaml
    ```
    Compare `spec.diskFileSpecMap` and `status.diskFileStatusMap` entries. Record any disk UUIDs where a `spec` entry exists but no corresponding `status` entry.
3. Disable scheduling on the affected disks.
4. Delete any replicas stuck on those disks:
    ```bash
    kubectl -n longhorn-system delete replica.longhorn.io <replica-name>
    ```
    The controller will automatically reschedule new replicas on disks without UUID conflicts.
5. Remove the affected disks from the Backing Image specs:
    ```bash
    kubectl -n longhorn-system edit backingimage.longhorn.io <backing-image-name>
    ```
    Delete the problem disk's entry from `spec.diskFileSpecMap`

**Important**: Do **not** re-enable scheduling on disks with UUID conflicts. The issue will recur if workloads are scheduled there again. Instead, follow Option 2 below to permanently resolve the conflict, or keep the disk disabled until you upgrade to a Longhorn version that includes the fix.

### Change disk UUIDs to resolve naming collisions

This approach permanently resolves UUID conflicts by assigning new UUIDs to the affected disks.

**Warning**: This procedure requires evicting **all** resources from the affected disks, including volumes and their data. Use this only if you must continue using the disks and cannot upgrade to a fixed Longhorn version yet.

1. Follow steps 1–5 above to identify conflicts and move workloads off the affected disks.
2. After all Backing Images are removed, evict the disk completely:
   ```bash
   kubectl -n longhorn-system edit node.longhorn.io <node-name>
   ```
   Remove the disk's entire entry from `spec.disks`
3. SSH to the affected node and update the disk's UUID:
   ```bash
   # Navigate to the disk's directory, /var/lib/longhorn by default
   cd <disk-path>

   # Edit longhorn-disk.cfg and change the diskUUID field
   vi longhorn-disk.cfg
   ```
   Generate a new UUID that does not share a prefix with any other disk in the cluster.
4. Re-add the disk to Longhorn:
   ```bash
   # Edit the node again
   kubectl -n longhorn-system edit node.longhorn.io <node-name>

   # Add back the disk entry under spec.disks with the path and other settings,
   # but let Longhorn detect the new UUID
   ```
5. Verify that the new UUID is detected:
   ```bash
   kubectl -n longhorn-system get node.longhorn.io <node-name> -o json | \
     jq -r '.status.diskStatus[] | [.diskName, .diskUUID] | @tsv'
   ```
6. If the new UUID no longer conflicts with other disks, re-enable scheduling on the disk.

**Caution**: Always verify you have recent backups before modifying disk configurations. When possible, prefer upgrading to a Longhorn version that includes the fix rather than changing UUIDs manually.

## Related information

- [Longhorn issue #11455](https://github.com/longhorn/longhorn/issues/11455)
