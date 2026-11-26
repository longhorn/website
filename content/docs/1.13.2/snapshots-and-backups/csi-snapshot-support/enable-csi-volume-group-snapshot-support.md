---
title: Enable CSI Volume Group Snapshot Support on a Cluster
weight: 4
---

Taking a [CSI VolumeGroupSnapshot](../csi-volume-group-snapshot) requires three things on top of regular CSI snapshot support:

1. The VolumeGroupSnapshot CRDs.
2. The `CSIVolumeGroupSnapshot` feature gate enabled on the snapshot-controller.
3. The same feature gate enabled on the csi-snapshotter deployed by Longhorn.

> **Prerequisite:**
> CSI snapshot support must be enabled on your cluster. See [Enable CSI Snapshot Support](../enable-csi-snapshot-support).

> **Warning: Potential Snapshot Outage**
> Install the VolumeGroupSnapshot CRDs **before** enabling the `CSIVolumeGroupSnapshot` feature gate on any component. If the feature gate is enabled while the CRDs are missing, the csi-snapshotter sidecar stops serving regular volume snapshots. Every `VolumeSnapshot` in the cluster will hang in the `Pending` state even though the sidecar pod reports `Running`.

## Install the VolumeGroupSnapshot CRDs

The CRDs ship with [external-snapshotter](https://github.com/kubernetes-csi/external-snapshotter/releases): `VolumeGroupSnapshotClass`, `VolumeGroupSnapshot`, and `VolumeGroupSnapshotContent` in the `groupsnapshot.storage.k8s.io` API group.

Use release `v8.6.0` or later so they serve the `v1` API. Replace `<version>` in the URLs below with your target release (e.g., `v8.6.0`) and apply:

```shell
kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/<version>/client/config/crd/groupsnapshot.storage.k8s.io_volumegroupsnapshotclasses.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/<version>/client/config/crd/groupsnapshot.storage.k8s.io_volumegroupsnapshots.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/<version>/client/config/crd/groupsnapshot.storage.k8s.io_volumegroupsnapshotcontents.yaml
```

## Enable the Feature Gate on the snapshot-controller

The snapshot-controller processes `VolumeGroupSnapshot` objects only when its `CSIVolumeGroupSnapshot` feature gate is on. The controller must also be from external-snapshotter v8.6.0 or later.

Add the feature gate to the controller arguments, adjusting the namespace to where your snapshot-controller is deployed (default is `kube-system`):

```shell
kubectl -n kube-system patch deploy snapshot-controller --type=json \
  -p='[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--feature-gates=CSIVolumeGroupSnapshot=true"}]'
```

## Enable VolumeGroupSnapshot Support in Longhorn

In Longhorn, VolumeGroupSnapshot support is off by default. Enabling it turns on the `CSIVolumeGroupSnapshot` feature gate of the csi-snapshotter that Longhorn deploys.

- **For Helm installations**: Set the chart value `csi.volumeGroupSnapshotEnabled` to `true`.
- **For kubectl installations**: Uncomment the `CSI_VOLUME_GROUP_SNAPSHOT_ENABLED` environment variable in the `longhorn-driver-deployer` Deployment of the deploy manifest:

  ```yaml
  - name: CSI_VOLUME_GROUP_SNAPSHOT_ENABLED
    value: "true"
  ```

> **Troubleshooting:**: When the Longhorn toggle is enabled but the VolumeGroupSnapshot CRDs are missing (or not served at `v1`), the Longhorn driver deployer will fail with an error naming the missing CRDs. However, regular per-volume snapshots will keep working. To recover, simply install the CRDs (or disable the toggle) and redeploy.
