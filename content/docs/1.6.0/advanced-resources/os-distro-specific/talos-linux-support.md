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

These mounts are necessary to provide access to the host directories, and attach volumes required by Longhorn components.

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

## Talos Linux Upgrades

When [upgrading a Talos Linux node](https://www.talos.dev/v1.7/talos-guides/upgrading-talos/#talosctl-upgrade), always include the `--preserve` option in the command. This option explicitly tells Talos to keep ephemeral data intact.

Example:

```
talosctl upgrade --nodes 10.20.30.40 --image ghcr.io/siderolabs/installer:v1.7.6 --preserve
```

> **Caution:**
> If you do not include the `--preserve` option, Talos wipes `/var/lib/longhorn`, destroying all replicas stored on that node.

### Recovering from an Upgraded Node without Preserving Data

If you were unable to include the `--preserve` option in the upgrade command, perform the following steps:

1. On the Longhorn UI, go to the **Node** page.

1. Select the upgraded node, and then select **Edit node and disks** in the **Operation** menu.

1. On the **Edit Node and Disks** page, set **Scheduling** to **Disable**, delete the disk, and then click **Save**.

1. Select the upgraded node again, and then select **Edit node and disks** in the **Operation** menu.

1. On the **Edit Node and Disks** page, add a disk and configure the following settings:

    - **Path**: Specify `/var/lib/longhorn/`.
    - **Storage Reserved**: Specify a value that matches your requirements. The default value is **30 Gi**. 
    - **Scheduling**: Select **Enable**.

1. Click **Save**.

Longhorn synchronizes the replicas based on the configured settings.

## References

- [[FEATURE] Talos support](https://github.com/longhorn/longhorn/issues/3161)
