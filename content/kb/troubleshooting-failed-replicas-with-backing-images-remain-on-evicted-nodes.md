---
title: "Troubleshooting: Failed Replicas with Backing Images Remain On Evicted Nodes"
authors:
- "Raphanus Lo"
draft: false
date: 2025-06-05
versions:
- "v1.9.0 and earlier versions"
categories:
- "longhorn manager"
---

## Applicable versions

v1.9.0 and earlier.

## Symptoms

After evicting a node, some volume replicas created from a backing image may enter an error state. Despite this, the associated volumes remain healthy.

## Root Cause

The issue occurs due to the unconditional deletion of backing image copies. If a backing image copy still in use is removed, its associated replica is forcibly shut down and marked as broken. This prevents the replica from being cleaned up during node eviction process.

## Workaround

To resolve this issue and maintain cluster stability, perform the following steps:

1. Wait for affected volumes to automatically schedule new replicas on other nodes and confirm the volumes return to a healthy state.
2. In the Node page, find the evicted node’s replica list and manually delete the failed replicas.

The processes tied to these replicas have already terminated. Data is safely synchronized to new replicas, and no orphaned backing images will remain.

## Fixed Versions

Longhorn v1.8.2+, v1.9.1+

## Reference

[GitHub Issue #11053](https://github.com/longhorn/longhorn/issues/11053)
