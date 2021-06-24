---
title: "K3S Upgrade Guide"
draft: true
weight: 5
---

<!-- TOC -->

- [Patterns for Cluster Upgrades](#patterns-for-cluster-upgrades)
- [Rancher Kubernetes Upgrade Best Practices](#rancher-kubernetes-upgrade-best-practices)
- [Registered K3s Kubernetes clusters](#registered-k3s-kubernetes-clusters)
- [Upgrade Using System Upgrade Controller](#upgrade-using-system-upgrade-controller)
  - [Deploy System Upgrade Controller](#deploy-system-upgrade-controller)
  - [Deploy Upgrade Plan](#deploy-upgrade-plan)
    - [Label Node to be Upgrade](#label-node-to-be-upgrade)
    - [Prepare and Deploy Plan](#prepare-and-deploy-plan)
- [Reference](#reference)
<!-- /TOC -->

## Patterns for Cluster Upgrades

K3S cluster upgrade use `In place` and `Rolling` pattern.

## Rancher Kubernetes Upgrade Best Practices

- Always [Backup Cluster](https://rancher.com/docs/rancher/v2.5/en/backups/).
- Always [Backup Longhorn Volume](https://longhorn.io/docs/1.1.1/snapshots-and-backups/).
- Following scenario and solution in drain node and prepare volumes to avoid pod's disruption budget.
- If cluster's workload downtime is allowed, scale down the workload to avoid long rebuild time.
- Prepare upgrade strategy/plan to have `1` currency controller node upgrade, and `n - 1` currency worker nodes upgrade. Also, need to make sure that upgrade timeout is long enough if cluster have many volumes or large volume size.

## Registered K3s Kubernetes clusters

Registered K3S cluster managed with Rancher should follow [Upgrading the Kubernetes Version](https://rancher.com/docs/rancher/v2.5/en/cluster-admin/upgrading-kubernetes/) to conduct Kubernetes cluster upgrade.

## Upgrade Using System Upgrade Controller

K3S cluster upgrade can also automated using [System Upgrade Controller](https://github.com/rancher/system-upgrade-controller) and [K3S Upgrade](https://github.com/k3s-io/k3s-upgrade) by feeding upgrade plan to system upgrade controllers to drain nodes, replace binaries, and pull updated images according to the plan. Upgrade detail can be find in the [document](https://rancher.com/docs/k3s/latest/en/upgrades/)

### Deploy System Upgrade Controller

```bash
CONTROLLER_RELEASE=v0.6.2 # https://github.com/rancher/system-upgrade-controller/releases/
kubectl apply -f https://github.com/rancher/system-upgrade-controller/releases/download/${CONTROLLER_RELEASE}/system-upgrade-controller.yaml
```

### Deploy Upgrade Plan

#### Label Node to be Upgrade

```bash
NODES=""
LABELS="k3s-upgrade=true"
for NODE in ${NODE_NAMES[*]}; do
    echo ${NODE} ${LABEL}
    kubectl label nodes ${NODE} ${LABEL}
done
```

#### Prepare and Deploy Plan

```bash
K3S_VERSION=v1.21.2+k3s1 # https://github.com/k3s-io/k3s/releases
```

Sample for K3S upgrade plan:

```yaml
# Server plan
apiVersion: upgrade.cattle.io/v1
kind: Plan
metadata:
  name: k3s-server-plan
  namespace: system-upgrade
  labels:
    k3s-upgrade: server
spec:
  concurrency: 1
  version: ${K3S_VERSION}
  nodeSelector:
    matchExpressions:
      - { key: k3s-upgrade, operator: Exists }
      - { key: k3s-upgrade, operator: NotIn, values: ["disabled", "false"] }
      - { key: k3s.io/hostname, operator: Exists }
      - { key: k3os.io/mode, operator: DoesNotExist }
      - { key: node-role.kubernetes.io/master, operator: In, values: ["true"] }
    # - {key: node-role.kubernetes.io/control-plane, operator: In, values: ["true"]}
  serviceAccountName: system-upgrade
  # Specify which node taints should be tolerated by pods applying the upgrade.
  # Anything specified here is appended to the default of:
  # - {key: node.kubernetes.io/unschedulable, effect: NoSchedule, operator: Exists}
  # - {key: CriticalAddonsOnly, operator: Exists}
  tolerations:
    - {
        key: node-role.kubernetes.io/master,
        effect: NoSchedule,
        operator: Exists,
      }
  cordon: true
  drain:
    force: true
  upgrade:
    image: rancher/k3s-upgrade
---
# Agent plan
apiVersion: upgrade.cattle.io/v1
kind: Plan
metadata:
  name: k3s-agent-plan
  namespace: system-upgrade
  labels:
    k3s-upgrade: agent
spec:
  concurrency: 2 # in general, this should be the number of workers - 1
  version: ${K3S_VERSION}
  nodeSelector:
    matchExpressions:
      - { key: k3s-upgrade, operator: Exists }
      - { key: k3s-upgrade, operator: NotIn, values: ["disabled", "false"] }
      - { key: k3s.io/hostname, operator: Exists }
      - { key: k3os.io/mode, operator: DoesNotExist }
      - {
          key: node-role.kubernetes.io/master,
          operator: NotIn,
          values: ["true"],
        }
    # - {key: node-role.kubernetes.io/control-plane, operator: NotIn, values: ["true"]}
  serviceAccountName: system-upgrade
  prepare:
    args:
      - prepare
      - k3s-server-plan
    image: rancher/k3s-upgrade
  cordon: true
  drain:
    force: true
    skipWaitForDeleteTimeout: 60 # set this to prevent upgrades from hanging on small clusters since k8s v1.18
  upgrade:
    image: rancher/k3s-upgrade
```

Deploy command:

```bash
kubectl apply -f ./k3s-upgrade.yaml
```

---

## Reference

- [K3S Upgrade](https://rancher.com/docs/k3s/latest/en/upgrades/)
- [system-upgrade-controller](https://github.com/rancher/system-upgrade-controller)
- [k3s-upgrade](https://github.com/k3s-io/k3s-upgrade)
