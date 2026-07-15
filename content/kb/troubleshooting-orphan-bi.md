---
title: "Troubleshooting: Manually Clean Up Orphaned Backing Image Files"
authors:
- "Raphanus Lo"
draft: false
date: 2026-07-15
versions:
- "all"
categories:
- "backing image"
- "orphan"
---

## Applicable Versions

All Longhorn versions.

## Symptoms

Backing image files remain under `<disk-path>/backing-images`, or incomplete backing image downloads remain under `<disk-path>/tmp`, even though Longhorn no longer references them. These orphaned files consume disk capacity but are not reported as Longhorn orphan resources.

## Details

Longhorn does not currently detect backing image files as orphan resources. A backing image copy or an interrupted backing image download can therefore remain on a disk after the corresponding Longhorn resource is removed.

Do not delete files from a disk that still has scheduled replicas or scheduled backing image copies. First evict the disk and wait until both `scheduledReplica` and `scheduledBackingImage` are empty. Longhorn then has no online resources allocated to the disk, so the remaining files in `backing-images` and `tmp` can be removed safely.

## Prerequisites

- Another schedulable disk has enough capacity for all replicas and backing image copies evicted from the disk.
- You have `kubectl` access to the cluster and administrative shell access to the node.
- You know the Longhorn node name and disk name. The examples use `worker-node1` and `my-disk-name`.

## Workaround

1. Inspect the Longhorn Node custom resource (CR) and record the disk path and its current scheduling settings.

    ```bash
    kubectl -n longhorn-system get node.longhorn.io worker-node1 -o yaml
    ```

    Simplified example output:

    ```yaml
    apiVersion: longhorn.io/v1beta2
    kind: Node
    metadata:
      name: worker-node1
      namespace: longhorn-system
    spec:
      disks:
        my-disk-name:
          allowScheduling: true
          diskType: filesystem
          evictionRequested: false
          path: /var/lib/longhorn/
    status:
      diskStatus:
        my-disk-name:
          diskName: my-disk-name
          diskPath: /var/lib/longhorn/
          scheduledBackingImage:
            example-backing-image: 1073741824
          scheduledReplica:
            example-volume-r-abc123: 10737418240
    ```

2. Disable scheduling and request eviction for the disk.

    ```bash
    kubectl -n longhorn-system patch node.longhorn.io worker-node1 \
      --type=merge \
      -p '{"spec":{"disks":{"my-disk-name":{"allowScheduling":false,"evictionRequested":true}}}}'
    ```

    Example output:

    ```text
    node.longhorn.io/worker-node1 patched
    ```

3. Wait for disk eviction to complete. Check the disk status until both maps are empty.

    ```bash
    kubectl -n longhorn-system get node.longhorn.io worker-node1 -o json \
      | jq --arg disk "my-disk-name" \
        '.status.diskStatus[$disk] | {diskName, diskPath, scheduledReplica, scheduledBackingImage}'
    ```

    Eviction is complete when the output resembles the following:

    ```json
    {
      "diskName": "my-disk-name",
      "diskPath": "/var/lib/longhorn/",
      "scheduledReplica": {},
      "scheduledBackingImage": {}
    }
    ```

    If either map contains entries, do not remove any files. Wait for eviction to complete. Check that another schedulable disk has sufficient capacity if eviction does not progress.

4. SSH into the node and inspect the cache directories. Set `DISK_PATH` to the exact `diskPath` recorded in the Step 1.

    ```bash
    DISK_PATH=/var/lib/longhorn
    sudo find "${DISK_PATH%/}/backing-images" "${DISK_PATH%/}/tmp" \
      -mindepth 1 -maxdepth 1 -print 2>/dev/null
    ```

    Simplified example output:

    ```text
    /var/lib/longhorn/backing-images/example-backing-image-a1b2c3d4
    /var/lib/longhorn/tmp/example-backing-image.tmp
    ```

5. On the node, remove the contents of the `backing-images` and `tmp` directories on the evicted disk. Set `DISK_PATH` to the exact `diskPath` recorded in the Step 1.

    ```bash
    DISK_PATH=/var/lib/longhorn
    for DIR in "${DISK_PATH%/}/backing-images" "${DISK_PATH%/}/tmp"; do
      if [ -d "$DIR" ]; then
        sudo find "$DIR" -mindepth 1 -maxdepth 1 -exec rm -rf -- {} +
      fi
    done
    sudo find "${DISK_PATH%/}/backing-images" "${DISK_PATH%/}/tmp" \
      -mindepth 1 -maxdepth 1 -print 2>/dev/null
    ```

    The final command produces no output if both directories are empty or do not exist.

6. Cancel disk eviction and re-enable scheduling after cleanup.

    ```bash
    kubectl -n longhorn-system patch node.longhorn.io worker-node1 \
      --type=merge \
      -p '{"spec":{"disks":{"my-disk-name":{"allowScheduling":true,"evictionRequested":false}}}}'
    ```

    Example output:

    ```text
    node.longhorn.io/worker-node1 patched
    ```

    Verify the disk settings:

    ```bash
    kubectl -n longhorn-system get node.longhorn.io worker-node1 -o json \
      | jq --arg disk "my-disk-name" \
        '.spec.disks[$disk] | {allowScheduling, evictionRequested, path}'
    ```

    Example output:

    ```json
    {
      "allowScheduling": true,
      "evictionRequested": false,
      "path": "/var/lib/longhorn/"
    }
    ```

    If the disk was not schedulable before this procedure, restore its original scheduling setting instead of enabling scheduling.

## Related Information

- [Evicting disks or nodes](../../docs/1.13.0/nodes-and-volumes/nodes/disks-or-nodes-eviction/)
- [Orphaned data cleanup](../../docs/1.13.0/advanced-resources/data-cleanup/orphaned-data-cleanup/)
- Related Longhorn issue [#13523](https://github.com/longhorn/longhorn/issues/13523)
