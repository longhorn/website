---
title: "Troubleshooting: Instance manager pods are restarted every hour"
author: Phan Le
draft: false
date: 2022-02-25
categories:
- "instance manager"
---

## Applicable versions
v1.0.1 or newer

## Background

Each Longhorn volume has one engine and one or more replicas (see more detail about Longhorn architecture at [here](https://longhorn.io/docs/1.2.3/concepts/)).
When a Longhorn volume is attached, Longhorn launches a process for each engine/replica object.
The engine process will be launched inside engine instance manager pods (the `instance-manager-e-xxxxxxxx` pods inside `longhorn-system` namespace).
The replica process will be launched inside replica instance manager pods (the `instance-manager-r-xxxxxxxx` pods inside `longhorn-system` namespace).

## Symptoms

The instance manager pods are restarted every hour.
As the consequence, Longhorn volumes and the workload pods are crashed every hour.

## Reason

One potential root cause is that the cluster has the default PriorityClass (i.e., the PriorityClass with `globalDefault` field set to `true`) but the [PriorityClass setting](https://longhorn.io/docs/1.2.3/references/settings/#priority-class) in Longhorn is empty.
See more about PriorityClass at [here](https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/#priorityclass).

When Longhorn creates the instance manager pods, it doesn't set the PriorityClass for them because the PriorityClass setting in Longhorn is empty.
Because the cluster has default PriorityClass, Kubernetes automatically uses it for newly created Pods without a PriorityClassName.
Later on, Longhorn detects the difference between the actual PriorityClass in the instance manager pods and the PriorityClass in Longhorn setting,
so Longhorn deletes and recreates the instance manager pods. This happens every hour since Longhorn resyncs all setting every hour.

#### Solution
Set the PriorityClass setting in Longhorn to be the same as the default PriorityClass

## Related information

* Longhorn issue: https://github.com/longhorn/longhorn/issues/2820
