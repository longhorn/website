---
title: Instance Manager Pods During Upgrade
weight: 4
---

After a live upgrade, you may notice that some **old instance manager pods** are still running. This is expected behavior and **not a bug**.

## Why This Happens

Longhorn uses the following strategy to manage instance manager pods during a live upgrade:

- Old instance manager pods are cleaned up immediately once no engine or replica processes are running in them.
- During a **live engine upgrade** of a volume:
  - Replica processes are re-created in new instance manager pods using the upgraded engine image.
  - To avoid interrupting I/O, Longhorn cannot start a new engine process using the upgraded engine image in a new instance manager pod while the volume is attached. Instead, the old instance manager pod continues to manage the lifecycle of the new engine process until the volume is detached. As a result, the new engine process runs in the old instance manager pod.

As a result, an old instance manager pod remains running as long as it hosts an active engine process. Once the volume is detached and no engine or replica processes remain, Longhorn will automatically clean up the old instance manager pod.

## How to Check Which Volumes Are Using Old Instance Manager Pods

You can check which volumes are still using the old instance manager pods from the Longhorn UI:

- Navigate to **Volume** > **Name** > **Volume Details** > **Instance Manager**.

## How to Fully Clean Up Old Instance Manager Pods

To allow Longhorn to clean up all old instance manager pods:

1. Detach all volumes that are still using old instance manager pods.
2. Once no engine or replica processes remain, Longhorn will automatically remove the old instance manager pods.
