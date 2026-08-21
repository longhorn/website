---
title: "Troubleshooting: Volume attachment stuck due to CNI NetworkPolicies"
authors:
- "Raphanus Lo"
draft: false
date: 2026-08-21
versions:
- "1.12.1"
categories:
- "network"
- "network policy"
- "volume attachment"
---

## Applicable versions

Longhorn v1.12.1 with `networkPolicies.restrictInternalTraffic` enabled and a CNI that enforces Kubernetes `NetworkPolicy` resources. Longhorn v1.12.1 creates these internal policies by default. If the CNI does not enforce NetworkPolicy, this workaround is not needed for traffic filtering.

This article describes two independent traffic paths. Apply only the policy that matches the symptom and the networking features enabled in the cluster.

## Symptoms

### V1 volume attachment or detachment fails

* A V1 data-engine volume remains in `attaching`, or an engine remains in `starting`.
* Kubernetes reports a `FailedAttachVolume` or `FailedMount` event, or a detach operation does not finish.
* The instance-manager log contains iSCSI discovery or login timeouts, `No route to host`, or a failed connection to TCP port `3260`.
* The CNI verdict or flow log shows the node's host-originated connection denied when it connects to the instance-manager pod on TCP port `3260`. The source may be reported with a CNI-specific identity such as `world`.

### RWX recovery fails with Istio Ambient

* A ReadWriteMany (RWX) volume cannot complete recovery and its share-manager pod does not become ready.
* The share-manager log reports a failed recovery-backend request, such as a failed HTTP client operation during NFS server startup.
* Istio Ambient `ztunnel` logs show a timeout for the HBONE tunnel to the Longhorn recovery backend on TCP port `15008`.

The RWX symptom is specific to a mesh transport that tunnels the request through TCP port `15008`. It is separate from the V1 iSCSI host-origin problem above.

## Root cause and impact on Longhorn

### V1 iSCSI traffic originates from the node

For the V1 data engine, the node's kernel iSCSI initiator connects to the instance-manager iSCSI target. The initiator runs from the host network namespace; it is not a pod selected by the v1.12.1 instance-manager policy. A NetworkPolicy-enforcing CNI can therefore deny the connection even though Longhorn manager and instance-manager pods are healthy.

The source address evaluated by the CNI is implementation- and topology-specific. For example, a Cilium verdict may show a host-routing source such as `169.254.7.127`. The Cilium example CIDR `169.254.0.0/16` in the workaround below is not a portable Longhorn or Kubernetes default. Do not copy it unless the CNI verdict or flow logs for your cluster show that it is the effective source range for the host iSCSI initiators. A pod CIDR, service CIDR, or node CIDR is not a substitute for the source observed by the CNI.

### Istio Ambient tunnels the RWX recovery request

The default recovery-backend policy permits the share-manager pod to reach the recovery-backend application on TCP port `9503`. Istio Ambient first carries that pod-to-pod connection through an HBONE tunnel on TCP port `15008`. The destination policy can deny the tunnel before the request reaches the recovery-backend application, so share-manager recovery fails even though TCP port `9503` is allowed.

This extra port is needed only when the deployed mesh actually uses TCP port `15008` for this path. Do not add it to a cluster without that mesh transport.

### CSI sidecars do not need manager ingress

The CSI sidecar pods communicate with the `longhorn-csi-plugin` pods over the Unix socket at `<kubelet-directory>/plugins/driver.longhorn.io/csi.sock`. The CSI plugin then communicates with `longhorn-manager` over its normal network endpoint. The workaround therefore does not add CSI sidecar sources to a manager ingress policy; no direct CSI sidecar-to-manager ingress is required for this issue.

## Workaround for Longhorn v1.12.1

These are additive policies. They supplement the policies installed by Longhorn and do not replace or modify the Helm-managed policies. Save the following YAML, change the example CIDR if your CNI reports a different effective source, and apply it in the `longhorn-system` namespace. If Longhorn is installed in another namespace, replace `longhorn-system` in the manifests and commands. If only one symptom applies, remove the other YAML document before applying so that you grant only the required access.

```yaml
# Use this CIDR only when CNI verdict or flow logs show that it is the
# effective source range for the node-hosted V1 iSCSI initiators.
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: longhorn-instance-manager-v1-iscsi
  namespace: longhorn-system
spec:
  podSelector:
    matchLabels:
      longhorn.io/component: instance-manager
  policyTypes:
  - Ingress
  ingress:
  - from:
    - ipBlock:
        cidr: 169.254.0.0/16
    ports:
    - protocol: TCP
      port: 3260
---
# Apply this policy only when Istio Ambient or another applicable mesh
# transport uses TCP/15008 for share-manager to recovery-backend traffic.
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: longhorn-recovery-backend-mesh
  namespace: longhorn-system
spec:
  podSelector:
    matchLabels:
      longhorn.io/recovery-backend: longhorn-recovery-backend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          longhorn.io/component: share-manager
    ports:
    - protocol: TCP
      port: 15008
```

