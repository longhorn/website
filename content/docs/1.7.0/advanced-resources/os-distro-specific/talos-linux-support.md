---
title:  Talos Linux Support
weight: 5
---

## Requirements

You must meet the following requirements before installing Longhorn on a Talos Linux cluster.

### System Extensions

Some Longhorn-dependent binary executables are not present in the default Talos root filesystem. To have access to these binaries, Talos offers system extension mechanism to extend the installation.

- `siderolabs/iscsi-tools`: this extension enables iscsid daemon and iscsiadm to be available to all nodes for the Kubernetes persistent volumes operations.
- `siderolabs/util-linux-tools`: this extension enables linux tool to be available to all nodes. For example, the `fstrim` binary is used for Longhorn volume trimming.

The most straightforward method is patching the extensions onto existing Talos Linux nodes.

```yaml
customization:
  systemExtensions:
    officialExtensions:
      - siderolabs/iscsi-tools
      - siderolabs/util-linux-tools
```

For detailed instructions, see the Talos documentation on [System Extensions](https://www.talos.dev/v1.6/talos-guides/configuration/system-extensions/) and [Boot Assets](https://www.talos.dev/v1.6/talos-guides/install/boot-assets/).

### Pod Security

Longhorn requires pod security `enforce: "privileged"`.


By default, Talos Linux applies a `baseline` pod security profile across namespaces, except for the kube-system namespace. This default setting restricts Longhorn's ability to manage and access system resources. For more information, see [Root and Privileged Permission](../../../deploy/install/#root-and-privileged-permission).

For detailed instructions, see [Pod Security Policies Disabled & Pod Security Admission Introduction](../../../deploy/important-notes/#pod-security-policies-disabled--pod-security-admission-introduction) and Talos' documentation on [Pod Security](https://www.talos.dev/v1.6/kubernetes-guides/configuration/pod-security/).

### Data Path Mounts

You need provide additional data path mounts to be accessible to the Kubernetes Kubelet container.

These mount is necessary to provide access to the host directories and attaching volumes required by the Longhorn components.

```yaml
machine:
  kubelet:
    extraMounts:
      - destination: /var/lib/longhorn
        type: bind
        source: /var/lib/longhorn
        options:
          - bind
          - rshared
          - rw
```

For detailed instructions, see the Talos documentation on [Editing Machine Configuration](https://www.talos.dev/v1.6/talos-guides/configuration/editing-machine-configuration/).

## Limitations

- Exclusive to v1 data volume: currently, within a Talos Linux cluster, Longhorn only supports v1 data volume. The v2 data volume isn't currently supported in this environment.

## References

- [[FEATURE] Talos support](https://github.com/longhorn/longhorn/issues/3161)