---
  title: Create a Snapshot
  weight: 1
---

A [snapshot](../../concepts/#24-snapshots) is the state of a Kubernetes volume at any given moment in time.

## Snapshot Management via UI

To create a snapshot of an existing cluster, follow these steps:

1. In the top navigation bar of the Longhorn UI, click **Volume**.
2. Click the name of the volume for which you want to create a snapshot. This leads to the volume detail page.
3. Click the **Take Snapshot** button

Once the snapshot is created, you will see it in the list of snapshots for the volume before the Volume Head.

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

### List a Snapshot

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
