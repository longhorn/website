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

**References**:

- [Longhorn Installation Requirements](https://longhorn.io/docs/1.11.0/deploy/install/#installation-requirements)

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

**References**:

- [Longhorn Volume Encryption Documentation](https://longhorn.io/docs/1.11.0/advanced-resources/security/volume-encryption/)

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

- **Common Name**: `longhorn-backend`
- **Required SANs**: `longhorn-backend`, `longhorn-backend.longhorn-system`, `longhorn-backend.longhorn-system.svc`, `longhorn-frontend`, `longhorn-frontend.longhorn-system`, `longhorn-frontend.longhorn-system.svc`, `longhorn-engine-manager`, `longhorn-engine-manager.longhorn-system`, `longhorn-engine-manager.longhorn-system.svc`, `longhorn-replica-manager`, `longhorn-replica-manager.longhorn-system`, `longhorn-replica-manager.longhorn-system.svc`, `longhorn-csi`, `longhorn-csi.longhorn-system`, `longhorn-csi.longhorn-system.svc`, `IP Address:127.0.0.1`

**2. Create the Kubernetes Secret**: Deploy the certificates into the `longhorn-system` namespace.

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: longhorn-grpc-tls
  namespace: longhorn-system
type: kubernetes.io/tls
data:
  ca.crt: <BASE64_ENCODED_CA_CERT>
  tls.crt: <BASE64_ENCODED_CHILD_CERT>
  tls.key: <BASE64_ENCODED_PRIVATE_KEY>
```

- **Why this is necessary**: Longhorn components are hardcoded to look for an optional secret mount named `longhorn-grpc-tls`. If this secret exists at startup, Longhorn automatically switches the gRPC server and clients from plaintext to TLS mode. Using a private CA ensures that only components issued certificates by you can join the storage cluster.

**3. Restart Longhorn Components**: If Longhorn is already running, you must restart the manager and instance managers to pick up the certificates.

```bash
kubectl rollout restart deployment longhorn-manager -n longhorn-system
kubectl rollout restart daemonset longhorn-manager -n longhorn-system
```

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
