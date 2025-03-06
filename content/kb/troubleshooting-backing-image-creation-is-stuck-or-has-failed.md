---
title: "Troubleshooting: Backing Image Creation Is Stuck Or Has Failed"
authors:
- "Jack Lin"
draft: false
date: 2025-03-06
versions:
- "all"
categories:
- "backing image"
---

## Applicable versions

All Longhorn versions.

## Symptoms

When attempting to create a backing image in Longhorn, the process may either remain stuck indefinitely or fail without completing. This issue occurs consistently with certain image files.

## Root Cause

Longhorn utilizes Direct I/O by default when accessing backing images. Direct I/O requires that file sizes be aligned to the underlying storage block size, which is 512 bytes in Longhorn. If the image file size is not a multiple of 512 bytes, Longhorn returns an error and the preparation process may become stuck.

You may also see the following error in the backing-image-manager pod.

```
the file size xxxx should be a multiple of 512 bytes since Longhorn uses directIO by default.
```

## Workaround

To resolve this issue, convert the image file using the qemu-img command. The qemu-img convert operation automatically adjusts the image file size to align with 512-byte multiples. Use the following command to perform the conversion:

```sh
qemu-img convert -O qcow2 fackvm.qcow2 fackvm-fixed.qcow2
```

Replace fackvm.qcow2 with the name of your original image file, and fackvm-fixed.qcow2 with the desired name for the fixed image file. Once the conversion is complete, use the newly converted image file as the backing image in Longhorn.

## Related Information

* Longhorn issue: [#10536](https://github.com/longhorn/longhorn/issues/10536)