Apply the saved file, for example:

```
kubectl apply -f longhorn-cni-networkpolicy-workaround.yaml
```

### Choose the V1 source CIDR carefully

1. Use the CNI's policy verdict or flow observability tool while reproducing the V1 attachment failure.
2. Find the denied TCP SYN from the node-hosted iSCSI initiator to the instance-manager pod IP and TCP port `3260`.
3. Record the source address after the CNI's source translation and policy classification. Repeat this on every node that can host a V1 volume workload, including failover destinations.
4. Use the narrowest set of CIDRs that covers those observed sources. Use individual host prefixes where the CNI presents stable individual addresses; use a range only when the CNI uses a range for the host path.

`169.254.0.0/16` is an example for the reported Cilium setup, where a source such as `169.254.7.127` was observed. It is not a universal Cilium, Kubernetes, or Longhorn value. An `ipBlock` cannot express that the source must be the same node as the destination pod, so a broad range increases the set of clients that can reach TCP `3260`. Keep the range narrow and review it after changing the CNI, routing, node addressing, or topology.

The recovery-backend policy is narrower: it allows only the `share-manager` pod selector to the recovery-backend pod selector on TCP `15008`. It does not open the application port `9503` to other sources, and it does not add access for CSI sidecars.

NetworkPolicy is additive, but a CNI can also enforce egress policy. If the source pods are isolated by egress policies, confirm that their egress rules also permit the corresponding destination and port.

## Verification

After applying the policies:

1. Confirm that both supplemental policies exist only in `longhorn-system`:

   ```
   kubectl get networkpolicy -n longhorn-system \
     longhorn-instance-manager-v1-iscsi longhorn-recovery-backend-mesh
   ```

2. Re-check the CNI verdict or flow log. The V1 host-originated connection to the selected instance-manager pod on TCP `3260` should be allowed. For an Ambient deployment, the share-manager-to-recovery-backend tunnel on TCP `15008` should be allowed.
3. Retry the affected V1 volume attachment or detachment and confirm that the volume and engine leave the stuck state. Check the instance-manager logs for a successful iSCSI discovery or login and no new NetworkPolicy denial.
4. If the RWX symptom applies, retry recovery and confirm that the share-manager pod becomes ready. Check the share-manager and Ambient proxy logs for a successful recovery-backend connection.

If the CNI still denies the flow, do not widen the policy blindly. Re-check the destination pod labels, effective source address, source egress policy, mesh transport port, and whether the connection is using the expected node or pod path.

## Rollback and upgrade transition

To remove only the supplemental policies on v1.12.1, run:

```
kubectl delete networkpolicy -n longhorn-system \
  longhorn-instance-manager-v1-iscsi longhorn-recovery-backend-mesh
```

This does not remove Longhorn's Helm-managed policies. Removing the V1 policy can restore the original attachment failure, and removing the recovery policy can restore the Ambient RWX recovery failure, so delete each policy only after the corresponding traffic path is no longer needed.

Longhorn v1.12.2 and later provide Helm values for these paths. Configure the V1 source CIDRs using the value that matches your CNI, and configure the recovery-backend port only for an applicable mesh transport:

```yaml
networkPolicies:
  v1DataEngineInitiatorSourceCIDRs:
    - 169.254.0.0/16
  recoveryBackendAdditionalIngressPorts:
    - 15008
```

The `169.254.0.0/16` entry remains only an example for the reported Cilium source range; derive the value from your own CNI observations. In v1.12.2 and later:

* An empty `v1DataEngineInitiatorSourceCIDRs` list leaves the generated TCP `3260` rule without source filtering. Any source that can reach an instance-manager pod can then connect to TCP `3260`; an empty list does not deny all sources. Set explicit observed CIDRs when least-privilege filtering is required.
* An empty `recoveryBackendAdditionalIngressPorts` list adds no mesh ports. The default share-manager access to TCP `9503` remains, but TCP `15008` is not allowed unless it is listed.
* `recoveryBackendAdditionalIngressPorts` should contain `15008` only when Istio Ambient or another deployed mesh transport uses that port for this recovery path.

During the upgrade, add the values to the Helm release before removing the corresponding supplemental policy. Render or inspect the resulting policies and verify the CNI flows. Once the Helm-managed policies contain the equivalent allowed paths, remove the v1.12.1 supplemental policies. If the upgrade is rolled back to v1.12.1, restore the supplemental policies as needed.

## Related information

* [Longhorn issue #13802](https://github.com/longhorn/longhorn/issues/13802)
* [Longhorn Network Policies](../../docs/1.12.1/advanced-resources/security/network-policy)
* [Longhorn Networking reference](../../docs/1.12.1/references/networking)
