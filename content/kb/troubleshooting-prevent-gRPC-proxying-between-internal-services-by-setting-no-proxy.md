---
title: "Troubleshooting: Prevent gRPC Proxying Between Internal Services by Setting NO_PROXY"
authors:
- "Sushant Gaurav"
draft: false
date: 2026-03-30
versions:
- All
categories:
- "troubleshooting"
- "network"
- "proxy"
---

## Applicable versions

**Confirmed working with**:

- Longhorn `v1.10.1` and later (contains gRPC code-level fixes)

**Potentially applicable to**:

- All Longhorn versions running in proxied Kubernetes environments (MicroK8s, RKE2, etc.)

## Symptoms

When Longhorn is installed in a cluster where a global proxy (for example, `HTTP_PROXY`, `HTTPS_PROXY`) is configured at the container runtime or OS level, you may encounter the following issues:

- **Replica Failures**: Replica rebuilding, cloning, or restoration tasks fail with `rpc error: code = Unavailable desc = connection error`.
- **Proxy Header Errors**: Logs in `longhorn-manager` showing `Invalid header received from client`. This typically happens when a proxy (like Privoxy or Squid) receives non-HTTP gRPC traffic and rejects it.
- **Backup Failures**: Restoration from backup targets (NFS or S3) failing due to traffic being routed to an external gateway instead of internal endpoints.

Example error log:
```text
replica pvc-xxxx-r-xxxx failed to get replica: rpc error: code = Unavailable desc = connection error: desc = "transport: Error while dialing: failed to do connect handshake, response: \"HTTP/1.1 400 Invalid header received from client\""
```

## Reason

Longhorn services communicate via gRPC. In environments with a global proxy, this internal traffic may be incorrectly routed through the proxy server.

While recent Longhorn versions include `grpc.WithNoProxy()` in the backend code, some traffic paths (such as inter-pod HTTP calls for backing image managers or health checks) and older versions of Longhorn still rely on environment variables. If the `NO_PROXY` variable is missing or incomplete, internal gRPC/HTTP traffic "escapes" the cluster, leading to connection resets by the proxy.

## Implementation

To ensure stable internal communication, you must explicitly exclude Kubernetes internal traffic from the proxy by configuring the `NO_PROXY` environment variable.

### 1. Identify your Cluster CIDRs

There is no "one-size-fits-all" string. You must include your specific cluster ranges.

  - **Service CIDR**: (for example, `10.96.0.0/12`)
  - **Pod CIDR**: (for example, `10.244.0.0/16`)

### 2. Configure via Helm (Recommended)

If you use Helm, update your `values.yaml` to inject the environment variables into the Longhorn Manager and related components.

```yaml
manager:
  env:
    - name: NO_PROXY
      value: "localhost,127.0.0.1,<SERVICE_CIDR>,<POD_CIDR>,.svc,.cluster.local"
```

### 3. Configure via Longhorn Settings

For components managed dynamically by Longhorn (like `instance-manager` pods), ensure that the proxy settings are consistent:

1. Navigate to Longhorn UI > Settings > General.
2. If using a proxy for backups, ensure the Proxy Secret is configured.
3. For manual overrides, ensure the `longhorn-manager` DaemonSet environment variables are set; newly created pods (including `instance-manager` pods) will inherit these settings.

### 4. Golden String Template

The `NO_PROXY` value should ideally look like this: `localhost,127.0.0.1,<K8S_SERVICE_CIDR>,<K8S_POD_CIDR>,.svc,.cluster.local`

## Verification

1.  Exec into a `longhorn-manager` pod:
    ```bash
    kubectl exec -n longhorn-system -it <longhorn-manager-pod-name> -- env | grep -i PROXY
    ```
2.  Verify that the `NO_PROXY` value contains your Pod and Service CIDRs.
3.  Test replica rebuilding or cloning to ensure the `Unavailable` gRPC errors no longer occur.

## Related Information

- Longhorn [Issue](https://github.com/longhorn/longhorn/issues/12522).
- Related [Bug Report](https://github.com/longhorn/longhorn/issues/12304).
