---
title: CSI VolumeSnapshot Associated with Longhorn BackingImage
weight: 2
---

BackingImage in Longhorn is an object that represents a QCOW2 or RAW image which can be set as the backing/base image of a Longhorn volume.

Instead of directly using Longhorn BackingImage resource for BackingImage management. You can also use the generic Kubernetes CSI VolumeSnapshot mechanism. To learn more about the CSI VolumeSnapshot mechanism, click [here](https://kubernetes.io/docs/concepts/storage/volume-snapshots/).

> **Prerequisite:** CSI snapshot support needs to be enabled on your cluster.
> If your kubernetes distribution does not provide the kubernetes snapshot controller
> as well as the snapshot related custom resource definitions, you need to manually deploy them.
> For more information, see [Enable CSI Snapshot Support](../enable-csi-snapshot-support).

## Create A CSI VolumeSnapshot Associated With Longhorn BackingImage

To create a CSI VolumeSnapshot associated with a Longhorn BackingImage, you first need to create a `VolumeSnapshotClass` object
with the parameter `type` set to `bi` as follow:
```yaml
kind: VolumeSnapshotClass
apiVersion: snapshot.storage.k8s.io/v1
metadata:
  name: longhorn-snapshot-vsc
driver: driver.longhorn.io
deletionPolicy: Delete
parameters:
  type: bi
  # export-type default to raw if it is not given
  export-type: qcow2
```
For more information about `VolumeSnapshotClass`, see the kubernetes documentation for [VolumeSnapshotClasses](https://kubernetes.io/docs/concepts/storage/volume-snapshot-classes/).

After that, create a Kubernetes `VolumeSnapshot` object with `volumeSnapshotClassName` points to the name of the `VolumeSnapshotClass` (`longhorn-snapshot-vsc`) and
the `source` points to the PVC of the Longhorn volume for which a Longhorn BackingImage should be exported from.
```yaml
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshot
metadata:
  name: test-csi-volume-snapshot-longhorn-backing-image
spec:
  volumeSnapshotClassName: longhorn-snapshot-vsc
  source:
    persistentVolumeClaimName: test-vol
```

**Result:**
A Longhorn BackingImage is created. The `VolumeSnapshot` object creation leads to the creation of a `VolumeSnapshotContent` Kubernetes object.
The `VolumeSnapshotContent` refers to a Longhorn BackingImage in its `VolumeSnapshotContent.snapshotHandle` field with the name `bi://backing?backingImageDataSourceType=export-from-volume&backingImage=${GENERATED_SNAPSHOT_NAME}&volume-name=test-vol&export-type=qcow2`.

### Viewing the Longhorn BackingImage

To see the BackingImage, click **Setting > Backing Image** in the top navigation bar and click the BackingImage mentioned in the `VolumeSnapshotContent.snapshotHandle`.


### How the CSI Mechanism Works in this Scenario

When the VolumeSnapshot object is created with kubectl, the `VolumeSnapshot.uuid` field is used to identify a Longhorn BackingImage and the associated `VolumeSnapshotContent` object.

This creates a new Longhorn BackingImage named `snapshot-uuid` and the CSI request returns.

Afterwards a `VolumeSnapshotContent` object named `snapcontent-uuid` is created with the `VolumeSnapshotContent.readyToUse` flag is set to **true**.


## Restore PVC from CSI VolumeSnapshot Associated With Longhorn BackingImage
Create a `PersistentVolumeClaim` object where the `dataSource` field points to an existing `VolumeSnapshot` object that is associated with Longhorn BackingImage.

The csi-provisioner will pick this up and instruct the Longhorn CSI driver to provision a new volume using the associated Longhorn BackingImage.

An example `PersistentVolumeClaim` is below. The `dataSource` field needs to point to an existing `VolumeSnapshot` object.

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-restore-pvc
spec:
  storageClassName: longhorn
  dataSource:
    name: test-csi-volume-snapshot-longhorn-backing-image
    kind: VolumeSnapshot
    apiGroup: snapshot.storage.k8s.io
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
```

### Restore a Longhorn BackingImage that Has No Associated `VolumeSnapshot` (pre-provision)

You can use the CSI mechanism to restore Longhorn BackingImage that has not been created via the CSI mechanism.
To restore Longhorn BackingImage that has not been created via the CSI mechanism, you have to first manually create a `VolumeSnapshot` and `VolumeSnapshotContent` object for the BackingImage.

Create a `VolumeSnapshotContent` object with the `snapshotHandle` field set to `bi://backing?backingImageDataSourceType=${TYPE}&backingImage=${BACKINGIMAGE_NAME}&backingImageChecksum=${backingImageChecksum}&${OTHER_PARAMETERS}` which point to an existing BackingImage.

- Users need to provide following query parameters in `snapshotHandle` for validation purpose:
    - `backingImageDataSourceType`: `sourceType` of existing BackingImage, e.g. `export-from-volume`, `download`
    - `backingImage`: Name of the BackingImage
    - `backingImageChecksum`: Optional. Checksum of the BackingImage.
    - you should also provide the `sourceParameters` of existing BackingImage in the `snapshotHandle` based on the `backingImageDataSourceType`
      - `export-from-volume`:
        - `volume-name`: volume to be expoted from.
        - `export-type`: qcow2 or raw.
      - `download`:
        - `url`: url of the BackingImage.
        - `checksum`: optional.

The parameters can be retrieved from the **Setting > Backing Image** page in the Longhorn UI.

```yaml
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshotContent
metadata:
  name: test-existing-backing
spec:
  volumeSnapshotClassName: longhorn-snapshot-vsc
  driver: driver.longhorn.io
  deletionPolicy: Delete
  source:
    snapshotHandle: bi://backing?backingImageDataSourceType=download&backingImage=test-bi&url=https%3A%2F%2Flonghorn-backing-image.s3-us-west-1.amazonaws.com%2Fparrot.qcow2&backingImageChecksum=bd79ab9e6d45abf4f3f0adf552a868074dd235c4698ce7258d521160e0ad79ffe555b94e7d4007add6e1a25f4526885eb25c53ce38f7d344dd4925b9f2cb5d3b
  volumeSnapshotRef:
    name: test-snapshot-existing-backing
    namespace: default
```

Create the associated `VolumeSnapshot` object with the `name` field set to `test-snapshot-existing-backing`, where the `source` field refers to a `VolumeSnapshotContent` object via the `volumeSnapshotContentName` field.

This differs from the creation of a BackingImage, in which case the `source` field refers to a `PerstistentVolumeClaim` via the `persistentVolumeClaimName` field.

Only one type of reference can be set for a `VolumeSnapshot` object.

```yaml
apiVersion: snapshot.storage.k8s.io/v1beta1
kind: VolumeSnapshot
metadata:
  name: test-snapshot-existing-backing
spec:
  volumeSnapshotClassName: longhorn-snapshot-vsc
  source:
    volumeSnapshotContentName: test-existing-backing
```

Now you can create a `PerstistantVolumeClaim` object that refers to the newly created `VolumeSnapshot` object.
For an example see [Restore PVC from CSI VolumeSnapshot Associated With Longhorn BackingImage](#restore-pvc-from-csi-volumesnapshot-associated-with-longhorn-backingimage) above.


### Restore a Longhorn BackingImage that Has Not Created (on-demand provision)

You can use the CSI mechanism to restore Longhorn BackingImage which has not been created yet. This mechanism only support following 2 kinds of BackingImage data sources.

1. `download`: Download a file from a URL as a BackingImage.
2. `export-from-volume`: Export an existing in-cluster volume as a backing image.

Users need to create the `VolumeSnapshotContent` with an associated `VolumeSnapshot`. The `snapshotHandle` of the `VolumeSnapshotContent` needs to provide the parameters of the data source. Example below for a non-existing BackingImage `test-bi` with two different data sources.

1. `download`: Users need to provide following parameters
    - `backingImageDataSourceType`: `download` for on-demand download.
    - `backingImage`: Name of the BackingImage
    - `url`: Download the file from a URL as a BackingImage.
    - `backingImageChecksum`: Optional. Used for validating the file.
    - example yaml:
        ```yaml
        apiVersion: snapshot.storage.k8s.io/v1
        kind: VolumeSnapshotContent
        metadata:
            name: test-on-demand-backing
        spec:
            volumeSnapshotClassName: longhorn-snapshot-vsc
            driver: driver.longhorn.io
            deletionPolicy: Delete
            source:
              # NOTE: change this to provide the correct parameters
              snapshotHandle: bi://backing?backingImageDataSourceType=download&backingImage=test-bi&url=https%3A%2F%2Flonghorn-backing-image.s3-us-west-1.amazonaws.com%2Fparrot.qcow2&backingImageChecksum=bd79ab9e6d45abf4f3f0adf552a868074dd235c4698ce7258d521160e0ad79ffe555b94e7d4007add6e1a25f4526885eb25c53ce38f7d344dd4925b9f2cb5d3b
        volumeSnapshotRef:
            name: test-snapshot-on-demand-backing
            namespace: default
        ```

2. `export-from-volume`: Users need to provide following parameters
    - `backingImageDataSourceType`: `export-form-volume` for on-demand export.
    - `backingImage`: Name of the BackingImage
    - `volume-name`: Volume to be exported for the BackingImage
    - `export-type`: Currently Longhorn supports `raw` or `qcow2`
    - example yaml:
        ```yaml
        apiVersion: snapshot.storage.k8s.io/v1
        kind: VolumeSnapshotContent
        metadata:
        name: test-on-demand-backing
        spec:
        volumeSnapshotClassName: longhorn-snapshot-vsc
        driver: driver.longhorn.io
        deletionPolicy: Delete
        source: 
          # NOTE: change this to provide the correct parameters
          snapshotHandle: bi://backing?backingImageDataSourceType=export-from-volume&backingImage=test-bi&volume-name=vol-export-src&export-type=qcow2
        volumeSnapshotRef:
            name: test-snapshot-on-demand-backing
            namespace: default
        ```

Create the associated `VolumeSnapshot` object with the `name` field set to `test-snapshot-on-demand-backing`, where the `source` field refers to a `VolumeSnapshotContent` object via the `volumeSnapshotContentName` field.

This differs from the creation of a BackingImage, in which case the `source` field refers to a `PerstistentVolumeClaim` via the `persistentVolumeClaimName` field.

Only one type of reference can be set for a `VolumeSnapshot` object.

```yaml
apiVersion: snapshot.storage.k8s.io/v1beta1
kind: VolumeSnapshot
metadata:
  name: test-snapshot-on-demand-backing
spec:
  volumeSnapshotClassName: longhorn-snapshot-vsc
  source:
    volumeSnapshotContentName: test-on-demand-backing
```

Now you can create a `PerstistantVolumeClaim` object that refers to the newly created `VolumeSnapshot` object.
Longhorn will create the BackingImage with the parameters provide in the `snapshotHandle`.
For an example see [Restore PVC from CSI VolumeSnapshot Associated With Longhorn BackingImage](#restore-pvc-from-csi-volumesnapshot-associated-with-longhorn-backingimage) above.
