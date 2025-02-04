---
title: Install as a Rancher Apps & Marketplace
description: Run Longhorn on Kubernetes with Rancher 2.x
weight: 7
---

One benefit of installing Longhorn through Rancher Apps & Marketplace is that Rancher provides authentication to the Longhorn UI.

If there is a new version of Longhorn available, you will see an `Upgrade Available` sign on the `Apps & Marketplace` screen. You can click `Upgrade` button to upgrade Longhorn manager. See more about upgrade [here](../../upgrade).

## Prerequisites

Each node in the Kubernetes cluster where Longhorn is installed must fulfill [these requirements.](../#installation-requirements)

[This script](https://github.com/longhorn/longhorn/blob/v{{< current-version >}}/scripts/environment_check.sh) can be used to check the Longhorn environment for potential issues.

## Installation

> **Note**:
> * For Kubernetes < v1.25, if your cluster still enables Pod Security Policy admission controller, set `Other Settings > Pod Security Policy` to `true` to install `longhorn-psp` PodSecurityPolicy resource which allows privileged Longhorn pods to start.

1. Optional: If Rancher version is 2.5.9 or before, we recommend creating a new project for Longhorn, for example, `Storage`.
2. Navigate to the cluster where you will install Longhorn.
    {{< figure src="/img/screenshots/install/rancher-2.6/select-project.png" >}}
3. Navigate to the `Apps & Marketplace` screen.
    {{< figure src="/img/screenshots/install/rancher-2.6/apps-launch.png" >}}
4. Find the Longhorn item in the charts and click it.
    {{< figure src="/img/screenshots/install/rancher-2.6/longhorn.png" >}}
5. Click **Install**.
    {{< figure src="/img/screenshots/install/rancher-2.6/longhorn-chart.png" >}}
6. Optional: Select the project where you want to install Longhorn.
7. Optional: Customize the default settings.
    {{< figure src="/img/screenshots/install/rancher-2.6/launch-longhorn.png" >}}
8. Click Next. Longhorn will be installed in the longhorn-system namespace.
    {{< figure src="/img/screenshots/install/rancher-2.6/installed-longhorn.png" >}}
9. Click the Longhorn App Icon to navigate to the Longhorn dashboard.
    {{< figure src="/img/screenshots/install/rancher-2.6/dashboard.png" >}}

After Longhorn has been successfully installed, you can access the Longhorn UI by navigating to the `Longhorn` option from Rancher left panel.


## Access UI With Network Policy Enabled

Note that when the Network Policy is enabled, access to the UI from Rancher may be restricted.

Rancher interacts with the Longhorn UI via a service called remotedialer, which facilitates connections between Rancher and the downstream clusters it manages. This service allows a user agent to access the cluster through an endpoint on the Rancher server. Remotedialer connects to the Longhorn UI service by using the Kubernetes API Server as a proxy.

However, when the Network Policy is enabled, the Kubernetes API Server may be unable to reach pods on different nodes. This occurs because the Kubernetes API Server operates within the host’s network namespace without a dedicated per-pod IP address. If you're using the Calico CNI plugin, any process in the host’s network namespace (such as the API Server) connecting to a pod triggers Calico to encapsulate the packet in IPIP before forwarding it to the remote host. The tunnel address is chosen as the source to ensure the remote host knows to encapsulate the return packets correctly.

In other words, to allow the proxy to work with the Network Policy, the Tunnel IP of each node must be identified and explicitly permitted in the policy.

You can find the Tunnel IP by:
```
$ kubectl get nodes -oyaml | grep "Tunnel"

      projectcalico.org/IPv4VXLANTunnelAddr: 10.42.197.0
      projectcalico.org/IPv4VXLANTunnelAddr: 10.42.99.0
      projectcalico.org/IPv4VXLANTunnelAddr: 10.42.158.0
      projectcalico.org/IPv4VXLANTunnelAddr: 10.42.80.0
```

Next, permit traffic in the Network Policy using the Tunnel IP. You may need to update the Network Policy whenever new nodes are added to the cluster.
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: longhorn-ui-frontend
  namespace: longhorn-system
spec:
  podSelector:
    matchLabels:
      app: longhorn-ui
  policyTypes:
  - Ingress
  ingress:
  - from:
    - ipBlock:
        cidr: 10.42.197.0/32
    - ipBlock:
        cidr: 10.42.99.0/32
    - ipBlock:
        cidr: 10.42.158.0/32
    - ipBlock:
        cidr: 10.42.80.0/32
    ports:
      - port: 8000
        protocol: TCP
```

Another way to resolve the issue is by running the server nodes with `egress-selector-mode: cluster`. For more information, see [RKE2 Server Configuration Reference](https://docs.rke2.io/reference/server_config#critical-configuration-values) and [K3s Control-Plane Egress Selector configuration](https://docs.k3s.io/networking/basic-network-options#control-plane-egress-selector-configuration).