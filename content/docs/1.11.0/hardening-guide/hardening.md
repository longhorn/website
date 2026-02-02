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

This guide provides security controls and remediation steps for hardening a stand-alone Longhorn storage system on RKE2/K3s. It prioritizes findings from Longhorn hardened cluster logs to address compliance failures in restricted environments.

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
- [K3s CIS Hardening Self-Assessment](https://docs.k3s.io/security/hardening-guide)
- [Rancher Security Hardening Guides and Benchmark Versions](https://ranchermanager.docs.rancher.com/reference-guides/rancher-security#hardening-guides-and-benchmark-versions)

#### Security Recommendation

Run RKE2/K3s with a CIS profile enabled and enforce kernel defaults using `protect-kernel-defaults`. Configure kernel panic behavior to fail fast during unrecoverable errors.

#### Configuration

1. Enable CIS enforcement in the distribution config.

    Create or update `/etc/rancher/rke2/config.yaml` on all nodes. For users running Kubernetes v1.29 and later, the `cis-1.11` profile is recommended:

    ```yaml
    profile: "cis"

    # Required for cis-1.11 only; not required for cis-1.9/cis-1.10
    kube-apiserver-arg:
      - 'service-account-extend-token-expiration=false'
    ```

    - **Why this is necessary**: 
      - The `profile: "cis" flag` automates the application of CIS-compliant configurations.
      - The `service-account-extend-token-expiration=false` argument is a mandatory requirement for the **CIS-1.11** profile to ensure service account tokens adhere to strict security lifecycles.
      - The `protect-kernel-defaults: true` setting prevents the Kubernetes service from starting if the host's kernel parameters differ from the hardened requirements, ensuring a "secure-by-default" boot sequence.

2. Apply the required kernel parameters.

    Apply the hardening parameters to the host system.

    > **Note on RKE2 Installation Paths**: If you installed RKE2 using the official script (`curl -sfL https://get.rke2.io | sh`), a preconfigured CIS sysctl file is available at `/opt/rke2/share/rke2/rke2-cis-sysctl.conf`. You can copy it directly:
    > ```bash
    > cp /opt/rke2/share/rke2/rke2-cis-sysctl.conf /etc/sysctl.d/60-rke2-cis.conf
    > ```

    Alternatively, you can create the file manually:

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

4. **Validation**: Validate that the RKE2 configuration uses the CIS profile and checks kernel parameters:

    ```bash
    grep "profile: cis" /etc/rancher/rke2/config.yaml
    ```

**Expected Result**: Output includes `profile: "cis-1.23"` (or another compliant CIS version) and `protect-kernel-defaults: true`.

#### Impact / Notes

- Enabling CIS profiles may restrict pod capabilities, hostPath usage, and sysctl overrides.
- Kernel panic settings favor data integrity over availability by rebooting nodes during fatal kernel errors.
- All nodes must be configured consistently.

### 1.2 Host-Level Kernel Dependencies

#### Overview

Longhorn requires specific kernel modules and host utilities to attach, encrypt and manage block devices. In CIS-hardened environments, these dependencies are not guaranteed to be present or loaded by default.

Failure to load these modules results in Longhorn volume attachment failures and node-level errors.

**References**:

- [Longhorn Installation Requirements](https://longhorn.io/docs/1.11.0/deploy/install/#installation-requirements)
- [Longhorn V2 Data Engine Prerequisites](https://longhorn.io/docs/1.11.0/v2-data-engine/prerequisites/)
- [Longhorn CLI (`longhornctl`)](https://longhorn.io/docs/1.11.0/advanced-resources/longhornctl/)

#### Security Recommendation

Ensure that required kernel modules for both V1 and V2 engines are installed installed, loaded and restricted to privileged execution on the host. For V2 stability, ensure nodes run Linux Kernel 5.19 or later (6.7+ recommended) to prevent unexpected reboots and memory corruption associated with NVMe-TCP. You can check the references mentioned above for the latest Longhorn requirements.

#### Configuration

The Longhorn CLI automates the environment setup, including the installation of `open-iscsi` and `cryptsetup`, and the loading of modules like `iscsi_tcp`, `dm_crypt`, and `nvme_tcp`. This tool ensures a "secure-by-default" configuration across all nodes with a single command.

1. **Setup and Verify**: Use the `install` command to apply dependencies and the `check` command to confirm the environment is ready.
    ```bash
    # Install dependencies (Add --enable-spdk for V2 Data Engine)
    longhornctl install preflight

    # Validate the environment
    longhornctl check preflight
    ```

2. **V2 Memory Requirements**: If using the V2 Data Engine, 2 MiB-sized Huge Pages must be manually allocated (for example, `echo 1024 > /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages`) to allow SPDK to perform high-speed polling.

**Expected Result**: A successful `longhornctl check` returns an `info` status for all required services and modules, signaling that the node is ready to host Longhorn replicas. On immutable systems like **SLE Micro**, a reboot may be necessary to finalize the installation.

## 2. Storage & Data Integrity

This section ensures the **confidentiality** of data at rest through encryption and maintains **security** by detecting silent data corruption.

### 2.1 Volume Encryption (LUKS)

#### Overview

Volume encryption ensures data confidentiality at rest by utilizing the Linux kernel's `dm_crypt` module and LUKS (Linux Unified Key Setup). This protection ensures that even if physical storage media is compromised or a node is accessed by an unauthorized user, the data remains unreadable.

Longhorn supports encryption for both `Filesystem` and `Block` modes. Critically, encryption is maintained throughout the data lifecycle: any backups created from encrypted volumes inherit the same level of protection.

**References**:

- [Longhorn Volume Encryption Documentation](https://longhorn.io/docs/1.11.0/advanced-resources/security/volume-encryption/)
- [Kubernetes StorageClass Secrets Guide](https://kubernetes-csi.github.io/docs/secrets-and-credentials-storage-class.html)

#### Security Recommendation

Enforce encryption for all sensitive workloads by defining a `StorageClass` that references a Kubernetes Secret. This secret should ideally be restricted to the `longhorn-system` namespace. For multi-tenant environments, consider using per-volume secrets to isolate encryption keys between different namespaces.

#### Configuration

The Longhorn CSI driver handles the heavy lifting of volume encryption by resolving secret templates during volume provisioning.

- **Secret Configuration**: Encryption keys are stored in a Kubernetes Secret. While the mandatory parameter is `CRYPTO_KEY_VALUE`, you can further harden the security posture by specifying high-entropy algorithms via `CRYPTO_KEY_CIPHER` (default: `aes-xts-plain64`) and `CRYPTO_PBKDF` (default: `argon2i`).
- **StorageClass Integration**: To enable encryption, the `StorageClass` must include the `encrypted: "true"` parameter. You must also map the Secret to the CSI sidecars (provisioner, node-publish, node-stage, and node-expand) to ensure the volume can be created, mounted, and resized securely.
- **Key Isolation Options**:
- **Global Secret**: Best for single-tenant clusters where one master key manages all volumes.
- **Per-Volume Secret**: Recommended for hardened environments; it uses template parameters like `${pvc.name}` and `${pvc.namespace}` to ensure each volume has a unique key, preventing a single compromised key from exposing the entire storage pool.

**Expected Result**: A successfully configured environment results in a `StorageClass` that automatically provisions LUKS-encrypted block devices. You can verify this by checking the `StorageClass` metadata for the `encrypted: "true"` flag. 

> **Note**: PVCs remain in a `Pending` state until their associated encryption secrets are available.

### 2.2 Snapshot Data Integrity

#### Overview

Snapshot data integrity checks are designed to detect "bit rot" or silent data corruption that occurs at the physical storage level and remains invisible to the file system. Longhorn maintains the integrity of your data by generating and verifying hashes for snapshot disk files, ensuring that the data recovered from a snapshot is identical to the data originally written.

**References**:

- [Longhorn Snapshots and Backups Documentation](https://longhorn.io/docs/1.11.0/snapshots-and-backups/setup-a-snapshot/)
- [Longhorn Snapshot Data Integrity Check](https://longhorn.io/docs/1.11.0/advanced-resources/data-integrity/snapshot-data-integrity-check/)

#### Security Recommendation

Enable the `snapshot-data-integrity` global setting to enforce automated verification of snapshot files. For a balance of performance and security, the `fast-check` mode is recommended, as it validates integrity only when metadata changes are detected.

#### Configuration

The hashing mechanism can be enabled globally using a `kubectl patch` command. This ensures that every volume in the cluster—whether managed via the UI or Custom Resources (CRs)—adheres to the same integrity standards.

1. **Apply the Setting**:
    ```bash
    kubectl -n longhorn-system patch setting snapshot-data-integrity \
      --type=merge -p '{"value": "fast-check"}'
    ```

    - **Why this is necessary**: In hardened environments, ensuring data has not been tampered with or corrupted is as critical as preventing unauthorized access. This setting provides an automated "Proof of Integrity" for your historical data states.

2. **Performance Considerations**: While `enabled` mode performs a full hash of every snapshot (increasing I/O overhead), `fast-check` optimizes the process by checking the file's modification time and size before re-hashing, making it suitable for high-performance production environments.

**Expected Result**: The setting validation can be confirmed by running `kubectl -n longhorn-system get setting snapshot-data-integrity`. A value of `fast-check` indicates that the integrity engine is active and alert administrators if a snapshot fails its periodic hash validation.

## 3. Network & Access Control

This section restricts network communication to reduce lateral movement and isolate storage traffic.

### 3.1 Network Policy Enforcement

#### Overview

In "default-deny" security environments, Longhorn components require explicit authorization to communicate with the Kubernetes API, between the control and data planes, and with external backup targets. Manually managing these policies is complex due to the extensive port range (for example, `9500–9503` for Manager, `8500–8504` for Instance Manager, and `10000–30000` for replica traffic).

Restricting traffic to only known Longhorn components minimizes the "blast radius" if a malicious pod attempts lateral movement within the cluster.

**References**:

- [Longhorn Networking and Port Requirements](https://longhorn.io/docs/1.11.0/references/networking/)
- [Kubernetes Network Policies Guide](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
- [Longhorn Helm Chart NetworkPolicy Values](https://github.com/longhorn/longhorn/blob/master/chart/values.yaml)

#### Security Recommendation

Enable the built-in NetworkPolicies provided by the Longhorn Helm chart rather than maintaining manual manifests. This ensures that all required ports including gRPC, UI, CSI and Webhook traffic—are automatically whitelisted according to the current Longhorn version's specifications.

#### Configuration

The most secure and maintainable way to enforce network isolation is to toggle the built-in policy engine during installation or via Helm upgrade. This creates a set of policies that cover the entire Longhorn communication matrix (Manager, Instance Manager, Backing Image Manager, etc.).

1. **Enable Native Policies**: Set the `networkPolicies.enabled` value to `true` in your Helm `values.yaml` or via the command line:
    ```bash
    helm upgrade longhorn longhorn/longhorn \
      --namespace longhorn-system \
      --set networkPolicies.enabled=true \
      --set networkPolicies.type=k3s  # Set type based on your CNI (for example, k3s, rke2, cilium)
    ```

2. **Custom Backup Targets**: If using an external backupstore (NFS, S3, or MinIO), you must ensure your CNI allows egress traffic to those specific endpoints. Longhorn's built-in policies primarily focus on intra-cluster traffic; therefore, if your cluster has a global default-deny egress policy, you must manually add an egress rule for the `longhorn-manager` and `instance-manager` pods to reach your backup target IP and port (for example, `2049` for NFS or `443` for S3).

**Expected Result**: Running `kubectl get netpol -n longhorn-system` should show a suite of policies (for example, `longhorn-manager`, `longhorn-instance-manager`) that match the labels and ports defined in the official networking documentation.

### 3.2 Storage Network Isolation

#### Overview

By default, Longhorn uses the primary Kubernetes CNI network for all traffic. To enhance security and performance, Longhorn supports the isolation of in-cluster data traffic (replication and management) to a dedicated network interface. This segmentation prevents data-heavy replication traffic from interfering with the Kubernetes control plane and reduces the attack surface of the storage layer.

**References**:

- [Longhorn Storage Network Documentation](https://longhorn.io/docs/1.11.0/advanced-resources/deploy/storage-network/)
- [Multus CNI Documentation](https://github.com/k8snetworkplumbingwg/multus-cni)

#### Security Recommendation

Implement network segregation by configuring a dedicated storage network using a Multus `NetworkAttachmentDefinition`. This ensures that sensitive storage traffic is physically or logically separated from general application and management traffic.

#### Configuration

The storage network is configured by providing a Multus `NetworkAttachmentDefinition` in the `<NAMESPACE>/<NAME>` format to the Longhorn **Storage Network** setting.

- **Behavioral Change**: Applying this setting adds the `k8s.v1.cni.cncf.io/networks` annotation to Longhorn pods. This triggers an immediate recreation of all `instance-manager`, `backing-image-manager`, and `backing-image-data-source` pods.
- **Best Practice**: To ensure immediate and stable application of the setting, it is critical to stop all workloads and detach all volumes before configuration. If volumes remain attached, Longhorn delays the restart of the affected pods until the volumes are detached or the next synchronization cycle occurs (typically one hour).
- **V2 Engine & RWX Support**: This isolation also extends to the V2 Data Engine and Read-Write-Many (RWX) volumes via the **Endpoint Network For RWX Volume** setting, ensuring end-to-end network hardening for all volume types.

**Expected Result**: Once configured, data traffic is routed through the specified secondary interface. This can be verified by describing the `instance-manager` pods and confirming the presence of the Multus network annotation and the assigned secondary IP address.

### 3.3 Control Plane and Data Plane mTLS

#### Overview

By default, communication between the Longhorn control plane (`longhorn-manager`) and the data plane (`instance-manager`) is unencrypted. Implementing Mutual TLS (mTLS) ensures that all gRPC traffic is encrypted and that both parties authenticate each other using a trusted Certificate Authority (CA).

This prevents "man-in-the-middle" attacks and unauthorized command injection within the storage network. Longhorn uses a Kubernetes Secret-based mechanism to distribute these certificates.

**References**:

- [Longhorn mTLS Support Documentation](https://longhorn.io/docs/1.11.0/advanced-resources/security/mtls-support/)
- [Kubernetes TLS Secrets](https://kubernetes.io/docs/reference/kubectl/generated/kubectl_create/kubectl_create_secret_tls/)

#### Security Recommendation

Enable mTLS for all gRPC communication by deploying a Kubernetes Secret named `longhorn-grpc-tls` in the `longhorn-system` namespace. This should be performed before Longhorn installation to ensure a secure-from-start posture.

#### Configuration

Longhorn uses an optional secret mount mechanism. If the `longhorn-grpc-tls` secret is detected during component startup, the system automatically transitions from plaintext to encrypted gRPC.

- **Certificate Requirements**: You must generate a `ca.crt` (CA) to sign a `tls.crt` (certificate) and `tls.key` (private key). To pass Longhorn's internal service discovery validation, the certificate **must** include specific Subject Alternative Names (SANs) for all managers, including `longhorn-backend`, `longhorn-engine-manager`, `longhorn-replica-manager`, and `longhorn-csi`.
- **Deployment**: The certificates are stored as a `kubernetes.io/tls` type secret. When generating the base64 encoding for these secrets manually, ensure no trailing newlines are added, as this causes certificate loading failures.
- **Lifecycle Management**:
- **Mixed Mode**: The `longhorn-manager` includes a fallback mechanism to communicate with older, non-TLS instance managers during rolling upgrades.
- **Rotations**: Using a self-signed CA allows for the rotation of the `tls.crt` without service interruption, provided the CA remains valid.
- **Restarts**: If mTLS is enabled after installation, a full restart of all manager and instance-manager pods is required to mount the secret and activate encryption.

**Expected Result**: Successful activation can be confirmed by inspecting the `longhorn-manager` logs. The output indicates that gRPC services are initializing with TLS enabled and that the secret has been successfully mounted from the `longhorn-system` namespace.
