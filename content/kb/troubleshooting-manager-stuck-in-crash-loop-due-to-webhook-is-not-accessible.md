---
title: "Troubleshooting: Longhorn Manager Stuck in CrashLoopBackOff Due to Webhook Not Accessible"
authors:
- "Jack Lin"
draft: false
date: 2025-01-17
versions:
- ">= v1.5.0"
categories:
- "longhorn manager"
---

## Applicable versions

Longhorn >= v1.5.0.

## Symptoms

Starting from v1.5.0, the webhook services were merged into the Longhorn Manager. During startup, the manager first initializes the admission and conversion webhook services, ensuring they are accessible by curling the webhook service's URL before starting the manager service.

In some cases, the Longhorn Manager pod may enter a CrashLoopBackOff state due to the webhook service being inaccessible. Its failure can lead to the manager pod being repeatedly restarted. Below, we outline the three most common root causes for this issue and provide solutions to resolve it.

### Root Cause 1: Firewall Is Not Set Correctly

The firewall configuration may be preventing communication between the pods on different nodes in your Kubernetes cluster. This can block the Longhorn Manager from accessing the webhook service, resulting in the CrashLoopBackOff state.

Please ensure that the pods on all nodes are able to communicate with each other. This can be verified by checking the firewall rules and ensuring that inter-pod communication is not blocked.

### Root Cause 2: DNS Doesn't Work Correctly

If DNS resolution is not functioning as expected, the Longhorn Manager may be unable to reach the webhook service by its DNS name. This is particularly important when accessing services through their internal Kubernetes DNS names.

Please ensure that the dns works by executing into a pod and test if DNS resolution works correctly by attempting to curl the webhook service:

```bash
kubectl exec -it <pod-name> -- /bin/bash
curl https://longhorn-conversion-webhook.longhorn-system.svc:9501/v1/healthz
```

Or Please verify if the CoreDNS or kube-dns service is running correctly. For more details on how to check this, refer to the official Kubernetes documentation on [Debugging DNS Resolution](https://kubernetes.io/docs/tasks/administer-cluster/dns-debugging-resolution/) for more information.

### Root Cause 3: Hairpin Is Not Set Correctly

Hairpinning allows a pod to access itself using its Service IP. This is a common issue in single-node clusters but can also happen in a muti-node cluster, where a pod may fail to access services via the service's internal DNS name.

Please verify that the hairpin setting is enabled. The hairpin setting ensures that a pod can access itself via its Service IP. You can refer to the official Kubernetes documentation [Edge case: A Pod fails to reach itself via the Service IP](https://kubernetes.io/docs/tasks/debug/debug-application/debug-service/#a-pod-fails-to-reach-itself-via-the-service-ip) for more information on hairpinning in the cluster.

## Related Information

* Longhorn issue: [#8293](https://github.com/longhorn/longhorn/issues/8293)