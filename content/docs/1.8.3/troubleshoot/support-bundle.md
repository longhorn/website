---
title: Support Bundle
weight: 2
---

Since v1.4.0, Longhorn replaced the in-house support bundle generation with a general-purpose [support bundle kit](https://github.com/rancher/support-bundle-kit). 

You can click the `Generate Support Bundle` at the bottom of Longhorn UI to download a zip file containing cluster manifests and logs.

During support bundle generation, Longhorn will create a Deployment for the support bundle manager.

> **Note:** The support bundle manager will use a dedicated `longhorn-support-bundle` service account and `longhorn-support-bundle` cluster role binding with `cluster-admin` access for bundle collection.

With the support bundle, you can simulate a mocked Kubernetes cluster that is interactable with the `kubectl` command. See [simulator command](https://github.com/rancher/support-bundle-kit#simulator-command) for more details.


## Limitations

Longhorn currently does not support concurrent generation of multiple support bundles. We recommend waiting until the completion of the ongoing support bundle before initiating a new one. If a new support bundle is created while another one is still in progress, Longhorn will overwrite the older support bundle.


## History
[Original Feature Request](https://github.com/longhorn/longhorn/issues/2759)

Available since v1.4.0
