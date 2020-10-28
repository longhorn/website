---
title: Detaching Volumes
weight: 8
---

Shutdown all Kubernetes Pods using Longhorn volumes in order to detach the volumes. The easiest way to achieve this is by deleting all workloads and recreate them later after upgrade. If this is not desirable, some workloads may be suspended.

In this section, you'll learn how each workload can be modified to shut down its pods.

#### Deployment
Edit the deployment with `kubectl edit deploy/<name>`.

Set `.spec.replicas` to `0`.

#### StatefulSet
Edit the statefulset with `kubectl edit statefulset/<name>`.

Set `.spec.replicas` to `0`.

#### DaemonSet
There is no way to suspend this workload.

Delete the daemonset with `kubectl delete ds/<name>`.

#### Pod
Delete the pod with `kubectl delete pod/<name>`.

There is no way to suspend a pod not managed by a workload controller.

#### CronJob
Edit the cronjob with `kubectl edit cronjob/<name>`.

Set `.spec.suspend` to `true`.

Wait for any currently executing jobs to complete, or terminate them by deleting relevant pods.

#### Job
Consider allowing the single-run job to complete.

Otherwise, delete the job with `kubectl delete job/<name>`.

#### ReplicaSet
Edit the replicaset with `kubectl edit replicaset/<name>`.

Set `.spec.replicas` to `0`.

#### ReplicationController
Edit the replicationcontroller with `kubectl edit rc/<name>`.

Set `.spec.replicas` to `0`.

Wait for the volumes using by the Kubernetes to complete detaching.

Then detach all remaining volumes from Longhorn UI. These volumes were most likely created and attached outside of Kubernetes via Longhorn UI or REST API.