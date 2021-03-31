---
title: Announcing Longhorn v1.1.0
author: Sheng Yang
draft: false
date: 2021-01-22
categories:
  - "announcement"
---

# Announcing Longhorn v1.1.0

Hi, Longhorn community members!

Today I am excited to announce our latest Longhorn release: v1.1.0!

Longhorn v1.1 is a huge step forward to the ultimate goal of the project: making persistent storage ubiquitous in Kubernetes. Here are a few highlights of Longhorn v1.1.0.


## Built-in ReadWriteMany(RWX) Support

ReadWriteMany(RWX) support is one of the most requested features since we announced the project four years ago, and it’s now part of Longhorn.

However, it's very different from Longhorn's original design target: providing highly available persistent block storage. Traditionally, distributed block storage (which provides ReadWriteOnce support) works differently from distributed file systems (which provide ReadWriteMany support). Normally users would format block storage into a filesystem before using it. To keep the filesystem on top of the block device functioning correctly, the in-memory cache of the filesystem must be consistent with the data underneath. Since the in-memory cache cannot be shared across different nodes, block storage only supports writing by a single node.

A distributed file system is different. A common design is to treat the individual file as a single object and handle the locking of objects to make sure it's properly synchronized between nodes since it's the filesystem and knows which file is being worked on.

Despite the differences, we realized RWX support was critical to many of our users' use cases, so in the v1.0 release, we've introduced the NFS provisioner. However, it comes with a few shortcomings:



1. Users have to create the NFS provisioner and use Longhorn volume backing it manually.
2. One Longhorn volume would be shared across different NFS volumes, so it's hard to properly budget the space, or backup/restore the associated volumes.

To address those issues, we've implemented the native RWX support in Longhorn v1.1. on top of Longhorn. Starting with Longhorn v1.1:



1. Users can create RWX volume using Longhorn directly, by specifying the AccessMode when creating PVC as `ReadWriteMany` (instead of `ReadWriteOnce` for block device).
2. Users can snapshot/backup/restore all the RWX volumes like other Longhorn volumes.

