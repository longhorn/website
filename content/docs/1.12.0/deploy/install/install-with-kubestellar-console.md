---
title: Install with KubeStellar Console
weight: 14
---

[KubeStellar Console](https://console.kubestellar.io) is an open-source Kubernetes dashboard that provides guided installation missions for CNCF projects, including Longhorn.

The guided install mission walks you through the entire Longhorn installation process with:

- **Pre-flight checks**: Automatically verifies that your cluster meets Longhorn's [installation requirements](../#installation-requirements) before proceeding.
- **Step-by-step guidance**: Each installation step is presented with clear instructions and expected outcomes.
- **Progress tracking**: Visual progress indicators show your current position in the installation workflow.
- **Validation**: Post-install checks confirm that Longhorn components are running correctly.

> **Note**: Longhorn does not support downgrading. The guided install follows a forward-only upgrade path consistent with Longhorn's requirements.

## Using the Guided Install

1. Open the [Longhorn install mission](https://console.kubestellar.io/missions/install-longhorn) in KubeStellar Console.
2. Connect your Kubernetes cluster.
3. Follow the guided steps to complete the installation.

The mission installs Longhorn using Helm, similar to the [Install with Helm](./install-with-helm) method.

## More Information

- [KubeStellar Console](https://console.kubestellar.io) — Open-source Kubernetes dashboard
- [Mission source](https://github.com/kubestellar/console-kb/blob/master/fixes/cncf-install/install-longhorn.json) — The mission definition is open source and maintained by the KubeStellar community
