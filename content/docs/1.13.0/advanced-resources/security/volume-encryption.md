---
title: Volume Encryption
weight: 2
---

Longhorn supports volume encryption in both `Filesystem` and `Block` modes, providing protection against unauthorized access, data breaches, and compliance violations. Backups created from encrypted volumes are also encrypted.

Volume encryption is made possible by the Linux kernel module `dm_crypt`, the command-line utility `cryptsetup`, and Kubernetes Secrets. `dm_crypt` and `cryptsetup` handle the creation and management of encrypted devices, while Secrets (and related permissions) facilitate secure storage of encryption keys.

# Requirements

To use encrypted volumes, ensure that the `dm_crypt` kernel module is loaded and that `cryptsetup` is installed on your worker nodes.

# Setting up Kubernetes Secrets and StorageClasses

Longhorn uses Kubernetes Secrets for secure storage of encryption keys. Kubernetes allows usage of template parameters that are resolved during volume creation. To use a Secret with an encrypted volume, you must configure the Secret as a StorageClass parameter.

Template parameters allow you to use Secrets with individual volumes or with a collection of volumes. For more information about template parameters, see [StorageClass Secrets](https://kubernetes-csi.github.io/docs/secrets-and-credentials-storage-class.html) in the Kubernetes CSI Developer Documentation.

In the following example, the encryption key is specified as string data in the `CRYPTO_KEY_VALUE` parameter of the Secret. Using string data eliminates the need for Base64 encoding before the Secret is submitted via kubectl create.

Besides `CRYPTO_KEY_VALUE`, parameters `CRYPTO_KEY_CIPHER`, `CRYPTO_KEY_HASH`, `CRYPTO_KEY_SIZE`, `CRYPTO_PBKDF`, `CRYPTO_PBKDF_FORCE_ITERATIONS`, and `CRYPTO_PBKDF_MEMORY` provide the customization for volume encryption.
- `CRYPTO_KEY_CIPHER`: Sets the cipher specification algorithm string. The default value is `aes-xts-plain64` for LUKS.
- `CRYPTO_KEY_HASH`: Specifies the passphrase hash for `open`. The default value is `sha256`.
- `CRYPTO_KEY_SIZE`: Sets the key size in bits and it must be a multiple of 8. The default value is `256`.
- `CRYPTO_PBKDF`: Sets Password-Based Key Derivation Function (PBKDF) algorithm for LUKS keyslot. The default value is `argon2i`.
- `CRYPTO_PBKDF_FORCE_ITERATIONS`: Sets a fixed iteration count for the PBKDF algorithm. When specified, this overrides cryptsetup's default auto-tuning behavior. In FIPS mode, where PBKDF2 is required, specifying an explicit iteration count (such as `200000`) helps meet security policy requirements and avoids errors like "Not compatible PBKDF2 options". The default value is `200000` (Longhorn default).
- `CRYPTO_PBKDF_MEMORY`: Sets the memory cost (in KB) for the PBKDF algorithm. This parameter is only applicable to memory-hard algorithms such as Argon2 (`argon2i` or `argon2id`) and has no effect when PBKDF2 is used. In FIPS mode, Argon2 is not allowed and PBKDF2 is used instead, so this parameter is ignored. The default value is `0`.

For more information, see [cryptsetup(8)](https://man7.org/linux/man-pages/man8/cryptsetup.8.html) in the Linux man pages.

- Example of a Secret:
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
    CRYPTO_PBKDF_FORCE_ITERATIONS: "200000" 
    CRYPTO_PBKDF_MEMORY: "0" 
  ```

- Example of a StorageClass with a global Secret:
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
    csi.storage.k8s.io/node-publish-secret-name: "longhorn-crypto"
    csi.storage.k8s.io/node-publish-secret-namespace: "longhorn-system"
    csi.storage.k8s.io/node-stage-secret-name: "longhorn-crypto"
    csi.storage.k8s.io/node-stage-secret-namespace: "longhorn-system"
    csi.storage.k8s.io/node-expand-secret-name: "longhorn-crypto"
    csi.storage.k8s.io/node-expand-secret-namespace: "longhorn-system"
  ```

- Example of a StorageClass with a volume-specific Secret:
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
    csi.storage.k8s.io/node-publish-secret-name: ${pvc.name}
    csi.storage.k8s.io/node-publish-secret-namespace: ${pvc.namespace}
    csi.storage.k8s.io/node-stage-secret-name: ${pvc.name}
    csi.storage.k8s.io/node-stage-secret-namespace: ${pvc.namespace}
    csi.storage.k8s.io/node-expand-secret-name: ${pvc.name}
    csi.storage.k8s.io/node-expand-secret-namespace: ${pvc.namespace}
  ```

# Secret access for encrypted volumes

Longhorn assigns the CSI controller sidecars a dedicated service account without permission to read Kubernetes Secrets. This behavior is unconditional; there is no Helm value to enable controller-side Secret access. Any additional Secret grants created by an administrator are not removed automatically; remove them separately if they exist, but do not use controller-side Secret access for Longhorn encryption.

For Longhorn StorageClasses, follow these parameter rules:

- **Do configure:** Only the node-stage, node-publish, and node-expand Secret parameters shown above.
- **Do not configure:** `csi.storage.k8s.io/provisioner-secret-*`, `csi.storage.k8s.io/controller-publish-secret-*`, or `csi.storage.k8s.io/controller-expand-secret-*` pairs.
- **Do not set:** Generic `csi.storage.k8s.io/secret-name` or `csi.storage.k8s.io/secret-namespace` defaults for Longhorn.

At staging, restaging, and expansion, the kubelet fetches the Secret referenced by the node-side parameters and supplies the encryption key to the Longhorn node service. If the key is missing or cannot be read, workload staging, restaging, or expansion fails; PVC provisioning does not require the controller to read the key.

# Using an Encrypted Volume

To create an encrypted volume, you must create a PVC using a StorageClass that has been configured for encryption. The above StorageClass examples can be used as a starting point.

The encryption Secret is not required for controller-side PVC provisioning. When a workload uses the volume, the kubelet fetches the node-side Secret references and supplies the key during staging and publishing. A missing or inaccessible key prevents the workload from staging or restaging the volume. The node-expand Secret is also required for online filesystem expansion.

# Filesystem Expansion

Longhorn supports [both online and offline expansion](../../../nodes-and-volumes/volumes/expansion/#encrypted-volume) for encrypted volumes.

StorageClass parameters are needed to enable online expansion:

- `csi.storage.k8s.io/node-expand-secret-name`
- `csi.storage.k8s.io/node-expand-secret-namespace`

> **Notice**  
> - Longhorn v1.8.0 does not support expansion of V2 volumes.


# History

- Encryption of volumes in `Filesystem` mode available starting v1.2.0 ([#1859](https://github.com/longhorn/longhorn/issues/1859))
- Encryption of volumes in `Block` mode available starting v1.6.0 ([#4883](https://github.com/longhorn/longhorn/issues/4883))
