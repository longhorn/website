---
title: Install longhornctl
weight: 1
---

## Use the Prebuilt Binary

1. Download the binary:
   ```bash
   # Choose your architecture (amd64 or arm64).
   ARCH="amd64"

   # Download the release binary.
   curl -LO "https://github.com/longhorn/cli/releases/download/{{< current-version >}}/longhornctl-linux-${ARCH}"
   ```
1. Validate the binary:
   ```bash
   # Download the checksum for your architecture.
   curl -LO "https://github.com/longhorn/cli/releases/download/{{< current-version >}}/longhornctl-linux-${ARCH}.sha256"

   # Verify the downloaded binary matches the checksum.
   echo "$(cat longhornctl-linux-${ARCH}.sha256 | awk '{print $1}') longhornctl-linux-${ARCH}" | sha256sum --check
   ```
1. Install the binary:
   ```bash
   sudo install longhornctl-linux-${ARCH} /usr/local/bin/longhornctl
   ```
1. Verify installation:
   ```bash
   longhornctl version
   ```

## Build From Source

See [this document](https://github.com/longhorn/cli/tree/{{< current-version >}}?tab=readme-ov-file#build-from-source) in the GitHub repository.
