---
title: Talos Linux Support
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

For detailed instructions, see [Pod Security Policies Disabled & Pod Security Admission Introduction](../../../../1.7.0/important-notes/#pod-security-policies-disabled--pod-security-admission-introduction) and the Talos documentation on [Pod Security](https://www.talos.dev/v1.6/kubernetes-guides/configuration/pod-security/).

## Talos Linux Version Prior to v1.10.x

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

## V2 Data Engine

To use V2 volumes, all nodes must meet the V2 Data Engine [prerequisites](../../../v2-data-engine/prerequisites#prerequisites).

```yaml
machine:
  sysctls:
    vm.nr_hugepages: "1024"
  kernel:
    modules:
      - name: nvme_tcp
      - name: vfio_pci
#     - name: uio_pci_generic
```

> **Note:**
> Talos Linux v1.7.x and earlier versions do not include the `uio_pci_generic` kernel module. If your system device supports `vfio_pci`, which is the preferred kernel module for SPDK application deployment, you are not required to install and enable the `uio_pci_generic` kernel driver. For more information, see [System Configuration User Guide](https://spdk.io/doc/system_configuration.html) in the SPDK documentation.
>
> You can use `uio_pci_generic` if `vfio_pci` is incompatible with your system or specific hardware. Future versions of Talos Linux are expected to include native support for `uio_pci_generic`. For more information, see [Issue #9236](https://github.com/siderolabs/talos/issues/9236).
> Since Talos 1.8.0 `uio_pci_generic` is now supported.

## Talos Linux Upgrades

### Prior to v1.8.x

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
   - **Storage Reserved**: Specify a value that matches your requirements. By default, it is set to 30% of the disk capacity.
   - **Scheduling**: Select **Enable**.

1. Click **Save**.

Longhorn synchronizes the replicas based on the configured settings.

### After v1.8.x

The `--preserve` is no longer required. The flag is automatically set for `talosctl upgrade` command. [here](https://www.talos.dev/v1.8/introduction/what-is-new/#upgrades)

## Talos Linux Version v1.10.x and Later

### Data Path Mounts

Because Talos Linux deprecated `.machine.disks` we recommend using `UserVolumeConfig` to mount a disk for Longhorn. See the [What's new in Talos v1.10](https://www.talos.dev/v1.10/introduction/what-is-new/#user-volumes) for more details.

You can optionally create also a `VolumeConfig` to specify the size of Talos System volumes, which is _recommended_, like this we avoid the set `defaultSettings.storageReservedPercentageForDefaultDisk`.

> More options of disk configuration can be found in the [Talos documentation](https://www.talos.dev/v1.10/talos-guides/configuration/disk-management/#disk-layout).

You need provide additional data path mounts to be accessible to the Kubernetes Kubelet container.

These mounts are necessary to provide access to the host directories, and attach volumes required by Longhorn components.

```yaml
machine:
  kubelet:
    extraMounts:
      - destination: /var/mnt/longhorn
        type: bind
        source: /var/mnt/longhorn
        options:
          - bind
          - rshared
          - rw
```

You need to create a `UserVolumeConfig` to mount the disk for Longhorn, which will be automatically mounted to `/var/mnt/longhorn` on the configured node.

```
apiVersion: v1alpha1
kind: UserVolumeConfig
name: longhorn # name is used to identify the volume /var/mnt/<name>
provisioning:
  diskSelector:
    match: disk.transport == "nvme"
  grow: false
  maxSize: 1700GB
```

For detailed instructions on `UserVolumeConfig` and `VolumeConfig`, see the Talos documentation on [Block configuration](https://www.talos.dev/v1.10/reference/configuration/block/)

## References

- [[FEATURE] Talos support](https://github.com/longhorn/longhorn/issues/3161)
