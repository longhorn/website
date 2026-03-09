---
title: Longhorn VolumeAttachment
weight: 1
---

**Table of Contents**
- [Kubernetes and Longhorn `VolumeAttachment`](#kubernetes-and-longhorn-volumeattachment)
- [Longhorn VolumeAttachment](#longhorn-volumeattachment)
  - [VolumeAttachment CR](#volumeattachment-cr)
  - [Understanding Attachment Tickets](#understanding-attachment-tickets)
- [The CSI Attachment and Detachment Workflow](#the-csi-attachment-and-detachment-workflow)
  - [Core Components in the Workflow](#core-components-in-the-workflow)
  - [The CSI Volume Attachment Flow](#the-csi-volume-attachment-flow)
  - [The CSI Volume Detachment Flow](#the-csi-volume-detachment-flow)
  - [Summary of the Workflow](#summary-of-the-workflow)
- [Troubleshooting Volume Attachment Issues](#troubleshooting-volume-attachment-issues)
  - [Volume is Stuck in `Attaching` or `Detaching` State](#volume-is-stuck-in-attaching-or-detaching-state)
    - [Possible Causes](#possible-causes)
    - [Resolution Steps](#resolution-steps)
  - [Case Study](#case-study)
    - [Case 1: Failure to Attach Volume Due to Unexpected `longhorn-ui` Attachment Ticket](#case-1-failure-to-attach-volume-due-to-unexpected-longhorn-ui-attachment-ticket)
    - [Case 2: Volume Fails to Attach to New Node Due to Backup Job Stuck in Pending State](#case-2-volume-fails-to-attach-to-new-node-due-to-backup-job-stuck-in-pending-state)

---

This document provides a detailed overview of Longhorn's `VolumeAttachment` custom resource, how it integrates with Kubernetes' native `VolumeAttachment`, its operational flow, and common troubleshooting scenarios.

## Kubernetes and Longhorn `VolumeAttachment`

To understand how volume attachments work in Longhorn, it is important to distinguish between the Kubernetes `VolumeAttachment` and Longhorn's custom `VolumeAttachment`:

- **Kubernetes `VolumeAttachment`**: It is a native Kubernetes API resource that is part of the Container Storage Interface (CSI) specification. Its primary role is to signal to a CSI driver that a volume should be attached to a specific node.

- **Longhorn `VolumeAttachment`**: It is a Custom Resource (CR) defined by Longhorn, with the full name `volumeattachment.longhorn.io`. This internal Longhorn resource is used by the Longhorn Manager to track and manage all attachment requests for a volume.

## Longhorn VolumeAttachment

### VolumeAttachment CR

To retrieve a Longhorn `VolumeAttachment`, use the following command:

```bash
kubectl -n longhorn-system get volumeattachment.longhorn.io <volume-name> -o yaml
```

Example output:

```bash
apiVersion: v1
...
  spec:
    attachmentTickets:
      csi-f0471a334f0b249f964cd1dec461a5eb94c8d268cbbc904c1a8e9a37e2045208:
        generation: 0
        id: csi-f0471a334f0b249f964cd1dec461a5eb94c8d268cbbc904c1a8e9a37e2045208
        nodeID: rancher60-master
        parameters:
          disableFrontend: "false"
          lastAttachedBy: ""
        type: csi-attacher
    volume: pvc-b26e9514-aafd-46e0-b70c-4e3f187c7977
  status:
    attachmentTicketStatuses:
      csi-f0471a334f0b249f964cd1dec461a5eb94c8d268cbbc904c1a8e9a37e2045208:
        conditions:
        - lastProbeTime: ""
          lastTransitionTime: "2025-07-05T09:17:27Z"
          message: ""
          reason: ""
          status: "True"
          type: Satisfied
        generation: 0
        id: csi-f0471a334f0b249f964cd1dec461a5eb94c8d268cbbc904c1a8e9a37e2045208
        satisfied: true
...
```

- `spec.attachmentTickets`: A map containing all active attachment requests (also known as **tickets**). Each ticket includes:
  - `id`: A unique identifier for each attachment ticket.
  - `nodeID`: The ID of the node where the volume should be attached.
  - `parameters`: Optional parameters for the attachment, such as `disableFrontend` and `lastAttachedBy`.
  - `type`: The attacher type, indicating the source of the attachment request.

- `status.attachmentTicketStatuses`: A map containing the current status of each active attachment ticket or request. Each entry includes:
  - `conditions`: The current condition(s) of the ticket, including whether the request is satisfied or not.
  - `satisfied`: A boolean value indicating whether the attachment request has been fulfilled or not.
  - `generation`: The generation number of the ticket, used to track updates.

### Understanding Attachment Tickets

The Longhorn `VolumeAttachment` custom resource (CR) is designed to manage attachment requests from various internal Longhorn system controllers. Each request is represented as an **attachment ticket** within the CR.

All active tickets are stored in the `spec.attachmentTickets` map. The `type` field in each ticket (referred to as the **AttacherType**) identifies the source of the request. The common `AttacherType` values include:

- `csi-attacher`: The most common type which handles standard attachment requests from the Kubernetes CSI plugin, typically when mounting a volume to a pod.
- `longhorn-api`: Represents a manual attachment request initiated by a user, either through the Longhorn UI or the Longhorn API.
- `snapshot-controller`: Used when attaching a volume to create or restore a snapshot.
- `backup-controller`: Used when attaching a volume to perform a backup.
- `volume-restore-controller`: Used when attaching a volume during a restore operation.
- `volume-clone-controller`: Used when attaching a volume for cloning from an existing volume.
- `share-manager-controller`: Manages backend volume attachments for ReadWriteMany (RWX) volumes by attaching them to the share-manager pod.
- `volume-expansion-controller`: Handles attachments needed for online volume expansion.
- `volume-rebuilding-controller`: Used when attaching a volume to rebuild a degraded or missing replica.
- `salvage-controller`: Used during the salvage process when Longhorn attempts to recover and reattach a problematic volume.
- `volume-eviction-controller`: Handles attachments involved in evicting a replica from a node.
- `bim-ds-controller`: Used by the Backing Image Data Source controller when creating a volume from a backing image.

## The CSI Attachment and Detachment Workflow

To understand how Longhorn integrates with Kubernetes, it is important to examine how the native Kubernetes `VolumeAttachment` resource and Longhorn’s custom `VolumeAttachment` CR interact through the CSI interface.

### Core Components in the Workflow

In addition to the Kubernetes and Longhorn `VolumeAttachment` objects, several key components work together to manage volume attachment and detachment:

- `external-attacher`: A CSI sidecar container that monitors Kubernetes `VolumeAttachment` objects and triggers `ControllerPublishVolume` or `ControllerUnpublishVolume` gRPC calls to the Longhorn CSI driver.
- `longhorn-csi-plugin`: The Longhorn CSI driver that implements the required CSI gRPC services.
- `longhorn-manager`: The central controller in Longhorn that manages the full lifecycle of Longhorn volumes. It includes various sub-controllers, including the volume attachment logic.
- `longhorn-volume-attachment-controller`: A sub-controller within `longhorn-manager` that monitors the Longhorn `VolumeAttachment` CR and performs attach or detach operations based on its spec.

### The CSI Volume Attachment Flow

When a pod that uses a Longhorn PersistentVolumeClaim (PVC) is scheduled onto a node, the CSI volume attachment workflow is triggered.

1. **kubelet Request**: The kubelet on the target node detects that a Longhorn volume needs to be mounted and notifies the Kubernetes `attach-detach-controller`.

2. **Kubernetes `VolumeAttachment` Creation**: The `attach-detach-controller` creates a Kubernetes `VolumeAttachment` object, specifying the Longhorn CSI driver (`driver.longhorn.io`), the target node name, and the persistent volume name.

3. **`external-attacher` Triggers CSI Call**: The `external-attacher` sidecar container observes the new Kubernetes `VolumeAttachment` object and issues a `ControllerPublishVolume` gRPC call to the `longhorn-csi-plugin`.

4. **Longhorn `VolumeAttachment` CR Creation**: Rather than attaching the volume directly, the `longhorn-csi-plugin` creates a Longhorn `VolumeAttachment` custom resource (CR). It adds an **attachment ticket** to the CR’s spec to represent the attachment request.

5. **Longhorn Controller Reconciliation**: The `longhorn-volume-attachment-controller`, a sub-controller within `longhorn-manager`, detects the new ticket and begins reconciliation. It verifies that the volume is available and updates the corresponding Volume CR’s `spec.nodeID` with the target node name.

6. **`longhorn-manager` Executes Attachment**: After detecting that `spec.nodeID` is set, `longhorn-manager` starts the Longhorn Engine on the specified node to complete the attachment.

7. **Volume Attachment Completion**:
   - `longhorn-manager` updates the Volume CR’s status to reflect that the volume is attached.
   - The `longhorn-volume-attachment-controller` updates the Longhorn `VolumeAttachment` CR’s status to indicate success.
   - The `longhorn-csi-plugin` receives the successful status and responds to the `external-attacher`.
   - Finally, the `external-attacher` marks the Kubernetes `VolumeAttachment` object’s `status.attached` field as `true`.

8. **kubelet Mounts the Volume**: Once the volume is marked as attached, the kubelet proceeds with the `NodeStageVolume` and `NodePublishVolume` CSI calls to mount the volume into the pod’s container.

### The CSI Volume Detachment Flow

When a pod using a Longhorn volume is deleted or rescheduled, the CSI detachment workflow is triggered.

1. **kubelet Request**: The kubelet signals to the Kubernetes `attach-detach-controller` that the volume is no longer needed on the node.

2. **Kubernetes `VolumeAttachment` Deletion**: The `attach-detach-controller` deletes the corresponding Kubernetes `VolumeAttachment` object.

3. **`external-attacher` Triggers CSI Call**: The `external-attacher` observes the deletion and initiates a `ControllerUnpublishVolume` gRPC call to the `longhorn-csi-plugin`.

4. **Attachment Ticket Removal**: The `longhorn-csi-plugin` processes the request by updating the Longhorn `VolumeAttachment` CR to remove the relevant attachment ticket.

5. **Longhorn Controller Reconciliation**: The `longhorn-volume-attachment-controller` detects that the ticket has been removed. If no other tickets exist for the volume, it clears the `spec.nodeID` field in the Longhorn Volume CR.

6. **`longhorn-manager` Executes Detachment**: With the `spec.nodeID` cleared, `longhorn-manager` initiates the detachment process by stopping the Longhorn Engine on the node.

7. **Volume Detachment Completion**:
   - `longhorn-manager` updates the Volume CR’s status to indicate that the volume is detached.
   - The `longhorn-csi-plugin` receives confirmation and responds with success to the `external-attacher`.
   - The `external-attacher` removes the finalizer from the Kubernetes `VolumeAttachment` object, allowing the API server to fully delete it.

### Summary of the Workflow

Longhorn extends the native volume attachment mechanism of Kubernetes by introducing a custom `VolumeAttachment` CR. This design provides several advantages:

- **Decoupling and Abstraction**: The custom resource encapsulates complex attach or detach logic within Longhorn, reducing the responsibilities of the `longhorn-csi-plugin`.
- **Fine-Grained Control**: The attachment ticket system enables Longhorn to handle requests from multiple sources (for example, pods, snapshots, backups) while ensuring only one valid attachment per volume at any time.
- **Observability and Troubleshooting**: The CR gives clear visibility into attachment state and history of the volume, simplifying monitoring and troubleshooting.

In summary, the Kubernetes `VolumeAttachment` object initiates the attachment or detachment process, while Longhorn’s custom `VolumeAttachment` CR orchestrates and manages the actual operations internally.

## Troubleshooting Volume Attachment Issues

This section outlines common issues related to volume attachment and provides recommended resolution steps. Before making any changes, carefully inspect system logs and the relevant custom resources to avoid disrupting active workloads.

### Volume is Stuck in `Attaching` or `Detaching` State

When a volume remains in the `Attaching` or `Detaching` state for an extended period, the cause is often related to stale or conflicting attachment tickets in the Longhorn `VolumeAttachment` CR.

#### Possible Causes

- **Stale or Orphaned Tickets**: A ticket from a previous workload (for example, a deleted pod or completed backup job) was not properly removed and still exists under `spec.attachmentTickets`.

- **Conflicting Tickets**: An existing ticket (for example, from the CSI attacher) blocks a new request (for example, a manual detach or move to a different node).

#### Resolution Steps

1. **Inspect the Longhorn `VolumeAttachment` CR**: Use the following command to view the attachment tickets:

    ```bash
    kubectl -n longhorn-system get volumeattachment.longhorn.io <volume-name> -o yaml
    ```

2. **Analyze Ticket Sources**: Look under `spec.attachmentTickets` and check the `type` field for each ticket to identify its source (for example, `csi-attacher`, `backup-controller`, etc.).

3. **Remove Invalid Tickets with Caution**: If you confirm a ticket is no longer needed (for example, its corresponding pod has been deleted), you may remove it by editing the CR.

  > **Warning:**
  >
  > Deleting an active ticket can cause serious disruptions. If you remove a ticket still required by a running workload, Longhorn interprets this as a detach request:
  >
  > - The volume engine will stop on the node, causing the pod to lose storage access and encounter I/O errors, likely crashing the pod.
  > - Kubernetes CSI will eventually detect the issue and re-attach the volume, recreating the ticket, but this causes downtime and may require manual pod restart.
  >
  > Always verify that the workload related to the ticket is inactive before removing it.

4. **Verify the State**: After removing invalid tickets, Longhorn should be able to complete the attach or detach operation successfully.

### Case Study

#### Case 1: Failure to Attach Volume Due to Unexpected `longhorn-ui` Attachment Ticket

- **Issue**: Longhorn [#8339](https://github.com/longhorn/longhorn/issues/8339)  
- **Symptom**:  
  - Workloads using the affected volume remain stuck in `Pending` state.  
  - The Longhorn `VolumeAttachment` CR contains an unexpected ticket from `longhorn-ui`.  
- **Workaround**:  
  - Inspect the `VolumeAttachment` CR:  
    ```bash
    kubectl -n longhorn-system get volumeattachment.longhorn.io <volume-name> -o yaml
    ```  
  - If you find a `longhorn-ui` attachment ticket, remove the entire ticket block from the CR.

#### Case 2: Volume Fails to Attach to New Node Due to Backup Job Stuck in Pending State

- **Issue**: Longhorn [#10090](https://github.com/longhorn/longhorn/issues/10090)  
- **Symptom**:  
  - When a workload is rescheduled to a different node, the volume fails to follow.  
  - Backup jobs referencing non-existent snapshots remain stuck in `Pending` state, with `status.message` containing `failed to get the snapshot ... not found`.  
  - These stuck backup jobs hold onto the volume, blocking detach/reattach.  
- **Workaround**:  
  1. Check the Longhorn `VolumeAttachment` CR for any tickets locking the volume:  
      ```bash
      kubectl -n longhorn-system get volumeattachment.longhorn.io <volume-name> -o yaml
      ```  
  2. If you see a ticket from the backup controller, a backup job is locking the volume.  
  3. **Do not delete the `backup-*` attachment ticket directly**, as Longhorn will recreate it.  
  4. Instead, resolve the stuck backup job by removing any `Backup` CRs with:  
       - `status.state = pending`  
       - `status.message` containing `Failed to get the Snapshot...`

      This releases the volume and allows it to be reattached.
