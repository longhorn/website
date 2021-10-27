---
title: "Troubleshooting: DNS Resolution Failed"
author: JenTing Hsiao
draft: false
date: 2021-10-26
categories:
  - "dns"
---

## Applicable versions

All Longhorn versions.

## Symptoms

The longhorn-driver-deployer or longhorn-csi-plugin or longhorn-ui Pods unable to access the longhorn manager backend http://longhorn-backend:9500/v1.

## Reason

The CoreDNS of the Kubernetes cluster is unable to resolve the longhorn-backend service, causing the DNS resolution to fail.

## Solution

1. Check the longhorn-backend Service is available.
   ```shell
   kubectl get service longhorn-backend -n longhorn-system
   ```
2. Make sure the longhorn-manager Pod(s) is/are up and running.
   ```shell
   kubectl get pod -l app=longhorn-manager -n longhorn-system
   ```
3. Make sure the CoreDNS Pod(s) is/are up and running.
   ```shell
   kubectl get pod -n kube-system
   ```
4. SSH into one of the longhorn-manager Pod, and check the nslookup test result, to make sure the DNS resolution result.
   ```shell
   kubectl exec -it <longhorn-manager-pod-name> -- nslookup longhorn-backend
   ```
5. If you're using k3s _or_ rke2, add
   ```shell
   K3S_RESOLV_CONF=/etc/resolv.conf
   RKE2_RESOLV_CONF=/etc/resolv.conf
   ```
   to k3s _or_ rke2 env files on all nodes, then restart the k3s _or_ rke2 server/agent service.
6. If you're not using k3s _or_ rke2, check the [Kubernetes DNS Resolution Known Issues](https://kubernetes.io/docs/tasks/administer-cluster/dns-debugging-resolution/#known-issues) to see how to set kubelet's `--resolv-conf` flag to point to the correct `resolv.conf`.

## Related information

- Longhorn issue comment: https://github.com/longhorn/longhorn/issues/3109#issuecomment-938471504
