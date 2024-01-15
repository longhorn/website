---
title: Volume Encryption
weight: 2
---

Longhorn supports volume encryption in both `Filesystem` and `Block` modes, providing protection against unauthorized access, data breaches, and compliance violations. Backups created from encrypted volumes are also encrypted.

This robust encryption is achieved through the integration of the Linux kernel module `dm_crypt`, the command-line utility `cryptsetup`, and the utilization of Kubernetes Secrets. The combination of `dm_crypt` and `cryptsetup` oversees the seamless creation and management of encrypted devices, while Secrets, along with associated permissions, ensures the secure storage of encryption keys.

# Requirements

For the utilization of encrypted volumes, it is essential to have the `dm_crypt` kernel module loaded and ensure the installation of `cryptsetup` on your worker nodes.

# Setting up Kubernetes Secrets and StorageClasses

Longhorn uses Kubernetes Secrets for secure storage of encryption keys. Kubernetes allows usage of template parameters that are resolved during volume creation. To use a Secret with an encrypted volume, you must configure the Secret as a StorageClass parameter.

Template parameters allow you to use Secrets with individual volumes or with a collection of volumes. For more information about template parameters, see [StorageClass Secrets](https://kubernetes-csi.github.io/docs/secrets-and-credentials-storage-class.html) in the Kubernetes CSI Developer Documentation.

In an example, your encryption keys are specified as part of the `CRYPTO_KEY_VALUE` parameter within the Secret. We use `stringData` as the type here so that there is no need for base64 encoding before submitting the Secret via kubectl create.

Besides `CRYPTO_KEY_VALUE`, parameters `CRYPTO_KEY_CIPHER`, `CRYPTO_KEY_HASH`, `CRYPTO_KEY_SIZE`, and `CRYPTO_PBKDF` provide the customization for volume encryption.
- `CRYPTO_KEY_CIPHER`: Sets the cipher specification algorithm string. The default value is `aes-xts-plain64` for LUKS.
- `CRYPTO_KEY_HASH`: Specifies the passphrase hash for `open`. The default value is `sha256`.
- `CRYPTO_KEY_SIZE`: Sets the key size in bits and it must be a multiple of 8. The default value is `256`.
- `CRYPTO_PBKDF`: Sets Password-Based Key Derivation Function (PBKDF) algorithm for LUKS keyslot. The default value is `argon2i`.

For more details, you can refer to the Linux manual page [crypsetup(8)](https://man7.org/linux/man-pages/man8/cryptsetup.8.html).

- Example Secret
  ```yaml
  apiVersion: v1
  kind: Secret
  metadata:
    name: longhorn-crypto
    namespace: longhorn-system
  stringData:
    CRYPTO_KEY_VALUE: "Your encryption passphrase"
    CRYPTO_KEY_PROVIDER: "secret"
    CRYPTO_KEY_CIPHER: "aes-xts-plain64"
    CRYPTO_KEY_HASH: "sha256"
    CRYPTO_KEY_SIZE: "256"
    CRYPTO_PBKDF: "argon2i"
  ```

- Example StorageClass for global key for all volumes
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

- Example StorageClass for per-volume key
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

# Using an Encrypted Volume

To create an encrypted volume, you just create a PVC utilizing a StorageClass that has been configured for encryption. The above StorageClass examples can be used as a starting point.

After creation of the PVC it will remain in `Pending` state till the associated secret has been created and can be retrieved
A newly-created PVC remains in the `Pending` state until the associated Secret is created and can be retrieved by the csi `external-provisioner` sidecar. Afterwards, the regular volume creation process continues with encryption taking effect.

# Filesystem Expansion

Longhorn supports [offline expansion](../../../volumes-and-nodes/expansion/#encrypted-volume) for encrypted volumes.

# History
- Encryption of volumes in `Filesystem` mode available starting v1.2.0 ([#1859](https://github.com/longhorn/longhorn/issues/1859))

- Encryption of volumes in `Block` mode available starting v1.6.0 ([#4883](https://github.com/longhorn/longhorn/issues/4883))