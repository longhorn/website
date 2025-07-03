---
title: "Troubleshooting: Mount Failure with XFS Filesystem"
authors:
- "Derek Su"
draft: false
date: 2025-07-03
versions:
- "all"
categories:
- "compatibility"
---

## Applicable versions

All Longhorn versions.

## Symptoms

PersistentVolumeClaims (PVCs) using XFS-formatted Longhorn volumes may fail to mount, causing pods to remain stuck in the `ContainerCreating` state. Attempting to manually mount the volume may result in errors such as:

```bash
wrong fs type, bad option, bad superblock on /dev/longhorn/<volume> missing codepage or helper program ...
```

Kernel logs (`dmesg`) may also display messages like:

```bash
[766396.293089] XFS (sdf): Superblock has unknown read-only compatible features (0x6) enabled.
[766396.293546] XFS (sdf): Attempted to mount read-only compatible filesystem read-write.
[766396.293548] XFS (sdf): Filesystem can only be safely mounted read only. 
```

These messages indicate that the filesystem cannot be safely mounted due to unsupported features.

## Reason

The issue is caused by a compatibility mismatch between the `xfsprogs` version inside the Longhorn manager pod (which is responsible for formatting volumes) and the Linux kernel version on the nodes where the volumes are mounted.

For example, Longhorn v1.7 and later includes a newer version of `xfsprogs` in the longhorn-manager pod that enables features such as checksums (CRC) and reflink (copy-on-write) by default. These features are not supported by older kernels, such as those in RHEL 7.

The following kernel log entry:

```bash
[766396.293089] XFS (sdf): Superblock has unknown read-only compatible features (0x6) enabled.
```

It shows that feature flags `0x6` are enabled, which correspond to the unsupported CRC and reflink features, leading to the mount failure.

### Workaround

You can resolve or avoid this issue by either of the following:
- Upgrade the Linux OS or kernel to a version that supports the required XFS features.
- Format volumes with compatible options by customising the StorageClass:
  ```yaml
  parameters:
    mkfsParams: "-m crc=0,finobt=0"
  ```
  This disables the CRC and finobt features, allowing the volume to be mounted on older kernels.

## Related information

- [Issue #11214](https://github.com/longhorn/longhorn/issues/11214)
