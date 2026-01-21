# Longhorn Hardening Guide

This guide provides security controls and remediation steps for hardening a standalone Longhorn storage system on RKE2/K3s. It prioritizes findings from Longhorn hardened cluster logs to address compliance failures in restricted environments.

## 1. Infrastructure & Node Security

This section hardens the underlying Kubernetes nodes to ensure they meet CIS benchmark requirements and provide a stable, secure foundation for Longhorn storage operations.

### 1.1 RKE2/K3s CIS Profile Enforcement

#### Overview

The Center for Internet Security (CIS) Kubernetes Benchmark is an industry-standard set of best practices for securely configuring Kubernetes clusters. Implementing these benchmarks is critical because they provide a prescriptive roadmap for reducing the attack surface of the control plane and worker nodes, ensuring that default settings which often prioritize ease of use over security are hardened against exploitation.

This control (a specific security technical safeguard) ensures that the Kubernetes distribution (RKE2 or K3s) is running with a CIS benchmark profile and that kernel defaults are protected from runtime modification. These settings enforce hardened defaults for kubelet, kube-apiserver, and host kernel behavior.

For Longhorn, compliance with CIS profiles is especially important because its storage components operate close to the host kernel, block devices, and networking stack. Inconsistent or weakened kernel settings can directly impact I/O behavior, isolation guarantees, and network reliability, increasing the risk of data corruption, performance degradation, or node instability.

**References**:

