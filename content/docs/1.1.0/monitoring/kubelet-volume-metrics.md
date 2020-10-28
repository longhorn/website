---
title: Support Kubelet Volume Metrics
weight: 2
---

## About Kubelet volume metrics

Kubelet exposes [the following metrics](https://github.com/kubernetes/kubernetes/blob/4b24dca228d61f4d13dcd57b46465b0df74571f6/pkg/kubelet/metrics/collectors/volume_stats.go#L27):

1. kubelet_volume_stats_capacity_bytes
1. kubelet_volume_stats_available_bytes
1. kubelet_volume_stats_used_bytes
1. kubelet_volume_stats_inodes
1. kubelet_volume_stats_inodes_free
1. kubelet_volume_stats_inodes_used

Those metrics measure PVC's filesystem related information inside a Longhorn block device.
They are different than [longhorn_volume_*](../metrics) metrics which measure Longhorn block devices specific information.

You can set up a monitoring system that scrapes Kubelet metric endpoints to obtains PVCs' status and set up alerts for abnormal events such as the PVC is about to run out of storage space.
A popular monitoring setup is [prometheus-operator/kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack) which scrapes `kubelet_volume_stats_*` metrics and provides a dashboard, alert rules for them.


## Longhorn CSI Plugin support

In v1.1.0, Longhorn CSI plugin supports the `NodeGetVolumeStats` RPC according to [CSI spec](https://github.com/container-storage-interface/spec/blob/master/spec.md#nodegetvolumestats).
This allows Kubelet to query the Longhorn CSI plugin for PVC's status.
Kubelet then exposes that information in `kubelet_volume_stats_*` metrics.
