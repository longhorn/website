---
title: Kubelet Volume Metrics Support
weight: 2
---

## About Kubelet Volume Metrics

Kubelet exposes [the following metrics](https://github.com/kubernetes/kubernetes/blob/4b24dca228d61f4d13dcd57b46465b0df74571f6/pkg/kubelet/metrics/collectors/volume_stats.go#L27):

1. kubelet_volume_stats_capacity_bytes
1. kubelet_volume_stats_available_bytes
1. kubelet_volume_stats_used_bytes
1. kubelet_volume_stats_inodes
1. kubelet_volume_stats_inodes_free
1. kubelet_volume_stats_inodes_used

Those metrics measure information related to a PVC's filesystem inside a Longhorn block device.

They are different than [longhorn_volume_*](../metrics) metrics, which measure information specific to a Longhorn block device.

You can set up a monitoring system that scrapes Kubelet metric endpoints to obtains a PVC's status and set up alerts for abnormal events, such as the PVC being about to run out of storage space.

A popular monitoring setup is [prometheus-operator/kube-prometheus-stack,](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack) which scrapes `kubelet_volume_stats_*` metrics and provides a dashboard and alert rules for them.

## Longhorn CSI Plugin Support

In v1.1.0, Longhorn CSI plugin supports the `NodeGetVolumeStats` RPC according to the [CSI spec](https://github.com/container-storage-interface/spec/blob/master/spec.md#nodegetvolumestats).

This allows the kubelet to query the Longhorn CSI plugin for a PVC's status.

The kubelet then exposes that information in `kubelet_volume_stats_*` metrics.
