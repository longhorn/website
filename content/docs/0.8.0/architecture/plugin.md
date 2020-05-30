---
title: CSI Plugin
weight: 31
---

Longhorn is managed in Kubernetes via a [CSI Plugin](https://kubernetes-csi.github.io/docs/).  This allows for easy installation of the Longhorn plugin.

Longhorn leverages iSCSI, so extra configuration of the node may be required.  This includes the installation of `open-iscsi` or `iscsiadm`, depending on the distribution.
