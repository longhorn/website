---
title: Configurable CPU Cores
weight: 20
aliases:
- /spdk/features/configurable-cpu-cores.md
---

Longhorn now supports configurable CPU cores for the V2 data engine through the use of a **CPU Mask**. This mask allows you to define exactly which CPU cores are allocated to the engine, offering both global and per-node configuration options.

## Understanding the CPU Mask

The CPU mask is a **hexadecimal (hex) representation of a binary bitmask**, where each bit corresponds to a specific CPU core.

- A bit set to **1** means the core is enabled for the data engine.
- A bit set to **0** means the core is skipped.

### How to Calculate the Mask

To determine the correct hex string, visualize your CPU cores as a sequence of bits from right to left:

| Desired No. of Cores | Binary Representation (Cores 3, 2, 1, 0) | Hexadecimal Value |
| --- | --- | --- |
| **1 Core**  | `0001` | **0x1** |
| **2 Cores** | `0011` | **0x3** |
| **3 Cores** | `0111` | **0x7** |
| **4 Cores** | `1111` | **0xF** |

**Example for 23 Cores**: To allocate 23 cores, you need 23 bits set to `1`.

- **Binary**: `111 1111 1111 1111 1111 1111`
- **Hexadecimal**: `0x7FFFFF`

> **Note**: Do not confuse the number of cores with the hex value. For instance, setting `0x4` (Binary `0100`) only enables **one** core (Core #2), whereas `0xF` (Binary `1111`) enables **four** cores.

## Global Configuration

To set CPU cores globally across the cluster, update the [`data-engine-cpu-mask`](../../../references/settings#data-engine-cpu-mask) setting.

1. Navigate to **Settings > General**.
2. Locate **Data Engine CPU Mask**.
3. Enter your calculated hex string (for example, `0xF`).

## Per-node Configuration

For node-specific CPU core allocation, update the `spec.dataEngineSpec.v2.cpuMask` field of the instance manager with a hexadecimal encoded string. By default, this value is empty, and the v2 data engine will use the global setting specified by `data-engine-cpu-mask`. When a per-node configuration is set, the v2 data engine will prioritize this value over the global setting for that specific node.

## Calculation Tools

You can use a [Binary to Hex Converter](https://www.rapidtables.com/convert/number/binary-to-hex.html) to help calculate your mask. Type a `1` for every core you wish to allocate and convert the resulting binary string to Hex.
