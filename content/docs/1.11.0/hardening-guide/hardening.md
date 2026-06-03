# Longhorn Hardening Guide

- [1. Infrastructure & Node Security](#1-infrastructure--node-security)
  - [1.1 RKE2/K3s CIS Profile Enforcement](#11-rke2k3s-cis-profile-enforcement)
  - [1.2 Host-Level Kernel Dependencies](#12-host-level-kernel-dependencies)
- [2. Data Security (Confidentiality)](#2-data-security-confidentiality)
  - [2.1 Volume Encryption (LUKS)](#21-volume-encryption-luks)
- [3. Data Integrity](#3-data-integrity)
  - [3.1 Snapshot Data Integrity](#31-snapshot-data-integrity)
- [4. Network & Access Control](#4-network--access-control)
  - [4.1 Namespace Traffic Isolation (Network Policies)](#41-namespace-traffic-isolation-network-policies)
  - [4.2 Storage Network Isolation](#42-storage-network-isolation)
  - [4.3 Control Plane and Data Plane mTLS](#43-control-plane-and-data-plane-mtls)

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

**Expected Result**: Output includes `profile: "cis"` (or another compliant CIS version) and `protect-kernel-defaults: true`.

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

Ensure that required kernel modules for both V1 and V2 engines are installed installed, loaded and restricted to privileged execution on the host. For V2 Data Engine (Technical Preview) stability, ensure nodes run Linux Kernel 5.19 or later (6.7+ recommended) to prevent unexpected reboots and memory corruption associated with NVMe-TCP. You can check the references mentioned above for the latest Longhorn requirements.

#### Configuration

The Longhorn CLI automates the environment setup, including the installation of `open-iscsi` and `cryptsetup`, and the loading of modules like `iscsi_tcp`, `dm_crypt`, and `nvme_tcp`. This tool ensures a "secure-by-default" configuration across all nodes with a single command.

1. **Setup and Verify**: Use the `install` command to apply dependencies and the `check` command to confirm the environment is ready.
    ```bash
    # Install dependencies (Add --enable-spdk for V2 Data Engine)
    longhornctl install preflight

    # Validate the environment
    longhornctl check preflight
    ```

2. **V2 Memory Requirements**: If using the V2 Data Engine, 2 MiB-sized Huge Pages must be manually allocated (for example, `echo 1024 > /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages`) to allow SPDK to perform high-speed polling. Refer to the [V2 Quick Start Guide](https://longhorn.io/docs/1.11.0/v2-data-engine/quick-start/) for permanent configuration steps.

**Expected Result**: A successful `longhornctl check` returns an `info` status for all required services and modules. On immutable systems like **SLE Micro**, a reboot may be necessary to finalize the installation.

## 2. Data Security (Confidentiality)

This section ensures the **confidentiality** of data at rest through encryption and maintains **security** by detecting silent data corruption.

### 2.1 Volume Encryption (LUKS)

#### Overview

Volume encryption ensures data confidentiality at rest by utilizing the Linux kernel's `dm_crypt` module and LUKS (Linux Unified Key Setup). This protection ensures that even if physical storage media is compromised or a node is accessed by an unauthorized user, the data remains unreadable.

Longhorn supports encryption for both `Filesystem` and `Block` modes. Critically, encryption is maintained throughout the data lifecycle: any backups created from encrypted volumes inherit the same level of protection.

**References**:

- [Longhorn Volume Encryption Documentation](https://longhorn.io/docs/1.11.0/advanced-resources/security/volume-encryption/)
- [Kubernetes StorageClass Secrets Guide](https://kubernetes-csi.github.io/docs/secrets-and-credentials-storage-class.html)

#### Security Recommendation

Enforce encryption for all sensitive workloads by defining a `StorageClass` that references a Kubernetes Secret. This secret should ideally be restricted to the `longhorn-system` namespace. To minimize the "blast radius" in multi-tenant environments, utilize per-volume secrets to ensure each volume has a unique encryption key.

#### Configuration

The Longhorn CSI driver handles volume encryption by resolving secret templates during volume provisioning. Configuration focuses on two main components:

1. **Secret Management**: Longhorn utilizes Kubernetes Secrets to store encryption passphrases. While `CRYPTO_KEY_VALUE` is mandatory, advanced security postures can be achieved by defining custom algorithms like `argon2i` for PBKDF or `aes-xts-plain64` for ciphers.
    - *Implementation detail*: Refer to the [Secret Configuration Example](https://longhorn.io/docs/1.11.0/advanced-resources/security/volume-encryption/#setting-up-kubernetes-secrets-and-storageclasses) for formatting.


2. **StorageClass Orchestration**: To enable encryption, the `StorageClass` must include the `encrypted: "true"` parameter.
    - **Global Secret**: Simplifies management by using one master key for all volumes.
    - **Per-Volume Secret**: Enhances hardening by using template parameters (for example, `${pvc.name}`) to isolate keys between workloads.
    - *Implementation detail*: Detailed parameters for both modes are available in the [StorageClass Examples](https://longhorn.io/docs/1.11.0/advanced-resources/security/volume-encryption/#setting-up-kubernetes-secrets-and-storageclasses).

**Expected State**: Once configured, a `StorageClass` with the `encrypted: "true"` flag automatically provision LUKS-encrypted block devices. PVCs remain in a `Pending` state until their associated encryption secrets are created and accessible to the CSI sidecars.

## 3. Data Integrity

This section focuses on maintaining the correctness of data by detecting and repairing silent data corruption.

### 3.1 Snapshot Data Integrity

#### Overview

Snapshot data integrity checks are designed to detect "bit rot" or silent data corruption that occurs at the physical storage level and remains invisible to the file system. Longhorn maintains the integrity of your data by generating and verifying hashes for snapshot disk files, ensuring that the data recovered from a snapshot is identical to the state originally captured.

**References**:

- [Longhorn Snapshots and Backups Documentation](https://longhorn.io/docs/1.11.0/snapshots-and-backups/setup-a-snapshot/)
- [Longhorn Snapshot Data Integrity Check](https://longhorn.io/docs/1.11.0/advanced-resources/data-integrity/snapshot-data-integrity-check/)

#### Security Recommendation

Enable the `snapshot-data-integrity` global setting to enforce automated verification. In hardened environments, ensuring data has not been tampered with or corrupted is as critical as preventing unauthorized access. For a balance of performance and protection, use `fast-check` mode to minimize I/O overhead while ensuring metadata-consistent integrity.

#### Configuration

The integrity engine can be configured globally or on a per-volume basis. Enabling this feature allows Longhorn to automatically detect corrupted replicas and initiate the rebuilding process to restore data consistency.

1. **Global Enforcement**: Use the Longhorn settings to enable hashing across the cluster.
    - *Implementation detail*: Refer to the [Snapshot Data Integrity Settings](https://longhorn.io/docs/1.11.0/advanced-resources/data-integrity/snapshot-data-integrity-check/#settings) for available modes (for example, `fast-check`, `enabled`).

2. **Scheduling and Performance**: Hashing disk files consumes storage and computation resources. It is recommended to:
    -  Use `snapshot-data-integrity-cronjob` to schedule checks during off-peak hours.
    - Disable `snapshot-data-integrity-immediate-check-after-snapshot-creation` to minimize immediate I/O impact.
    - *Technical context*: Detailed [Performance Benchmarks](https://longhorn.io/docs/1.11.0/advanced-resources/data-integrity/snapshot-data-integrity-check/#performance-impact) are available in the official documentation.

**Expected State**: When enabled, the global `snapshot-data-integrity` setting is reflected in the cluster configuration. A successful implementation ensures that any snapshot disk file corruption is identified through periodic hash validation, signaling the system to repair affected replicas.

## 4. Network & Access Control

This section restricts network communication to reduce lateral movement and isolate storage traffic.

### 4.1 Namespace Traffic Isolation (Network Policies)

#### Overview

In "default-deny" security environments, Longhorn components require explicit authorization to communicate with the Kubernetes API, between the control and data planes, and with external backup targets. Manually managing these policies is complex due to the extensive port range (for example, `9500–9503` for Manager, `8500–8504` for Instance Manager, and `10000–30000` for replica traffic).

Restricting traffic to only known Longhorn components minimizes the "blast radius" if a malicious pod attempts lateral movement within the cluster.

**References**:

- [Longhorn Networking and Port Requirements](https://longhorn.io/docs/1.11.0/references/networking/)
- [Kubernetes Network Policies Guide](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
- [Longhorn Helm Chart NetworkPolicy Values](https://github.com/longhorn/longhorn/blob/master/chart/values.yaml)

#### Security Recommendation

Enable the built-in NetworkPolicies provided by the Longhorn Helm chart rather than maintaining manual manifests. This approach is more maintainable than manual manifests, as it ensures that the complete communication matrix including gRPC, UI, CSI and Webhook traffic is automatically whitelisted according to the specific requirements of the Longhorn version in use.

#### Configuration

The Longhorn Helm chart includes a built-in policy engine that generates required `NetworkPolicy` objects for all core components (Manager, Instance Manager, etc.).

1. **Policy Enforcement**: Toggle the internal policy engine during installation or upgrade. This automates the configuration of complex port ranges (for example, `8500–8504` for Instance Managers and `10000–30000` for replica traffic).
    - *Implementation detail*: Set `networkPolicies.enabled` to `true` in your Helm configuration. Refer to the [Helm Chart Values](https://github.com/longhorn/longhorn/blob/master/chart/values.yaml) for provider-specific settings (for example, RKE2, K3s, or Cilium).

2. **Egress for Backup Targets**: Built-in policies primarily secure intra-cluster communication. If your environment enforces a global default-deny egress policy, you must manually define egress rules to allow `longhorn-manager` and `instance-manager` pods to reach external backupstore endpoints (for example, NFS on port `2049` or S3/MinIO on port `443`).
    - *Technical context*: Review the [Longhorn Manager Egress Requirements](https://longhorn.io/docs/1.11.0/references/networking/#longhorn-manager) for specific destination details.

**Expected State**: Upon application, the `longhorn-system` namespace contains a suite of `NetworkPolicy` objects. This hardened state ensures that only authorized Longhorn components can communicate over the required TCP ports, effectively isolating the storage control and data planes from unauthorized cluster traffic.

### 4.2 Storage Network Isolation

#### Overview

By default, Longhorn uses the primary Kubernetes CNI network for all traffic. To enhance security and performance, Longhorn supports the isolation of in-cluster data traffic (replication and management) to a dedicated network interface. This segmentation prevents high-bandwidth storage traffic from interfering with the Kubernetes control plane and significantly reduces the attack surface of the storage layer by physically or logically isolating data replication.

**References**:

- [Longhorn Storage Network Documentation](https://longhorn.io/docs/1.11.0/advanced-resources/deploy/storage-network/)
- [Longhorn Storage Network Setting](https://longhorn.io/docs/1.11.0/references/settings/#storage-network)
- [Multus CNI Documentation](https://github.com/k8snetworkplumbingwg/multus-cni)

#### Security Recommendation

Implement network segregation by configuring a dedicated storage network using a Multus `NetworkAttachmentDefinition`. This ensures that sensitive storage traffic is physically or logically separated from general application and management traffic.

#### Configuration

Longhorn uses the Multus CNI to attach secondary network interfaces to storage-related components.

- **Multus Integration**: The **Storage Network** setting accepts a `NetworkAttachmentDefinition` in `<NAMESPACE>/<NAME>` format. Applying this setting adds the required CNI annotations to Longhorn pods, routing replication traffic through the secondary interface.

- **Operational Requirements**:
    - **Volume Detachment**: For immediate application of the setting, it is critical to stop all workloads and [detach all volumes](https://longhorn.io/docs/1.11.0/advanced-resources/deploy/storage-network/#setting-storage-network-after-longhorn-installation) before configuration. Longhorn automatically recreates the `instance-manager` and `backing-image-manager` pods once volumes are offline.
    - **V2 & RWX Hardening**: This isolation also extends to the V2 Data Engine (Technical Preview) and Read-Write-Many (RWX) volumes via the **Endpoint Network For RWX Volume** setting. Review the [RWX specific limitations](https://longhorn.io/docs/1.11.0/advanced-resources/deploy/storage-network/#limitation) regarding NFS mount points when enabling this feature.

- **Prerequisites**: Ensure the specified Multus network is reachable across all cluster nodes. Refer to the [Prerequisite Verification](https://longhorn.io/docs/1.11.0/advanced-resources/deploy/storage-network/#prerequisite) for testing connectivity between nodes using a simple DaemonSet.

**Expected State**: Once the setting is active, all storage-related pods (for example, `instance-manager`) feature the `k8s.v1.cni.cncf.io/networks` annotation. The hardened state is confirmed when storage replication traffic is successfully verified on the isolated secondary interface, leaving the primary cluster network for control plane operations.

### 4.3 Control Plane and Data Plane mTLS

#### Overview

By default, communication between the Longhorn control plane (`longhorn-manager`) and the data plane (`instance-manager`) is unencrypted. Implementing Mutual TLS (mTLS) ensures that all gRPC traffic is encrypted and that both parties authenticate each other using a trusted Certificate Authority (CA).

This prevents "man-in-the-middle" attacks and unauthorized command injection within the storage network. Longhorn uses a Kubernetes Secret-based mechanism to distribute these certificates.

**References**:

- [Longhorn mTLS Support Documentation](https://longhorn.io/docs/1.11.0/advanced-resources/security/mtls-support/)
- [Kubernetes TLS Secrets](https://kubernetes.io/docs/reference/kubectl/generated/kubectl_create/kubectl_create_secret_tls/)

#### Security Recommendation

Enable mTLS for all gRPC communication by deploying a Kubernetes Secret named `longhorn-grpc-tls` in the `longhorn-system` namespace. For the highest security **posture**, this secret should be created before Longhorn installation to ensure all components are initialized with encryption active.

#### Configuration

Longhorn utilizes an optional secret mount. If the `longhorn-grpc-tls` secret is present, components automatically enable TLS. Otherwise, they fall back to plaintext.

- **Certificate Requirements**: The `tls.crt` must be signed by your CA and **must** contain a specific list of Subject Alternative Names (SANs) to support Longhorn's internal service discovery (for example, `longhorn-backend`, `longhorn-engine-manager`, and `longhorn-csi`).
    - *Mandatory details*: Refer to the [Required SANs List](https://longhorn.io/docs/1.11.0/advanced-resources/security/mtls-support/#self-signed-certificate-setup) for the complete list of entries.

- **Secret Formatting**: Deploy the CA, certificate, and private key as a `kubernetes.io/tls` secret.
    - *Implementation detail*: See the [mTLS Secret YAML Example](https://longhorn.io/docs/1.11.0/advanced-resources/security/mtls-support/#setting-up-kubernetes-secrets) for the required structure.

- **Lifecycle and Upgrades**:
    - **Mixed Mode**: The control plane supports a non-TLS fallback to maintain communication with older instance managers during rolling upgrades.
    - **Component Restarts**: If mTLS is enabled on an existing cluster, all `longhorn-manager` and `instance-manager` pods must be restarted to mount the secret and initiate encrypted communication.

**Expected State**: Successful activation is validated through the `longhorn-manager` logs, which indicate that gRPC services are initializing with TLS enabled. Once verified, the storage network is effectively hardened against unauthenticated gRPC traffic.
