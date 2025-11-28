---
  title: Create a Snapshot
  weight: 1
---

A [snapshot](../../concepts/#24-snapshots) is the state of a Kubernetes volume at any given moment in time.

## Snapshot Management via UI

To create a snapshot of an existing cluster, follow these steps:

1. In the top navigation bar of the Longhorn UI, click **Volume**.
2. Click the name of the volume for which you want to create a snapshot. This leads to the volume detail page.
3. Click the **Take Snapshot** button.

Once the snapshot is created, you will see it in the list of snapshots for the volume before the Volume Head.

### Understanding the Snapshot Chain Visualization

On the **Volumes** page, the **Snapshots and Backups** section displays the snapshot history as a chain. By default, the **Show System Snapshots** option is **enabled**, meaning all system-created snapshots are displayed automatically.

Each snapshot in the chain is color-coded to indicate its type or status, following a specific priority (highest status is displayed if multiple apply). 
| Snapshot Type | Color Code (Hex) | Description | Priority (1 = Highest) |
| :--- | :--- | :--- | :--- |
| **Error** | `#F15354` (Red) | Indicates a snapshot that failed during creation or has an issue. | 1 |
| **Removed** | `#cccccc` (Light Grey) | A snapshot that has been marked for removal or successfully deleted. | 2 |
| **System-created** | `#F1C40` (Orange/Yellow) | Snapshots automatically created by Longhorn, often for recurring jobs or internal operations. | 3 |
| **Backup** | `#33AB65` (Green) | A snapshot that has been backed up to a configured backup target. | 4 |
| **Default** (User-created) | `#3085d5` (Blue) | A standard, user-initiated snapshot taken manually using the **Take Snapshot** button. | 5 |

Below is an example of the snapshot chain visualization:

{{< figure src="/img/diagrams/snapshot/snapshot_volumes_page.png" >}}

## Snapshot Management with Custom Resources (CRs)

This section demonstrates how to create, list, restore, and delete Longhorn snapshots directly via `kubectl` using Longhorn’s **Custom Resources (CRs)**.

> **Note**: Longhorn uses its own `Snapshot` CRD under the `longhorn.io` API group (for example, `v1beta2`), not the generic Kubernetes `VolumeSnapshot` from `snapshot.storage.k8s.io`.  

### Create a Snapshot

1.  **Prepare the manifest**: Create a file named `longhorn-snapshot.yaml`:

    ```yaml
    apiVersion: longhorn.io/v1beta2
    kind: Snapshot
    metadata:
      name: longhorn-test-snapshot
      namespace: longhorn-system
    spec:
      volume: pvc-840804d8-6f11-49fd-afae-54bc5be639de   # replace with your actual Longhorn volume name
      createSnapshot: true
    ```

2.  **Apply the manifest**:

    ```bash
    kubectl apply -f longhorn-snapshot.yaml
    ```

    Expected output:

    ```bash
    snapshot.longhorn.io/longhorn-test-snapshot created
    ```

    > **Note**: If the volume is detached, you will see a brief warning about the engine not running. Longhorn automatically retries, and the snapshot will complete once the volume is attached.

### List Snapshots

```bash
kubectl get snapshots.longhorn.io -l longhornvolume=pvc-840804d8-6f11-49fd-afae-54bc5be639de -n longhorn-system
```

### Delete a Snapshot

```bash
kubectl delete snapshot.longhorn.io longhorn-test-snapshot -n longhorn-system
```

Expected output:

```
snapshot.longhorn.io "longhorn-test-snapshot" deleted
```

> **Note**: Longhorn automatically handles the cleanup of the underlying data.
