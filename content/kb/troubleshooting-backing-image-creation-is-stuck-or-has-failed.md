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

Backing image creation may either fail to complete or become stuck indefinitely when certain image files are used.

## Root Cause

By default, Longhorn uses direct I/O when accessing backing images. Direct I/O requires alignment of file sizes with the underlying storage block size, which is 512 bytes in Longhorn. If the source image size is not a multiple of 512 bytes, Longhorn returns an error and the backing image creation process may become stuck.

The backing-image-manager pod may return the following error message:

```
the file size xxxx should be a multiple of 512 bytes since Longhorn uses directIO by default.
```

## Workaround

To resolve this issue, convert the image file using the QEMU disk image utility (qemu-img). The `convert` option automatically adjusts the image size to align with 512-byte multiples. Run the following command to perform the conversion:

```sh
qemu-img convert -O qcow2 <source-image>.qcow2 <converted-image>.qcow2
```

You must first specify the file name of the source image, and then the preferred file name for the converted image. Once the conversion is completed, you can use the converted image as a backing image in Longhorn.

## Related Information

* Longhorn issue: [#10536](https://github.com/longhorn/longhorn/issues/10536)