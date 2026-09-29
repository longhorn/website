---
title: Volume Encryption
weight: 2
---

Longhorn supports volume encryption in both `Filesystem` and `Block` modes. Backups created from encrypted volumes are also encrypted.

Volume encryption uses the Linux kernel module `dm_crypt`, the `cryptsetup` utility, and Kubernetes Secrets. `dm_crypt` and `cryptsetup` create and manage encrypted devices. A Secret stores the encryption key and the kubelet supplies that key to the Longhorn node component when the volume is staged, published, or expanded.

# Requirements

To use encrypted volumes, ensure that the `dm_crypt` kernel module is loaded and that `cryptsetup` is installed on every worker node that can run an encrypted volume.

# Setting up Kubernetes Secrets and StorageClasses

Longhorn uses Kubernetes Secrets for encryption keys. Kubernetes resolves StorageClass Secret parameters when it creates a PV. Configure the node-side Secret parameters on the StorageClass so the resulting PV contains the references needed by the kubelet.
Metadata-only updates to an existing StorageClass remain possible. StorageClass parameter changes require a same-name replacement because parameters are immutable.

In the following example, the encryption key is specified as string data in `CRYPTO_KEY_VALUE`. Using string data avoids Base64 encoding before submitting the Secret with kubectl.

Besides `CRYPTO_KEY_VALUE`, `CRYPTO_KEY_CIPHER`, `CRYPTO_KEY_HASH`, `CRYPTO_KEY_SIZE`, `CRYPTO_PBKDF`, `CRYPTO_PBKDF_FORCE_ITERATIONS`, and `CRYPTO_PBKDF_MEMORY` customize volume encryption.

- `CRYPTO_KEY_CIPHER`: Cipher specification. The default for LUKS is `aes-xts-plain64`.
- `CRYPTO_KEY_HASH`: Passphrase hash for `open`. The default is `sha256`.
- `CRYPTO_KEY_SIZE`: Key size in bits, as a multiple of 8. The default is `256`.
- `CRYPTO_PBKDF`: Password-Based Key Derivation Function for the LUKS keyslot. The default is `argon2i`.
- `CRYPTO_PBKDF_FORCE_ITERATIONS`: Fixed PBKDF iteration count. In FIPS mode, an explicit value such as `200000` helps meet PBKDF2 policy requirements. The Longhorn default is `200000`.
- `CRYPTO_PBKDF_MEMORY`: Memory cost in KB for memory-hard algorithms such as Argon2. The default is `0` and this parameter is ignored when PBKDF2 is used.

