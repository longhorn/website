# Longhorn Hardening Guide

- [1. Infrastructure & Node Security](#1-infrastructure--node-security)
  - [1.1 RKE2/K3s CIS Profile Enforcement](#11-rke2k3s-cis-profile-enforcement)
  - [1.2 Host-Level Kernel Dependencies](#12-host-level-kernel-dependencies)
- [2. Storage & Data Integrity](#2-storage--data-integrity)
  - [2.1 Volume Encryption (LUKS)](#21-volume-encryption-luks)
  - [2.2 Snapshot Data Integrity](#22-snapshot-data-integrity)
- [3. Network & Access Control](#3-network--access-control)
  - [3.1 Network Policy Enforcement](#31-network-policy-enforcement)
  - [3.2 Storage Network Isolation](#32-storage-network-isolation)
  - [3.3 Control Plane and Data Plane mTLS](#33-control-plane-and-data-plane-mtls)

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

**References**:

- [Longhorn Installation Requirements](https://longhorn.io/docs/1.11.0/deploy/install/#installation-requirements)
- [Longhorn V2 Data Engine Prerequisites](https://longhorn.io/docs/1.11.0/v2-data-engine/prerequisites/)

#### Security Recommendation

Ensure that required kernel modules for both V1 and V2 engines are installed installed, loaded, and restricted to privileged execution on the host. For V2 stability, ensure nodes run Linux Kernel 5.19 or later (6.7+ recommended) to prevent unexpected reboots and memory corruption associated with NVMe-TCP. You can check the references mentioned above for the latest Longhorn requirements.

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

This section ensures the **confidentiality** of data at rest through encryption and maintains **integrity** by detecting silent data corruption.

### 2.1 Volume Encryption (LUKS)

#### Overview

Volume encryption ensures **data confidentiality** at rest. By using `dm_crypt` (LUKS), Longhorn protects sensitive information from being accessed if physical disks are stolen or if the underlying host nodes are compromised.

While encryption does not prevent data from being deleted or corrupted (integrity), it ensures that the data remains unreadable to unauthorized parties who do not possess the required Kubernetes Secret.

**References**:

- [Longhorn Volume Encryption Documentation](https://longhorn.io/docs/1.11.0/advanced-resources/security/volume-encryption/)

#### Security Recommendation

Enable Longhorn volume encryption using LUKS and store encryption keys in Kubernetes Secrets scoped to the `longhorn-system` namespace to maintain data confidentiality.

#### Configuration

1. Create the encryption secret:

      ```bash
      kubectl create secret generic longhorn-crypto \
        --from-literal=CRYPTO_KEY_VALUE="<PROVISION_KEY>" \
        --from-literal=CRYPTO_KEY_PROVIDER="secret" \
        --namespace longhorn-system
      ```

    - **Why this is necessary**: Storing the key in a Kubernetes Secret allows Longhorn to programmatically provide the decryption key to `dm_crypt` during volume attachment without requiring manual operator intervention.

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

    - **Why this is necessary**: The StorageClass parameters instruct the Longhorn CSI driver to initialize a LUKS header on the block device before the first use, ensuring that every byte written to the disk is encrypted.

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

**References**:

- [Longhorn Snapshots and Backups Documentation](https://longhorn.io/docs/1.11.0/snapshots-and-backups/setup-a-snapshot/)

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

**References**:

- [Longhorn Networking Documentation](https://longhorn.io/docs/1.11.0/references/networking/)
- [Kubernetes Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/)

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

**References**:

- [Longhorn Storage Network Documentation](https://longhorn.io/docs/1.11.0/advanced-resources/deploy/storage-network/)

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

### 3.3 Control Plane and Data Plane mTLS

#### Overview

By default, communication between the Longhorn control plane (`longhorn-manager`) and the data plane (`instance-manager`) is unencrypted. Implementing Mutual TLS (mTLS) ensures that all gRPC traffic is encrypted and that both parties authenticate each other using a trusted Certificate Authority (CA).

This prevents "man-in-the-middle" attacks and unauthorized command injection within the storage network. Longhorn uses a Kubernetes Secret-based mechanism to distribute these certificates.

**References**:

- [Longhorn mTLS Support Documentation](https://longhorn.io/docs/1.11.0/advanced-resources/security/mtls-support/)
- [Kubernetes TLS Secrets](https://kubernetes.io/docs/reference/kubectl/generated/kubectl_create/kubectl_create_secret_tls/)

#### Security Recommendation

Enable mTLS for all gRPC communication. Generate a dedicated CA to sign certificates for the `longhorn-backend` and deploy them as a Kubernetes Secret named `longhorn-grpc-tls` before deploying or restarting Longhorn components.

#### Configuration

**1. Generate Certificates**: You must generate a CA certificate and a server/client certificate. The `tls.crt` **must** include specific Subject Alternative Names (SANs) to be valid for Longhorn's internal service discovery.

**2. Create the Kubernetes Secret**: Deploy the certificates into the `longhorn-system` namespace.

**3. Restart Longhorn Components**: If Longhorn is already running, you must restart the manager and instance managers to pick up the certificates.

For detailed steps on generating the certificates and creating the secret, refer to the [Longhorn mTLS Support Documentation](https://longhorn.io/docs/1.11.0/advanced-resources/security/mtls-support/).

#### Verification

Check the logs of a `longhorn-manager` pod to confirm TLS is active:

```bash
kubectl logs -n longhorn-system -l app=longhorn-manager | grep -i "TLS"
```

**Pass**: Logs indicate that gRPC services are starting with TLS enabled and the secret is successfully mounted.

#### Impact / Notes

- **Mixed Mode**: The `longhorn-manager` has a non-TLS fallback to allow communication with older `instance-managers` during a rolling upgrade, but for full hardening, all components must be restarted.
- **Certificate Expiry**: You must monitor the expiration of these certificates. If the CA or TLS certificates expire, the control plane will lose the ability to manage volumes.
- **Pre-deployment**: It is highly recommended to create the secret **before** installing Longhorn to ensure a secure-from-start deployment.
