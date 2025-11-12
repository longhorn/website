---
title: Configurable CPU Cores
weight: 20
aliases:
- /spdk/features/configurable-cpu-cores.md
---

Longhorn now supports configurable CPU cores for the v2 data engine, offering both global and per-node configuration options.

## Global Configuration

To set CPU cores globally, update the [data-engine-cpu-mask](../../../references/settings#data-engine-cpu-mask) setting using a hexadecimal encoded string. For example:

- Use 0x01 to allocate 1 core
- Use 0x03 to allocate 2 cores
- Use 0x07 to allocate 3 cores

## Per-node Configuration

For node-specific CPU core allocation, update the `spec.dataEngineSpec.v2.cpuMask` field of the instance manager with a hexadecimal encoded string. By default, this value is empty, and the v2 data engine will use the global setting specified by `data-engine-cpu-mask`. When a per-node configuration is set, the v2 data engine will prioritize this value over the global setting for that specific node.