- [CIS Kubernetes Benchmark](https://www.cisecurity.org/benchmark/kubernetes)
- [RKE2 CIS Hardening Guide](https://docs.rke2.io/security/hardening_guide)
- [K3s CIS Hardening Self-Assessment](https://docs.k3s.io/security/self-assessment)
- [Rancher Security Hardening Guides and Benchmark Versions](https://ranchermanager.docs.rancher.com/reference-guides/rancher-security#hardening-guides-and-benchmark-versions)

#### Security Recommendation

Run RKE2/K3s with a CIS profile enabled and enforce kernel defaults using `protect-kernel-defaults`. Configure kernel panic behavior to fail fast during unrecoverable errors.

#### Configuration

1. Create or update `/etc/rancher/rke2/config.yaml` on **all nodes**:

    ```yaml
    profile: "cis"
    # For specific CIS versions 1.24 and older, use profile: "cis-1.23"
    protect-kernel-defaults: true
    ```

    - **Why this is necessary**: The `profile` flag automates the application of CIS-compliant configurations to the kubelet and API server. The `protect-kernel-defaults: true` setting is a security safeguard that prevents the Kubernetes service from starting if the host's kernel parameters differ from the hardened requirements, ensuring a "secure-by-default" boot sequence.

2. Apply the required kernel parameters as defined in the RKE2 hardening guidance:

    ```bash
    cat << EOF > /etc/sysctl.d/60-rke2-cis.conf
    vm.panic_on_oom=0
    vm.overcommit_memory=1
    kernel.panic=10
    kernel.panic_on_oops=1
    EOF

    systemctl restart systemd-sysctl
    ```

    - **Why this is necessary**:
      - **Memory Management (`vm.*`)**: Settings like `vm.overcommit_memory=1` provide more predictable memory allocation, reducing the risk of the Out-Of-Memory (OOM) killer terminating critical Longhorn replica processes.
      - **Panic Behavior (`kernel.panic*`)**: Forcing a reboot on "oops" or panics ensures that a compromised or unstable node does not continue to send faulty storage heartbeats or corrupted data blocks to the rest of the Longhorn cluster.

3. Restart the RKE2 service on each node.
    - **Why this is necessary**: Kubernetes components only read their configuration files during the initialization phase. A restart is required to transition the cluster from a "standard" state to a "hardened" state.

#### Verification

Verify that the RKE2 configuration uses the CIS profile and checks kernel parameters:

```bash
grep "profile: cis" /etc/rancher/rke2/config.yaml
```

**Pass**: Output includes `profile: "cis-1.23"` (or another compliant CIS version) and `protect-kernel-defaults: true`.

#### Impact / Notes

- Enabling CIS profiles may restrict pod capabilities, hostPath usage, and sysctl overrides.
- Kernel panic settings favor data integrity over availability by rebooting nodes during fatal kernel errors.
- All nodes must be configured consistently.

### 1.2 Host-Level Kernel Dependencies

#### Overview

Longhorn requires specific kernel modules and host utilities to attach, encrypt, and manage block devices. In CIS-hardened environments, these dependencies are not guaranteed to be present or loaded by default.

Failure to load these modules results in Longhorn volume attachment failures and node-level errors.

#### Security Recommendation

Ensure that required kernel modules (`iscsi_tcp`, `dm_crypt`) and supporting packages are installed, loaded, and restricted to privileged execution on the host.

#### Configuration

1. Install required packages and enable the iSCSI daemon:

      ```bash
      # SUSE / openSUSE
      zypper install -y open-iscsi cryptsetup device-mapper
      systemctl enable --now iscsid
      ```

2. Load the required kernel modules:

      ```bash
      modprobe iscsi_tcp dm_crypt
      ```

#### Verification

Run the Longhorn preflight check:

```bash
longhornctl check preflight
```

**Pass**: Output includes:

- `Successfully probed module iscsi_tcp`
- `Successfully probed module dm_crypt`

#### Impact / Notes

- These modules must be present on **every node** that can host Longhorn replicas.
- Module loading requires root privileges and must comply with node hardening policies.

## 2. Storage & Data Integrity

This section secures data at rest and ensures Longhorn components operate correctly under filesystem and permission constraints imposed by CIS benchmarks.

### 2.1 Volume Encryption (LUKS)

#### Overview

Volume encryption protects data at rest if physical disks or nodes are compromised. Longhorn implements encryption using `dm_crypt` (LUKS) on the host and manages keys through Kubernetes Secrets.

#### Security Recommendation

Enable Longhorn volume encryption using LUKS and store encryption keys in Kubernetes Secrets scoped to the `longhorn-system` namespace.

#### Configuration

1. Create the encryption secret:

      ```bash
      kubectl create secret generic longhorn-crypto \
        --from-literal=CRYPTO_KEY_VALUE="<PROVISION_KEY>" \
        --from-literal=CRYPTO_KEY_PROVIDER="secret" \
        --namespace longhorn-system
      ```

2. Define the encrypted StorageClass:

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

#### Verification

```bash
kubectl get storageclass longhorn-crypto -o yaml
```

**Pass**: Output includes `encrypted: "true"`.

#### Impact / Notes

- Encryption introduces minor CPU overhead during I/O operations.
- Encryption keys must be backed up securely; loss of keys results in permanent data loss.

### 2.2 Snapshot Data Integrity

#### Overview

Snapshot data integrity checks detect silent data corruption (bit rot) that may not be visible to the filesystem. Longhorn can hash snapshot files to detect unexpected changes.

#### Security Recommendation

Enable snapshot data integrity checks using `fast-check` mode to balance performance and protection.

#### Configuration

```bash
kubectl -n longhorn-system patch setting snapshot-data-integrity \
  --type=merge -p '{"value": "fast-check"}'
```

#### Verification

```bash
kubectl -n longhorn-system get setting snapshot-data-integrity
```

**Pass**: Value is `fast-check` or `enabled`.

#### Impact / Notes

- `fast-check` hashes snapshots only when metadata changes are detected.
- Full integrity checking increases I/O overhead.

## 3. Network & Access Control

This section restricts network communication to reduce lateral movement and isolate storage traffic.

### 3.1 Network Policy Enforcement

#### Overview

In default-deny network environments, Longhorn components require explicit NetworkPolicies to communicate with each other and with backup targets.

#### Security Recommendation

Apply explicit ingress and egress NetworkPolicies to the `longhorn-system` namespace to allow only required traffic.

#### Configuration

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
  egress:
  - to:
    - ipBlock:
        cidr: <BACKUP_TARGET_IP>/32
    ports:
    - port: 2049
      protocol: TCP
```

#### Verification

```bash
kubectl -n longhorn-system get networkpolicies
```

**Pass**: Policies exist and allow Longhorn internal and backup traffic.

#### Impact / Notes

- Incorrect policies will break backups and replica communication.
- NFS, S3, or MinIO ports must be explicitly allowed.

### 3.2 Storage Network Isolation

#### Overview

Storage replication traffic can be isolated to a dedicated network interface to reduce attack surface and prevent interference with control plane traffic.

#### Security Recommendation

Configure Longhorn to use a dedicated storage network via Multus.

#### Configuration

1. Ensure a `NetworkAttachmentDefinition` exists.
2. Apply the Longhorn setting:

      ```bash
      kubectl -n longhorn-system patch setting storage-network \
        --type=merge -p '{"value": "kube-system/storage-net"}'
      ```

#### Verification

```bash
kubectl -n longhorn-system get setting storage-network
```

**Pass**: Value references a valid Multus network.

#### Impact / Notes

- Instance Manager pods will restart when this setting changes.
- Network misconfiguration may prevent replica synchronization.
