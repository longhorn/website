---
title: Command Line Tool (longhornctl)
description: Command line interface (CLI) for Longhorn operations and troubleshooting.
weight: 8
---

The `longhornctl` tool is a CLI interface to Longhorn operations. It interacts with Longhorn by creating Kubernetes Custom Resources (CRs) and executing commands inside a dedicated Pod for in-cluster and host operations.

## Common usage scenarios

* **Installation:**
  * `longhornctl install preflight`: Perform preflight dependencies installation and setup before installing Longhorn.
* **Operations:**
  * `longhornctl export replica`: Extract data from a Longhorn replica data directory to a designated directory on its host machine. This is useful for recovering data when Longhorn is unavailable.
  * `longhornctl trim volume`: Reclaim unused storage space within a Longhorn volume.
* **Troubleshooting:**
  * `longhornctl check preflight`: Identifies potential issues before usage.
  * `longhornctl get replica`: Retrieve details about Longhorn replicas on the host.

## Usage

For more information about the available commands, see [this document](https://github.com/longhorn/cli/tree/{{< current-version >}}/docs/longhornctl.md) in the GitHub repository, or run `longhornctl help` in your terminal.
