---
title: Detaching Volumes and Suspending Pods
weight: 8
---

To detach Longhorn volumes, you will need to first shut down all Kubernetes Pods using the volumes.

The easiest way to achieve this is by deleting all workloads and recreating them later after upgrading. If this is not desirable, some workloads may be suspended.

In this section, you'll learn how each workload can be modified to shut down its pods.

#### Deployment
Edit the Deployment with `kubectl edit deploy/<name>`.

Set `.spec.replicas` to `0`.

#### StatefulSet
Edit the StatefulSet with `kubectl edit statefulset/<name>`.

Set `.spec.replicas` to `0`.

#### DaemonSet
There is no way to suspend this workload.

Delete the DaemonSet with `kubectl delete ds/<name>`.

#### Pod
Delete the Pod with `kubectl delete pod/<name>`.

There is no way to suspend a Pod not managed by a workload controller.

#### CronJob
Edit the cronjob with `kubectl edit cronjob/<name>`.

Set `.spec.suspend` to `true`.

Wait for any currently executing jobs to complete, or terminate them by deleting relevant pods.

#### Job
Consider allowing the single-run job to complete.

Otherwise, delete the job with `kubectl delete job/<name>`.

#### ReplicaSet
Edit the ReplicaSet with `kubectl edit replicaset/<name>`.

Set `.spec.replicas` to `0`.

#### ReplicationController
Edit the ReplicationController with `kubectl edit rc/<name>`.

Set `.spec.replicas` to `0`.

Wait for the volumes used by Kubernetes to complete detachment.

Then detach all remaining volumes from Longhorn UI. These volumes were most likely created and attached outside of Kubernetes via Longhorn UI or REST API.