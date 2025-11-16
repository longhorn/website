---
title: Talos Linux Support
weight: 5
---

## Requirements

The following requirements must be met before installing Longhorn on a Talos Linux cluster.

### System Extensions

Some Longhorn-dependent binary executables are not present in the default Talos root filesystem. To have access to these binaries, Talos offers system extension mechanism to extend the installation.

- `siderolabs/iscsi-tools`: this extension enables iscsid daemon and iscsiadm to be available to all nodes for the Kubernetes persistent volumes operations.
- `siderolabs/util-linux-tools`: this extension enables linux tool to be available to all nodes. For example, the `fstrim` binary is used for Longhorn volume trimming.

The most straightforward method is to patch the extensions onto existing Talos Linux nodes. Alternatively, we can use the [Talos Linux Image Factory](https://factory.talos.dev/) and select the desired extensions under **System Extensions**. This approach is especially useful when combined with Infrastructure as Code (IaC) tools.

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

For detailed instructions, see [Pod Security Policies Disabled & Pod Security Admission Introduction](../../../../archives/1.7.0/important-notes/#pod-security-policies-disabled--pod-security-admission-introduction) and the Talos documentation on [Pod Security](https://www.talos.dev/v1.6/kubernetes-guides/configuration/pod-security/).

## From Talos Linux v1.10.x Onwards

### Data Path Mounts

Since Talos Linux deprecated `.machine.disks`, we recommend using `UserVolumeConfig` to mount a disk for Longhorn. See [What's new in Talos v1.10](https://www.talos.dev/v1.10/introduction/what-is-new/#user-volumes) for more details.

Optionally, we can also create a `VolumeConfig` to specify the size of Talos system volumes. This is **recommended**, as it avoids the need to set `defaultSettings.storageReservedPercentageForDefaultDisk`.

> For more disk configuration options, see the [Talos documentation](https://www.talos.dev/v1.10/talos-guides/configuration/disk-management/#disk-layout).

We must provide additional data path mounts to make them accessible to the Kubernetes Kubelet container.

These mounts allow access to host directories and attach the volumes required by Longhorn components.

The [default data path](../../../references/settings#default-data-path) for Longhorn is `/var/lib/longhorn`. To use the configuration below in Talos, first set your default data path to `/var/mnt/longhorn`. The method to do this depends on your [deployment method](../../deploy/customizing-default-settings).

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

Next, create a `UserVolumeConfig` to mount the disk for Longhorn. It will be automatically mounted to `/var/mnt/longhorn` on the configured node.

```yaml
apiVersion: v1alpha1
kind: UserVolumeConfig
name: longhorn # name is used to identify the volume /var/mnt/<name>
provisioning:
  diskSelector:
    match: disk.transport == "nvme"
  grow: false
  maxSize: 1700GB
```

For detailed instructions on `UserVolumeConfig` and `VolumeConfig`, see the Talos documentation on [Block configuration](https://www.talos.dev/v1.10/reference/configuration/block/). Refer to the [Talos API Reference](https://docs.siderolabs.com/talos/v1.11/reference/api) for more configuration details.

## Up to Talos Linux v1.9.x

### Data Path Mounts

We need to provide additional data path mounts to be accessible to the Kubernetes Kubelet container.

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
> Talos Linux v1.7.x and earlier versions do not include the `uio_pci_generic` kernel module. If the system device supports `vfio_pci`, which is the preferred kernel module for SPDK application deployment, we are not required to install and enable the `uio_pci_generic` kernel driver. For more information, see [System Configuration User Guide](https://spdk.io/doc/system_configuration.html) in the SPDK documentation.
>
> We can use `uio_pci_generic` if `vfio_pci` is incompatible with your system or specific hardware. Future versions of Talos Linux are expected to include native support for `uio_pci_generic`. For more information, see [Issue #9236](https://github.com/siderolabs/talos/issues/9236).
> Since 1.8.0 `uio_pci_generic` is now supported.

## Talos Linux Upgrades

### From v1.8.x Onwards

The `--preserve` flag is no longer required. It is now automatically set for the `talosctl` upgrade command, as noted [here](https://www.talos.dev/v1.8/introduction/what-is-new/#upgrades).

### Up to v1.8.x

When [upgrading a Talos Linux node](https://www.talos.dev/v1.7/talos-guides/upgrading-talos/#talosctl-upgrade), always include the `--preserve` option in the command. This option explicitly tells Talos to keep ephemeral data intact.

Example:

```
talosctl upgrade --nodes 10.20.30.40 --image ghcr.io/siderolabs/installer:v1.7.6 --preserve
```

> **Caution:**
> If the `--preserve` option is not included, Talos wipes `/var/lib/longhorn`, destroying all replicas stored on that node.

### Recovering from an Upgraded Node without Preserving Data

If we were unable to include the `--preserve` option in the upgrade command, perform the following steps:

1. On the Longhorn UI, go to the **Nodes** page.

1. Select the upgraded node, and then select **Edit node and disks** in the **Operation** menu.

1. On the **Edit Node and Disks** page, set **Scheduling** to **Disable**, delete the disk, and then click **Save**.

1. Select the upgraded node again, and then select **Edit node and disks** in the **Operation** menu.

1. On the **Edit Node and Disks** page, add a disk and configure the following settings:

   - **Path**: Specify `/var/lib/longhorn/`.
   - **Storage Reserved**: Specify a value that matches your requirements. By default, it is set to 30% of the disk capacity.
   - **Scheduling**: Select **Enable**.

1. Click **Save**.

Longhorn synchronizes the replicas based on the configured settings.

## References

- [[FEATURE] Talos support](https://github.com/longhorn/longhorn/issues/3161)
