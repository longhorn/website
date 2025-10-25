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

> **Important Note**:  
> Longhorn uses its own `Snapshot` CRD under the `longhorn.io` API group (for example, `v1beta2`), not the generic Kubernetes `VolumeSnapshot` from `snapshot.storage.k8s.io`.  
>  
> Always confirm your CRD version first:
> ```bash
> kubectl get crd snapshots.longhorn.io -o yaml | grep version:
> ```
> The examples below assume `apiVersion: longhorn.io/v1beta2`.


### 1. Creating a Snapshot

This example shows how to create a snapshot for an existing Longhorn volume using `kubectl`.

In our verified example, the Longhorn volume name was:
```
pvc-d449abdc-5a17-4a80-a0ff-669173704060
```

> Replace this with your own volume name when running the commands.  
> You can find it with:
> ```bash
> kubectl get volumes.longhorn.io -n longhorn-system
> ```

#### Step 1 – Prepare the manifest

Create a file named `longhorn-snapshot.yaml`:

```yaml
apiVersion: longhorn.io/v1beta2
kind: Snapshot
metadata:
  name: longhorn-test-snapshot
  namespace: longhorn-system
spec:
  volume: pvc-d449abdc-5a17-4a80-a0ff-669173704060   # replace with your actual Longhorn volume name
  createSnapshot: true
  labels:
    purpose: cli-demo
```

#### Step 2 – Apply the manifest

```bash
kubectl apply -f longhorn-snapshot.yaml
```

Expected output:

```
snapshot.longhorn.io/longhorn-test-snapshot created
```

#### Step 3 – Verify creation

```bash
kubectl get snapshots.longhorn.io -n longhorn-system
kubectl describe snapshot.longhorn.io longhorn-test-snapshot -n longhorn-system
```

Expected output:

```
NAME                     VOLUME                                     CREATIONTIME           READYTOUSE   RESTORESIZE   SIZE   AGE
longhorn-test-snapshot   pvc-d449abdc-5a17-4a80-a0ff-669173704060   2025-10-25T17:23:25Z   true         2147483648    0      17s
```

Sample details:

```
Spec:
  Create Snapshot:  true
  Labels:
    Purpose:  cli-demo
  Volume:     pvc-d449abdc-5a17-4a80-a0ff-669173704060
Status:
  Creation Time:  2025-10-25T17:23:25Z
  Ready To Use:   true
  Restore Size:   2147483648
```

> **Note**:
> If the volume is **detached**, you may briefly see a warning such as:
> `failed to take snapshot because the volume engine ... is not running. Waiting for the volume to be attached`
> This is expected. Longhorn will automatically retry when the volume is attached, and the snapshot will complete successfully.

### 2. Listing Snapshots for a Volume

List all snapshot CRs in the Longhorn namespace:

```bash
kubectl get snapshots.longhorn.io -n longhorn-system
```

Filter by volume:

```bash
kubectl get snapshots.longhorn.io -n longhorn-system --field-selector spec.volume=pvc-d449abdc-5a17-4a80-a0ff-669173704060
```

### 3. Restoring a Volume from a Snapshot

Restoring involves creating a new PVC (or Longhorn volume) that references the snapshot.

#### Step 1 – Delete or detach the original volume

If you are restoring over the same name or want a clean restore:

```bash
kubectl delete pvc longhorn-test-pvc -n default
```

#### Step 2 – Create a new PVC referencing the snapshot

Create `longhorn-pvc-restore.yaml`:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: restored-pvc
  namespace: default
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: longhorn
  dataSource:
    name: longhorn-test-snapshot      # Snapshot CR name
    kind: Snapshot
    apiGroup: longhorn.io
  resources:
    requests:
      storage: 2Gi
```

Apply it:

```bash
kubectl apply -f longhorn-pvc-restore.yaml
```

Then verify:

```bash
kubectl get pvc restored-pvc -n default
```

> **Note**:
> If you manage volumes directly (not via PVCs), you can also create a new `Volume` CR with the field:
>
> ```yaml
> spec:
>   fromSnapshot: longhorn-test-snapshot
> ```


### 4. Deleting a Snapshot

To remove the snapshot CR:

```bash
kubectl delete snapshot.longhorn.io longhorn-test-snapshot -n longhorn-system
```

Expected output:

```
snapshot.longhorn.io "longhorn-test-snapshot" deleted
```

Longhorn automatically handles the cleanup of the underlying data according to its internal retention and replica policies.

### Key CR Fields & Their Meanings

Below are key fields for `Snapshot` CRs (Longhorn `v1beta2`):

| Field                 | Location               | Description                                                         |
| --------------------- | ---------------------- | ------------------------------------------------------------------- |
| `spec.volume`         | `.spec.volume`         | Name of the Longhorn volume being snapshotted.                      |
| `spec.createSnapshot` | `.spec.createSnapshot` | Boolean — triggers snapshot creation.                               |
| `spec.labels`         | `.spec.labels`         | Optional user-defined labels for organizing or filtering snapshots. |
| `status.createdAt`    | `.status.createdAt`    | Timestamp when the snapshot was created.                            |
| `status.readyToUse`   | `.status.readyToUse`   | Indicates if the snapshot is available for restore operations.      |
| `status.restoreSize`  | `.status.restoreSize`  | Size of the restored data (bytes).                                  |
| `status.parent`       | `.status.parent`       | The parent snapshot (if part of a snapshot tree).                   |
| `status.children`     | `.status.children`     | Child snapshots branching from this snapshot.                       |
| `status.removed`      | `.status.removed`      | Whether the snapshot has been marked for removal/cleanup.           |

> **Tip**:
> Inspect snapshot details directly:
>
> ```bash
> kubectl get snapshot.longhorn.io longhorn-test-snapshot -n longhorn-system -o yaml
> ```

### Summary

| Step            | Command                                                                         | Verified Output               |
| --------------- | ------------------------------------------------------------------------------- | ----------------------------- |
| Create PVC      | `kubectl apply -f longhorn-test-pvc.yaml`                                       | PVC bound to Longhorn volume  |
| Check volume    | `kubectl get volumes.longhorn.io -n longhorn-system`                            | Volume listed as detached     |
| Create snapshot | `kubectl apply -f longhorn-snapshot.yaml`                                       | Snapshot created successfully |
| Verify snapshot | `kubectl get snapshots.longhorn.io -n longhorn-system`                          | `ReadyToUse: true`            |
| Delete snapshot | `kubectl delete snapshot.longhorn.io longhorn-test-snapshot -n longhorn-system` | Snapshot deleted              |
