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

- Longhorn versions `v1.10.1` and prior running in clusters with global `HTTP_PROXY`/`HTTPS_PROXY` settings.

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

## Root Cause Analysis

Longhorn services utilize gRPC for inter-component communication (Manager to Instance Manager). By default, gRPC clients honor environment-level proxy variables (`HTTPS_PROXY`). 

In a proxied cluster, if `NO_PROXY` does not explicitly exclude the Pod and Service CIDRs, gRPC traffic is sent to the external proxy. Because most standard HTTP proxies cannot handle raw gRPC handshakes, the connection is rejected, leading to volume "Faulted" states.

## Resolution and Requirements

### 1. Upgrade to v1.10.2+ (Recommended)

Starting from version `v1.10.2`, Longhorn has introduced `grpc.WithNoProxy()` across all internal gRPC clients. This forces internal traffic to bypass environment proxy settings automatically, removing the need for manual `NO_PROXY` overrides for gRPC-based operations.

### 2. Manual Configuration for v1.10.1 and Prior

For users on older versions, or for traffic paths not covered by gRPC (such as certain BackupStore HTTP calls), the `NO_PROXY` variable must be correctly configured to include the internal cluster infrastructure:

- **Required Suffixes**: `localhost,127.0.0.1,.svc,.cluster.local`
- **Required Network Ranges**: Both the **Pod CIDR** and **Service CIDR** must be included. Suffixes alone are often insufficient for Pod-to-Pod IP communication.

Example Template:

```bash
NO_PROXY="localhost,127.0.0.1,<SERVICE_CIDR>,<POD_CIDR>,.svc,.cluster.local"
```

### 3. Backup Target Proxy Settings

Regardless of version, ensure that the **Proxy Secret** under **Settings > General** is correctly configured if your backup target requires an external proxy but your cluster communication must remain internal.

## Related Information

- Longhorn [Issue](https://github.com/longhorn/longhorn/issues/12522).
- Related [Bug Report](https://github.com/longhorn/longhorn/issues/12304).
