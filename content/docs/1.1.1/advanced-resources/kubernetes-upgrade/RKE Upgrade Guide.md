---
title: "RKE Upgrade Guide"
draft: true
weight: 4
---

<!-- TOC -->

- [Patterns for Cluster Upgrades](#patterns-for-cluster-upgrades)
- [Rancher Kubernetes Upgrade Best Practices](#rancher-kubernetes-upgrade-best-practices)
- [Rancher-launched RKE Kubernetes clusters](#rancher-launched-rke-kubernetes-clusters)
- [Upgrade with Upgrade Strategy](#upgrade-with-upgrade-strategy)
- [Reference](#reference)
<!-- /TOC -->

## Patterns for Cluster Upgrades

RKE cluster upgrade use `In place` and `Rolling` patterns.

## Rancher Kubernetes Upgrade Best Practices

- Always [Backup Cluster](https://rancher.com/docs/rancher/v2.5/en/backups/).
- Always [Backup Longhorn Volume](https://longhorn.io/docs/1.1.1/snapshots-and-backups/).
- Following scenario and solution in drain node and prepare volumes to avoid pod's disruption budget.
- If cluster's workload downtime is allowed, scale down the workload to avoid long rebuild time.
- Prepare upgrade strategy/plan to have `1` currency controller node upgrade, and `n - 1` currency worker nodes upgrade. Also, need to make sure that upgrade timeout is long enough if cluster have many volumes or large volume size.

## Rancher-launched RKE Kubernetes clusters

Registered RKE2 cluster managed with Rancher should follow [Upgrading the Kubernetes Version](https://rancher.com/docs/rancher/v2.5/en/cluster-admin/upgrading-kubernetes/) to conduct Kubernetes cluster upgrade.

## Upgrade with Upgrade Strategy

RKE2 cluster upgrade can also automated using upgrade strategy in `cluster.yaml` to drain nodes, replace binaries, and pull updated images according to the plan. Upgrade detail can be find in the [document](https://rancher.com/docs/rke/latest/en/upgrades/)

List Kubernetes Version:

```bash
rke config --list-version --all
```

List System Images Version:

```bash
rke config --system-images --version ${KUBERNETES_VERSION}
```

- Refer to [Upgrade with Upgrade Strategy](https://rancher.com/docs/rke/latest/en/upgrades/configuring-strategy/) for configuration, note as below:

> In case both kubernetes_version and system_images are defined, the system_images configuration will take precedence over kubernetes_version.
>
> In addition, if neither kubernetes_version nor system_images are configured in the cluster.yml, RKE will apply the default Kubernetes version for the specific version of RKE used to invoke rke up.

Sample for RKE upgrade config:

```yaml
# If you intened to deploy Kubernetes in an air-gapped environment,
# please consult the documentation on how to configure custom RKE images.
nodes:
  - address: { { MASTER_01 } }
    port: "22"
    internal_address: ""
    role:
      - controlplane
      - etcd
    hostname_override: ""
    user: { { PLATFORM_DISTRO } }
    docker_socket: /var/run/docker.sock
    ssh_key: ~/.ssh/id_rsa
    ssh_key_path: ""
    ssh_cert: ""
    ssh_cert_path: ""
    labels: {}
    taints: []
  # - address: {{ MASTER_02 }}
  #   port: "22"
  #   internal_address: ""
  #   role:
  #   - controlplane
  #   - etcd
  #   hostname_override: ""
  #   user: {{ PLATFORM_DISTRO }}
  #   docker_socket: /var/run/docker.sock
  #   ssh_key: ""
  #   ssh_key_path: ~/.ssh/id_rsa
  #   ssh_cert: ""
  #   ssh_cert_path: ""
  #   labels: {}
  #   taints: []
  # - address: {{ MASTER_03 }}
  #   port: "22"
  #   internal_address: ""
  #   role:
  #   - controlplane
  #   - etcd
  #   hostname_override: ""
  #   user: {{ PLATFORM_DISTRO }}
  #   docker_socket: /var/run/docker.sock
  #   ssh_key: ""
  #   ssh_key_path: ~/.ssh/id_rsa
  #   ssh_cert: ""
  #   ssh_cert_path: ""
  #   labels: {}
  #   taints: []
  - address: { { WORKER_01 } }
    port: "22"
    internal_address: ""
    role:
      - worker
    hostname_override: ""
    user: { { PLATFORM_DISTRO } }
    docker_socket: /var/run/docker.sock
    ssh_key: ""
    ssh_key_path: ~/.ssh/id_rsa
    ssh_cert: ""
    ssh_cert_path: ""
    labels: {}
    taints: []
  - address: { { WORKER_02 } }
    port: "22"
    internal_address: ""
    role:
      - worker
    hostname_override: ""
    user: { { PLATFORM_DISTRO } }
    docker_socket: /var/run/docker.sock
    ssh_key: ""
    ssh_key_path: ~/.ssh/id_rsa
    ssh_cert: ""
    ssh_cert_path: ""
    labels: {}
    taints: []
  - address: { { WORKER_03 } }
    port: "22"
    internal_address: ""
    role:
      - worker
    hostname_override: ""
    user: { { PLATFORM_DISTRO } }
    docker_socket: /var/run/docker.sock
    ssh_key: ""
    ssh_key_path: ~/.ssh/id_rsa
    ssh_cert: ""
    ssh_cert_path: ""
    labels: {}
    taints: []
upgrade_strategy:
  max_unavailable_worker: 10% # 34% | 10%
  max_unavailable_controlplane: 1
  drain: true
  node_drain_input:
    force: true
    ignore_daemonsets: true
    delete_local_data: true
    grace_period: 10
    timeout: 600 # 60 | 600
services:
  etcd:
    image: ""
    extra_args: {}
    extra_binds: []
    extra_env: []
    win_extra_args: {}
    win_extra_binds: []
    win_extra_env: []
    external_urls: []
    ca_cert: ""
    cert: ""
    key: ""
    path: ""
    uid: 0
    gid: 0
    snapshot: null
    retention: ""
    creation: ""
    backup_config: null
  kube-api:
    image: ""
    extra_args: {}
    extra_binds: []
    extra_env: []
    win_extra_args: {}
    win_extra_binds: []
    win_extra_env: []
    service_cluster_ip_range: 10.43.0.0/16
    service_node_port_range: ""
    pod_security_policy: false
    always_pull_images: false
    secrets_encryption_config: null
    audit_log: null
    admission_configuration: null
    event_rate_limit: null
  kube-controller:
    image: ""
    extra_args: {}
    extra_binds: []
    extra_env: []
    win_extra_args: {}
    win_extra_binds: []
    win_extra_env: []
    cluster_cidr: 10.42.0.0/16
    service_cluster_ip_range: 10.43.0.0/16
  scheduler:
    image: ""
    extra_args: {}
    extra_binds: []
    extra_env: []
    win_extra_args: {}
    win_extra_binds: []
    win_extra_env: []
  kubelet:
    image: ""
    extra_args:
      volume-plugin-dir: /usr/libexec/kubernetes/kubelet-plugins/volume/exec
    extra_binds:
      - /usr/libexec/kubernetes/kubelet-plugins/volume/exec:/usr/libexec/kubernetes/kubelet-plugins/volume/exec
    extra_env: []
    win_extra_args: {}
    win_extra_binds: []
    win_extra_env: []
    cluster_domain: cluster.local
    infra_container_image: ""
    cluster_dns_server: 10.43.0.10
    fail_swap_on: false
    generate_serving_certificate: false
  kubeproxy:
    image: ""
    extra_args: {}
    extra_binds: []
    extra_env: []
    win_extra_args: {}
    win_extra_binds: []
    win_extra_env: []
network:
  plugin: canal
  options: {}
  mtu: 0
  node_selector: {}
  update_strategy: # Available in v2.4
    strategy: "RollingUpdate"
    rollingUpdate:
      maxUnavailable: 6
  tolerations: []
authentication:
  strategy: x509
  sans: []
  webhook: null
addons: ""
addons_include: []
system_images:
  # etcd: ""
  # alpine: ""
  # nginx_proxy: ""
  # cert_downloader: ""
  # kubernetes_services_sidecar: ""
  # kubedns: ""
  # dnsmasq: ""
  # kubedns_sidecar: ""
  # kubedns_autoscaler: ""
  # coredns: ""
  # coredns_autoscaler: ""
  # nodelocal: ""
  # kubernetes: ""
  # flannel: ""
  # flannel_cni: ""
  # calico_node: ""
  # calico_cni: ""
  # calico_controllers: ""
  # calico_ctl: ""
  # calico_flexvol: ""
  # canal_node: ""
  # canal_cni: ""
  # canal_controllers: ""
  # canal_flannel: ""
  # canal_flexvol: ""
  # weave_node: ""
  # weave_cni: ""
  # pod_infra_container: ""
  # ingress: ""
  # ingress_backend: ""
  # metrics_server: ""
  # windows_pod_infra_container: ""
  # aci_cni_deploy_container: ""
  # aci_host_container: ""
  # aci_opflex_container: ""
  # aci_mcast_container: ""
  # aci_ovs_container: ""
  # aci_controller_container: ""
  # aci_gbp_server_container: ""
  # aci_opflex_server_container: ""
ssh_key_path: ~/.ssh/id_rsa
ssh_cert_path: ""
ssh_agent_auth: false
authorization:
  mode: rbac
  options: {}
ignore_docker_version: null
kubernetes_version: "{{ K8S_VERSION }}" # rke config --list-version --all
private_registries: []
ingress:
  provider: "nginx" # "nginx"
  options: {}
  node_selector: {}
  extra_args: {}
  dns_policy: ""
  extra_envs: []
  extra_volumes: []
  extra_volume_mounts: []
  update_strategy: # Available in v2.4
    strategy: "RollingUpdate"
    rollingUpdate:
      maxUnavailable: 5
  http_port: 0
  https_port: 0
  network_mode: ""
  tolerations: []
  default_backend: null
  default_http_backend_priority_class_name: ""
  nginx_ingress_controller_priority_class_name: ""
cluster_name: ""
cloud_provider:
  name: ""
prefix_path: ""
win_prefix_path: ""
addon_job_timeout: 0
bastion_host:
  address: ""
  port: ""
  user: ""
  ssh_key: ""
  ssh_key_path: ""
  ssh_cert: ""
  ssh_cert_path: ""
monitoring:
  provider: "metrics-server"
  options: {}
  node_selector: {}
  update_strategy: # Available in v2.4
    strategy: "RollingUpdate"
    rollingUpdate:
      maxUnavailable: 8
  replicas: null
  tolerations: []
  metrics_server_priority_class_name: ""
restore:
  restore: false
  snapshot_name: ""
rotate_encryption_key: false
dns:
  provider: "coredns"
  update_strategy: # Available in v2.4
    strategy: "RollingUpdate"
    rollingUpdate:
      maxUnavailable: 20%
      maxSurge: 15%
  linear_autoscaler_params:
    cores_per_replica: 0.34
    nodes_per_replica: 4
    prevent_single_point_failure: true
    min: 2
    max: 3
```

Upgrade command:

```bash
rke up --ssh-agent-auth
```

---

## Reference

- [RKE Upgrade](https://rancher.com/docs/rke/latest/en/upgrades/)
- [Kubernetes Version Precedence](https://rancher.com/docs/rke/latest/en/upgrades/#kubernetes-version-precedence)
- [Upgrading and Rolling Back Kubernetes](https://rancher.com/docs/rancher/v2.5/en/cluster-admin/upgrading-kubernetes/)
