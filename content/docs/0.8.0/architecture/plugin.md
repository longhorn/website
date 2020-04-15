---
title: CSI Plugin
weight: 31
---

Longhorn is managed in Kubernetes via a [CSI Plugin](https://kubernetes-csi.github.io/docs/).  This allows for easy installation of the Longhorn plugin.

Longhron does leverage iscsi, so extra configuration of the node may be required.  This may include the installation of `open-iscsi` or `iscsiadm`. Depending on the distribution.