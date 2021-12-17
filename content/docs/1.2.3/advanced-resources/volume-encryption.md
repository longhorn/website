---
title: Volume Encryption
weight: 4
---

Longhorn supports encrypted volumes by utilizing the linux kernel module `dm_crypt` via `cryptsetup` for the encryption.
Further we use the Kubernetes secret mechanism for key storage, which can be further encrypted and guarded via appropriate permissions.
An encrypted volume results in your data being encrypted while in transit as well as at rest, this also means that any backups taken from that volume are also encrypted.

# Requirements

To be able to use encrypted volumes, you will need to have the `dm_crypt` kernel module loaded
and `cryptsetup` installed on your worker nodes.

# Setting up Kubernetes Secrets
Volume encryption utilizes Kubernetes secrets for encryption key storage.
To configure the secret that will be used for an encrypted volume, you will need to specify the secret as part of the parameters of a storage class.
This mechanism is provided by Kubernetes and allows the usage of some template parameters that will be resolved as part of volume creation.

The template parameters can be useful in the case where you want to use a per volume secret or a group secret for a specific collection of volumes.
More information about the available template parameters can be found in the [Kubernetes documentation](https://kubernetes-csi.github.io/docs/secrets-and-credentials-storage-class.html).

Example secret your encryption keys are specified as part of the `CRYPTO_KEY_VALUE` parameter.
We use `stringData` as type here so we don't have to base64 encoded before submitting the secret via `kubectl create`.
```yaml
---
apiVersion: v1
kind: Secret
metadata:
  name: longhorn-crypto
  namespace: longhorn-system
stringData:
  CRYPTO_KEY_VALUE: "Your encryption passphrase"
  CRYPTO_KEY_PROVIDER: "secret"
```

Example storage class (global key for all volumes)
```yaml
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: longhorn-crypto-global
provisioner: driver.longhorn.io
allowVolumeExpansion: true
parameters:
  numberOfReplicas: "3"
  staleReplicaTimeout: "2880" # 48 hours in minutes
  fromBackup: ""
  encrypted: "true"
  # global secret that contains the encryption key that will be used for all volumes
  csi.storage.k8s.io/provisioner-secret-name: "longhorn-crypto"
  csi.storage.k8s.io/provisioner-secret-namespace: "longhorn-system"
  csi.storage.k8s.io/node-publish-secret-name: "longhorn-crypto"
  csi.storage.k8s.io/node-publish-secret-namespace: "longhorn-system"
  csi.storage.k8s.io/node-stage-secret-name: "longhorn-crypto"
  csi.storage.k8s.io/node-stage-secret-namespace: "longhorn-system"
```

Example storage class (per volume key)
```yaml
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: longhorn-crypto-per-volume
provisioner: driver.longhorn.io
allowVolumeExpansion: true
parameters:
  numberOfReplicas: "3"
  staleReplicaTimeout: "2880" # 48 hours in minutes
  fromBackup: ""
  encrypted: "true"
  # per volume secret which utilizes the `pvc.name` and `pvc.namespace` template parameters
  csi.storage.k8s.io/provisioner-secret-name: ${pvc.name}
  csi.storage.k8s.io/provisioner-secret-namespace: ${pvc.namespace}
  csi.storage.k8s.io/node-publish-secret-name: ${pvc.name}
  csi.storage.k8s.io/node-publish-secret-namespace: ${pvc.namespace}
  csi.storage.k8s.io/node-stage-secret-name: ${pvc.name}
  csi.storage.k8s.io/node-stage-secret-namespace: ${pvc.namespace}
```

# Using an encrypted volume

To create an encrypted volume, you just create a PVC utilizing a storage class that has been configured for encryption.
The above storage class examples can be used as a starting point.

After creation of the PVC it will remain in `Pending` state till the associated secret has been created and can be retrieved
by the csi `external-provisioner` sidecar. Afterwards the regular volume creation flow will take over and the encryption will be
transparently used so no additional actions are needed from the user.

# Filesystem expansion

The encrypted filesystem needs manual expansion after regular [expansion](../../volumes-and-nodes/expansion) of the Longhorn block device.
After offline volume expansion is completed the next time the volume is used by a workload, one can do an online filesystem expansion either on the node
or as part of a shell in the workload pod.

The following commands can be used on the node where the encrypted volume is being used to expand the filesystem.
For `EXT4` one can use `resize2fs /dev/mapper/<volume-name>`
For `XFS` one can use `xfs_growfs /dev/mapper/<volume-name>`

# History
Available since v1.2.0 [#1859](https://github.com/longhorn/longhorn/issues/1859)
