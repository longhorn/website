---
title: "RKE2 Upgrade Guide"
draft: true
weight: 6
---

<!-- TOC -->

- [Patterns for Cluster Upgrades](#patterns-for-cluster-upgrades)
- [Rancher Kubernetes Upgrade Best Practices](#rancher-kubernetes-upgrade-best-practices)
- [Registered RKE2 Kubernetes clusters](#registered-rke2-kubernetes-clusters)
- [Upgrade Using System Upgrade Controller](#upgrade-using-system-upgrade-controller)
  - [Deploy System Upgrade Controller](#deploy-system-upgrade-controller)
  - [Deploy Upgrade Plan](#deploy-upgrade-plan)
    - [Label Node to be Upgrade](#label-node-to-be-upgrade)
    - [Prepare and Deploy Plan](#prepare-and-deploy-plan)
- [Reference](#reference)
<!-- /TOC -->

## Patterns for Cluster Upgrades

RKE2 cluster upgrade use `In place` and `Rolling` patterns.

## Rancher Kubernetes Upgrade Best Practices

- Always [Backup Cluster](https://rancher.com/docs/rancher/v2.5/en/backups/).
- Always [Backup Longhorn Volume](https://longhorn.io/docs/1.1.1/snapshots-and-backups/).
- Following scenario and solution in drain node and prepare volumes to avoid pod's disruption budget.
- If cluster's workload downtime is allowed, scale down the workload to avoid long rebuild time.
- Prepare upgrade strategy/plan to have `1` currency controller node upgrade, and `n - 1` currency worker nodes upgrade. Also, need to make sure that upgrade timeout is long enough if cluster have many volumes or large volume size.

## Registered RKE2 Kubernetes clusters

Registered RKE2 cluster managed with Rancher should follow [Upgrading the Kubernetes Version](https://rancher.com/docs/rancher/v2.5/en/cluster-admin/upgrading-kubernetes/) to conduct Kubernetes cluster upgrade.

## Upgrade Using System Upgrade Controller

RKE2 cluster upgrade can also automated using [System Upgrade Controller](https://github.com/rancher/system-upgrade-controller) and [RKE2 Upgrade](https://github.com/rancher/rke2-upgrade) by feeding upgrade plan to system upgrade controllers to drain nodes, replace binaries, and pull updated images according to the plan. Upgrade detail can be find in the [document](https://docs.rke2.io/upgrade/upgrade/)

### Deploy System Upgrade Controller

```bash
CONTROLLER_RELEASE=v0.6.2 # https://github.com/rancher/system-upgrade-controller/releases/
kubectl apply -f https://github.com/rancher/system-upgrade-controller/releases/download/${CONTROLLER_RELEASE}/system-upgrade-controller.yaml
```

### Deploy Upgrade Plan

#### Label Node to be Upgrade

```bash
NODES=""
LABELS="rke2-upgrade=true"
for NODE in ${NODE_NAMES[*]}; do
    echo ${NODE} ${LABEL}
    kubectl label nodes ${NODE} ${LABEL}
done
```

#### Prepare and Deploy Plan

```bash
RKE2_VERSION=v1.20.7+rke2r2 # https://github.com/rancher/rke2/releases
```

[Sample for RKE2 upgrade plan](https://docs.rke2.io/upgrade/automated_upgrade.html):

```yaml
# Server plan
apiVersion: upgrade.cattle.io/v1
kind: Plan
metadata:
  name: rke2-server-plan
  namespace: system-upgrade
  labels:
    rke2-upgrade: server
spec:
  concurrency: 1
  version: ${RKE2_VERSION}
  nodeSelector:
    matchExpressions:
      - { key: rke2-upgrade, operator: Exists }
      - { key: rke2-upgrade, operator: NotIn, values: ["disabled", "false"] }
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
    image: rancher/rke2-upgrade
---
# Agent plan
apiVersion: upgrade.cattle.io/v1
kind: Plan
metadata:
  name: rke2-agent-plan
  namespace: system-upgrade
  labels:
    rke2-upgrade: agent
spec:
  concurrency: 2 # in general, this should be the number of workers - 1
  version: ${RKE2_VERSION}
  nodeSelector:
    matchExpressions:
      - { key: rke2-upgrade, operator: Exists }
      - { key: rke2-upgrade, operator: NotIn, values: ["disabled", "false"] }
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
      - rke2-server-plan
    image: rancher/rke2-upgrade
  cordon: true
  drain:
    force: true
    skipWaitForDeleteTimeout: 60 # set this to prevent upgrades from hanging on small clusters since k8s v1.18
  upgrade:
    image: rancher/rke2-upgrade
```

Deploy command:

```bash
kubectl apply -f ./rke2-upgrade.yaml
```

---

## Reference

- [RKE2 Upgrade](https://docs.rke2.io/upgrade/upgrade/)
- [system-upgrade-controller](https://github.com/rancher/system-upgrade-controller)
- [rke2-upgrade](https://github.com/rancher/rke2-upgrade)
