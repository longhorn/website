# Longhorn Hardening Guide (v1.11)

This guide provides security controls and remediation steps for hardening a standalone Longhorn storage system on RKE2/K3s. It prioritizes findings from Longhorn hardened cluster logs to address compliance failures in restricted environments.

## 1. Infrastructure & Node Security

This section aligns the underlying Kubernetes nodes with CIS benchmarks and ensures secure kernel configurations for storage operations.

### 1.1 RKE2/K3s CIS Profile Enforcement

**Description**:

Configure the Kubernetes distribution to enforce Center for Internet Security (CIS) benchmarks by applying specific security profiles and kernel parameters.

**Discussion**:

RKE2 and K3s are hardened by default but require manual intervention to fully pass CIS controls. Hardened clusters restrict functionality, such as Pod Security Standards and kernel defaults. Specifically, RKE2 must be started with a CIS profile flag, and the host kernel must be configured to panic on specific errors to prevent data corruption during instability.

**Audit/Check**:

Verify the RKE2 configuration uses the CIS profile and checks kernel parameters:

```bash
grep "profile: cis" /etc/rancher/rke2/config.yaml
```

*Pass*: Output includes `profile: "cis-1.23"` (or compliant version) and `protect-kernel-defaults: true`.

**Remediation/Fix**:

1. Create or update `/etc/rancher/rke2/config.yaml` on all nodes:

    ```yaml
    profile: "cis-1.23"
    protect-kernel-defaults: true
    ```

2. Apply the required kernel parameters as defined in the RKE2 hardening guide:

    ```bash
    cat << EOF > /etc/sysctl.d/60-rke2-cis.conf
    vm.panic_on_oom=0
    vm.overcommit_memory=1
    kernel.panic=10
    kernel.panic_on_oops=1
    EOF
    systemctl restart systemd-sysctl
    ```

3. Restart the RKE2 service.

### 1.2 Host-Level Kernel Dependencies

**Description**:

Ensure required kernel modules (`dm_crypt`, `iscsi_tcp`) and tools are loaded and restricted to root/privileged execution.

**Discussion**:

Longhorn requires `iscsi_tcp` for volume attachment and `dm_crypt` for volume encryption. In hardened environments, verify these are loaded to prevent startup failures. The `longhornctl` tool validates these preflight requirements.

**Audit/Check**:

Run the Longhorn CLI preflight check:

```bash
longhornctl check preflight
```

*Pass*: Output confirms `Successfully probed module iscsi_tcp` and `Successfully probed module dm_crypt`.

**Remediation/Fix**:

Install required packages and enable the iSCSI daemon on the host:

```bash
# SUSE/OpenSUSE
zypper install -y open-iscsi cryptsetup device-mapper
systemctl enable --now iscsid
modprobe iscsi_tcp dm_crypt
```

## 2. Storage & Data Integrity

This section secures data at rest and ensures Longhorn components operate within filesystem constraints enforced by CIS benchmarks.

### 2.1 Backupstore Non-Root Filesystem Compliance

**Description**:

Configure backup targets to avoid restricted root directories (`/root`).

**Discussion**:

CIS-hardened clusters restrict access to the root filesystem. Automation logs indicate that default backupstore configurations targeting `/root` fail due to permission errors. Components must utilize non-root paths (for example, `/storage`) to function correctly in hardened environments.

**Audit/Check**:

Inspect backupstore deployment manifests for host paths mounting `/root`:

```bash
kubectl get deployment -n longhorn-system -o yaml | grep "path: /root"
```

*Pass*: No output returning `/root` mounts.

**Remediation/Fix**:

Refactor backupstore configurations to use compliant paths as validated in hardened cluster tests:

1. **MinIO Home:** Change from `/root` to `/storage`.
2. **Certificate Mounts:** Change from `/root/certs` to `/tmp/certs`.
3. **Server Flags:** Explicitly define cert paths using flags like `--certs-dir` rather than relying on defaults.

### 2.2 Volume Encryption (LUKS)

**Description**:

Encrypt data-at-rest using `dm_crypt` and Kubernetes Secrets.

**Discussion**:

Encryption protects volume data against unauthorized access if physical media is compromised. Longhorn utilizes `dm_crypt` and `cryptsetup` on the node. Encryption configuration is managed via StorageClass parameters referencing a Kubernetes Secret.

**Audit/Check**:

Verify the StorageClass includes encryption parameters:

```bash
kubectl get storageclass longhorn-crypto -o yaml
```

*Pass*: Output includes `encrypted: "true"`.

**Remediation/Fix**:

1. Create the secret in `longhorn-system`:
    ```bash
    kubectl create secret generic longhorn-crypto \
      --from-literal=CRYPTO_KEY_VALUE="<PROVISION_KEY>" \
      --from-literal=CRYPTO_KEY_PROVIDER="secret" \
      --namespace longhorn-system
    ```
    
2. Define the StorageClass:
    ```yaml
    kind: StorageClass
    apiVersion: storage.k8s.io/v1
    metadata:
      name: longhorn-crypto
    provisioner: driver.longhorn.io
    parameters:
      encrypted: "true"
      csi.storage.k8s.io/provisioner-secret-name: "longhorn-crypto"
      csi.storage.k8s.io/provisioner-secret-namespace: "longhorn-system"
      csi.storage.k8s.io/node-publish-secret-name: "longhorn-crypto"
      csi.storage.k8s.io/node-publish-secret-namespace: "longhorn-system"
    ```

### 2.3 Snapshot Data Integrity

**Description**:

Enable periodic hashing and integrity checks for snapshot disk files.

**Discussion**:

To detect filesystem-unaware corruption (bit rot), Longhorn can hash snapshot files. The `fast-check` mode minimizes performance impact by only hashing files if metadata changes are detected.

**Audit/Check**:

Check the global setting:

```bash
kubectl -n longhorn-system get setting snapshot-data-integrity
```

*Pass*: Value is `fast-check` or `enabled`.

**Remediation/Fix**:

Apply the setting via `kubectl`:

```bash
kubectl -n longhorn-system patch setting snapshot-data-integrity \
  --type=merge -p '{"value": "fast-check"}'
```

## 3. Network & Access Control

This section isolates storage traffic and enforces strict network policies to prevent unauthorized lateral movement.

### 3.1 Network Policy Enforcement

**Description**:

Isolate Longhorn namespace traffic using explicit Allow lists.

**Discussion**:

Hardened environments often operate under a "Default Deny" policy. Logs from hardened cluster testing confirm that explicit policies are required for backupstores and Longhorn components to communicate. Without these policies, operations like backups will fail due to dropped packets.

**Audit/Check**:

Verify active NetworkPolicies in the namespace:

```bash
kubectl -n longhorn-system get networkpolicies
```

*Pass*: Policies allow traffic for `longhorn-manager`, `instance-manager`, and backup targets (for example, MinIO/NFS).

**Remediation/Fix**:

Apply a NetworkPolicy that explicitly allows Longhorn internal traffic and backup target access. Ensure NFS ports are defined if using NFS backupstores.

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: longhorn-backupstore-allow
  namespace: longhorn-system
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: longhorn-manager
    ports:
    - port: 9500
      protocol: TCP
  # Add egress rules for Backup Target (for example, NFS port 2049)
  egress:
  - to:
    - ipBlock:
        cidr: <BACKUP_TARGET_IP>/32
    ports:
    - port: 2049
      protocol: TCP
```

### 3.2 Storage Network Isolation

**Description**:

Segregate storage replication traffic to a dedicated interface.

**Discussion**:

Isolating storage traffic prevents interference with control plane traffic and enhances security by restricting data replication to a specific network. This is configured via the `Storage Network` setting using a Multus NetworkAttachmentDefinition.

**Audit/Check**:

Verify the storage network setting:

```bash
kubectl -n longhorn-system get setting storage-network
```

*Pass*: Value is set to a valid Multus definition (for example, `kube-system/storage-net`).

**Remediation/Fix**:

1. Ensure a NetworkAttachmentDefinition exists in the target namespace.
2. Update the Longhorn setting:
    ```bash
    kubectl -n longhorn-system patch setting storage-network \
      --type=merge -p '{"value": "kube-system/storage-net"}'
    ```
    *Note*: This will restart Instance Manager pods.
