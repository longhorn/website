---
title: "Troubleshooting: Longhorn Manager Stuck in CrashLoopBackOff State Due to Inaccessible Webhook"
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

The webhook services were merged into Longhorn Manager in v1.5.0. Because of the merge, Longhorn Manager now initializes the admission and conversion webhook services first during startup. To ensure that these services are accessible, Longhorn sends a request to the webhook service URL before starting the Longhorn Manager service.

In certain situations, the webhook service may become inaccessible and cause the Longhorn Manager pod to enter a CrashLoopBackOff state. This failure can lead to repeated attempts to restart the pod.

The following sections outline the most common root causes for this issue and their corresponding solutions.

### Root Cause 1: Misconfigured Firewall

Incorrect firewall configuration may block communication between pods on different nodes in your Kubernetes cluster. Longhorn Manager is unable to access the webhook service, resulting in the CrashLoopBackOff state.

Check your firewall rules and ensure that inter-pod communication is not blocked.

### Root Cause 2: DNS Resolution Issues

DNS resolution is crucial for accessing services via their internal Kubernetes DNS names. When DNS resolution is not functioning as expected, Longhorn Manager may be unable to reach the webhook service via its DNS name.

Execute the webhook service in a pod, and then check if DNS resolution is functioning correctly by running the following commands:

```bash
kubectl exec -it <pod-name> -- /bin/bash
curl https://longhorn-conversion-webhook.longhorn-system.svc:9501/v1/healthz
```

You can also check if either CoreDNS or Kube-DNS is running correctly. For more information, see [Debugging DNS Resolution](https://kubernetes.io/docs/tasks/administer-cluster/dns-debugging-resolution/) in the Kubernetes documentation.

### Root Cause 3: Hairpinning Not Implemented Correctly

Hairpinning allows a pod to access itself via its service IP. In some cases, however, a pod may fail to access a service via the service's internal DNS name. This issue is common in single-node clusters and may also occur in some multi-node clusters.

Verify that the `hairpin-mode` flag, which ensures that a pod can access itself via its service IP, is set correctly. For more information, see [Edge case: A Pod fails to reach itself via the Service IP](https://kubernetes.io/docs/tasks/debug/debug-application/debug-service/#a-pod-fails-to-reach-itself-via-the-service-ip) in the Kubernetes documentation.

## Related Information

* Longhorn issue: [#8293](https://github.com/longhorn/longhorn/issues/8293)