Currently, the RWX feature is still considered experimented in Longhorn. One thing we're still working on is ensuring better availability. At the moment, if the server that is running the NFS server for the RWX is down, we will restart the server. Based on the user's setting of [Automatically Delete Workload Pod when The Volume Is Detached Unexpectedly](https://longhorn.io/docs/1.1.0/references/settings/#automatically-delete-workload-pod-when-the-volume-is-detached-unexpectedly), we’ll delete the workload pods that are using the volume to trigger the pod remount process. It will incur workload downtime during the process. We're working on a better way to reduce the downtime in the node failure cases.

You can find more information on our native RWX support [here](https://longhorn.io/docs/1.1.0/advanced-resources/rwx-workloads/).


## ARM64 support

ARM64 support is [one of the oldest issues](https://github.com/longhorn/longhorn/issues/6 ) in Longhorn. Six years later, thanks to the help of  community member [Ivan Angelov](https://github.com/ivang), Longhorn now runs on ARM64.

To install the ARM64 version of Longhorn, you just need to install Longhorn the same as before. It's unnecessary to change to ARM64 specific images since the Longhorn images are built as multi-arch images by default, so it will automatically apply the right image to your system.

As in Longhorn v1.1, ARM64 support is still in the experiment stage. Please give it a try and let us know what you think.


## CSI Snapshotter Support

CSI Snapshotter was a beta feature since Kubernetes v1.17, and is now GA in Kubernetes v1.20. This Kubernetes CSI feature allows users to create snapshots for volumes directly using the `kubectl` command.

In Longhorn's context, the CSI snapshots are mapped into Longhorn Backups (instead of in-cluster Snapshots). Now with Longhorn v1.1, users can create/restore backups for the volumes without using the Longhorn UI.

To make CSI Snapshotter work on your Kubernetes cluster, you’ll need a component called Snapshot Controller. It is not a part of Longhorn installation since Longhorn doesn't have the permission to install other cluster-wide services. You can check the steps [here](https://longhorn.io/docs/1.1.0/snapshots-and-backups/csi-snapshot-support/enable-csi-snapshot-support/).

After installing Snapshot Controller and setting the backup target correctly in Longhorn, follow these links to create a [VolumeSnapshotClass](https://longhorn.io/docs/1.1.0/snapshots-and-backups/csi-snapshot-support/enable-csi-snapshot-support/), [create a CSI snapshot](https://longhorn.io/docs/1.1.0/snapshots-and-backups/csi-snapshot-support/create-a-backup-via-csi/) and [restore a CSI snapshot](https://longhorn.io/docs/1.1.0/snapshots-and-backups/csi-snapshot-support/restore-a-backup-via-csi/).


## Prometheus Support

With Prometheus endpoints support in Longhorn v1.1, you can use this existing monitoring solution to collect stats about Longhorn and set up alerts.

To enable Longhorn Prometheus support, you need to either [install the Prometheus operator](https://longhorn.io/docs/1.1.0/monitoring/prometheus_and_grafana_setup/) or use a solution based on the Prometheus operator (e.g. Rancher Monitoring v2).

Once you’ve installed the Prometheus operator, simply add the [ServiceMonitor YAML](https://longhorn.io/docs/1.1.0/monitoring/prometheus_and_grafana_setup/#install-longhorn-servicemonitor) to enable Prometheus support in Longhorn. If you're using Grafana, you can import the [Longhorn v1.1.0 example dashboard](https://grafana.com/grafana/dashboards/13032) to get a quick overview of the metrics exported by Longhorn.

Longhorn also exposes Persistent Volume related kubelet metrics, including the available space and inode for a formatted Longhorn volume. Those metrics are immediately available as long as your monitoring system is collecting standard kubelet metrics for Kubernetes Persistent Volumes.

See [here](https://longhorn.io/docs/1.1.0/monitoring/metrics/) for detailed instructions.

#### Longhorn Grafana Example Dashboard
![Longhorn Grafana Example Dashboard](https://longhorn.io/img/screenshots/monitoring/longhorn-example-grafana-dashboard.png "Longhorn Grafana Example Dashboard")


## Enhanced Failure Recovery


### Node Down Handling

As you may know, Kubernetes has a few limitations regarding the node down with stateful workload, as we explained [here](https://longhorn.io/docs/1.1.0/high-availability/node-failure/#what-to-expect-when-a-kubernetes-node-fails). This results in the stateful workload Pods not being recreated successfully on other nodes in the cluster (which is different from the stateless workload case). Manual intervention is required in those cases.

In Longhorn v1.0, we introduced a feature to automatically recover the Deployment workload Pods if the node they're running goes down by automatically cleaning up the volume attachment object. This allows the PV to be attached on another node.

Now in Longhorn v1.1, we've moved one step further to allow automatic recovery for both StatefulSet and Deployment Pods if they're using Longhorn volumes. Based on the setting [Pod Deletion Policy When the Node Is Down](https://longhorn.io/docs/1.1.0/references/settings/#pod-deletion-policy-when-node-is-down), Longhorn can automatically detect the node down scenario and delete the affected Pod to trigger the Kubernetes recreate mechanism.

Note: The default setting for the option is `do-nothing` since we need users to understand the new behavior and explicitly approve Longhorn from doing so before proceeding. We recommend you adjust the setting according to your workload's characteristics.


### Rebuild using existing replica

Previously, when a volume was degraded, Longhorn would always try to rebuild a new replica. In the case of temporary network interruption, even a replica that contains mostly correct data will not be considered for rebuilding when the network resumes. Even though the old replica will be removed after `Replica Stale Timeout`, this results in additional space requirements for the new replica rebuilding.

In Longhorn v1.1, we've introduced a way of rebuilding with existing replicas. The new [Replica Replenish Wait Interval](https://longhorn.io/docs/1.1.0/references/settings/#replica-replenishment-wait-interval) setting specifies how long Longhorn will wait before trying to fully rebuild a new replica instead of reusing the existing replica for rebuilding. Also, if we failed to rebuild using an existing replica three times, we will give up this replica and continue with other existing replicas or fully rebuild a new replica. This process will cut the storage consumption as well as speed up the rebuilding process.


### Minimal Resource requirements

From time to time, we receive reports that show the volume was remounted as read-only by the Linux kernel, mostly caused by losing the Longhorn volume. This occurs when the Longhorn engine loses all the connections to the replicas due to various reasons. The three most common reasons are:



1. CPU overutilization
2. Network interruption
3. Disk performance

As you probably know, a storage system is CPU, network, and disk IO intensive. A large amount of data needs to be processed by the CPU, then transferred through the network, and finally written to the underlying disk. A bottleneck on either of the parts above can result in suboptimal performance and even an unstable system. You always want to keep an eye on your system to make sure it's not overloaded.

Starting with Longhorn v1.1, we recommend reserving 25 percent of your CPU resources on the node for Longhorn engines. That means in the production environment, we recommend setting the [Guaranteed Engine CPU](https://longhorn.io/docs/1.1.0/references/settings/#guaranteed-engine-cpu) option to 12.5 percent of your total CPU numbers on the node. It's half of 25 percent since the setting is applied to both Engine Instance Manager and Replica Instance Manager on the node. See the updated [Best Practice Guide](https://longhorn.io/docs/1.1.0/best-practices) for details. 

We also recommend you reserve 100m (1/10 of a CPU) for each engine and replica. That means if you've reserved 1 CPU in the "Guaranteed Engine CPU" setting, then Longhorn will have enough CPU to serve 10 Engines and 10 Replicas on the node.

Check our[ knowledge base article](https://longhorn.io/kb/troubleshooting-volume-readonly-or-io-error/) for more information if you had issues with volume remounted as read-only. 

In addition, we’ve introduced the data locality feature to help with stability issues users might experience in unstable network environments. When this option is enabled for the volume, Longhorn will always try to keep a replica local to the workload, which guarantees even when the network interruption happens, the volume will continue working for the workload that's running on the same node.


## Enhanced Node Maintenance

We have also introduced various enhancements regarding node maintenance:



1. Replica eviction is now available on disk and node level. It can help users who want to replace a node or a disk.
2. We’ve implemented automated node removal. Now Longhorn will automatically recognize the missing node and remove it if the Kubernetes cluster is scaling down.
3. The [Disable Replica Rebuild](https://longhorn.io/docs/1.1.0/references/settings/#disable-replica-rebuild) setting stops replica rebuild cluster-wide for maintenance.
4. Kubernetes Drain is now supported by using Pod Disruption Budget to control the Drain process. Thanks to [Takashi Kusumi](https://github.com/tksm) for the great idea!
    1. Longhorn will stop the Drain process if it contains the last healthy replica of any volume by default to prevent unintentionally service outage during the Drain process. The behavior can be changed by [Allow Node Drain with the Last Healthy Replica](https://longhorn.io/docs/1.1.0/references/settings/#allow-node-drain-with-the-last-healthy-replica) setting.


## Upgrade

Ready to upgrade to Longhorn v1.1.0? You can find the upgrade instructions [here](https://longhorn.io/docs/1.1.0/deploy/upgrade/).

Live upgrades for engines are supported. Make sure to upgrade the engines for volumes when you complete the Longhorn manager upgrade process.

Please share your feedback with us at [GitHub](https://github.com/longhorn/longhorn) or Slack channel (#longhorn at CNCF slack).

Enjoy!