For more information, see [`cryptsetup(8)`](https://man7.org/linux/man-pages/man8/cryptsetup.8.html).

- Example of an encryption Secret:

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

- Example of a StorageClass with a global node-side Secret:

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
    csi.storage.k8s.io/node-publish-secret-name: "longhorn-crypto"
    csi.storage.k8s.io/node-publish-secret-namespace: "longhorn-system"
    csi.storage.k8s.io/node-stage-secret-name: "longhorn-crypto"
    csi.storage.k8s.io/node-stage-secret-namespace: "longhorn-system"
    csi.storage.k8s.io/node-expand-secret-name: "longhorn-crypto"
    csi.storage.k8s.io/node-expand-secret-namespace: "longhorn-system"
  ```

- Example of a StorageClass with a volume-specific node-side Secret:

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
    csi.storage.k8s.io/node-publish-secret-name: ${pvc.name}
    csi.storage.k8s.io/node-publish-secret-namespace: ${pvc.namespace}
    csi.storage.k8s.io/node-stage-secret-name: ${pvc.name}
    csi.storage.k8s.io/node-stage-secret-namespace: ${pvc.namespace}
    csi.storage.k8s.io/node-expand-secret-name: ${pvc.name}
    csi.storage.k8s.io/node-expand-secret-namespace: ${pvc.namespace}
  ```

Keep the original Secret and all node-side references when updating a StorageClass. Never include Secret values in a manifest export, support bundle, or issue report.

# Secret access for encrypted volumes

The CSI controller sidecars run with the dedicated `longhorn-csi-service-account`. The base `longhorn-csi-role` and `longhorn-csi-bind` remain Secret-free because the sidecars are separate from the Longhorn manager and node plugin.

The released Helm chart and static installation manifests grant this service account **cluster-wide `get` access to core Kubernetes Secrets by default** through `longhorn-csi-secret-role` and `longhorn-csi-secret-bind`. The ClusterRole contains only `get` on `secrets`, and the ClusterRoleBinding names exactly `longhorn-csi-service-account` in the Longhorn release namespace. This broad grant is intentional for CSI sidecar compatibility; review it against your cluster's Secret access policy. The grant is static and applies to fresh and upgraded installations regardless of StorageClass parameters.

The grant is installation-controlled, not startup-dynamic. `longhorn-driver-deployer` does not create or remove it based on StorageClass scans, and no deployer restart is needed when StorageClasses change. Deleting it is not automatically reversed by the deployer; only a later apply with the grant enabled can recreate it. Helm users who do not want controller-side Secret access must set `csi.allowControllerSecretAccess=false`; Helm then renders neither `longhorn-csi-secret-role` nor `longhorn-csi-secret-bind`. For a manifest installation, delete `longhorn-csi-secret-bind` and keep it out of every future apply; the now-unbound role may also be removed. If access is disabled, preserve existing node-side Secret references and encryption Secrets.

Before disabling access, clean historical provisioner-side Secret parameters from StorageClasses; otherwise new provisioning with those classes can fail. Review custom controller-side Secret requirements separately.

Administrators who choose to opt out can optionally use the [encrypted-volume Secret migration guide](/kb/how-to-migrate-encrypted-volumes-to-node-only-secrets) to remove historical `csi.storage.k8s.io/provisioner-secret-*` parameters from Longhorn StorageClasses. This is a StorageClass-only migration: parameters are immutable, so each class is recreated under the same name while preserving node-side Secret parameters, labels, annotations, default-class designation, and other fields. It does not require PV or PVC recreation, encryption-key changes, backup, detach, rebind, or PV replacement.

The migration is documented only for historical provisioner-only parameters. Do not assume that custom `controller-publish-secret-*`, `controller-expand-secret-*`, generic Secret parameters, deprecated parameter spellings, or other custom controller configurations become safe or preserve controller-side behavior after an SC-only cleanup. A best-effort Secret read during a later deletion may be logged as denied by the external-provisioner, but deletion continues; do not restore broad controller access or remove PV deletion annotations to suppress that message.

# Using an Encrypted Volume

Create a PVC using a StorageClass configured with `encrypted: "true"` and the required node-side Secret references. PVC provisioning can use the controller-side grant for CSI sidecar compatibility, while the kubelet fetches the node-side Secret and supplies the key during staging and publishing. A missing or inaccessible key prevents staging or restaging. The node-expand Secret is also required for online filesystem expansion.


# Filesystem Expansion

Longhorn supports [online and offline expansion](../../../nodes-and-volumes/volumes/expansion/#encrypted-volume) for encrypted volumes.

For online expansion, the external-resizer grows the Longhorn backend through `ControllerExpandVolume`; the controller operation does not consume the encryption key. The kubelet then fetches the Secret named by `csi.storage.k8s.io/node-expand-secret-name` and `csi.storage.k8s.io/node-expand-secret-namespace` for `NodeExpandVolume`, where Longhorn grows the encrypted device and filesystem. Preserve these node-side parameters. Removing a controller-expand reference is not a substitute for the required node-expand reference.

For offline expansion, the backend grows without the key. When the workload next stages the volume, the kubelet supplies the Secret referenced by the node-stage parameters and Longhorn opens the encrypted device and performs the required filesystem resize.

> **Notice**
> - Longhorn v1.8.0 does not support expansion of V2 volumes.

# History

- Encryption of volumes in `Filesystem` mode available starting v1.2.0 ([#1859](https://github.com/longhorn/longhorn/issues/1859))
- Encryption of volumes in `Block` mode available starting v1.6.0 ([#4883](https://github.com/longhorn/longhorn/issues/4883))
