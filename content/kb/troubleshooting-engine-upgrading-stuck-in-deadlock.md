---
title: "Troubleshooting: Upgrading volume engine is stuck in deadlock"
author: Phan Le
draft: false
date: 2022-01-03
categories:
- "Longhorn Upgrade"
---

## Applicable versions

This happens when users upgrade Longhorn from version <= v1.1.1 to a newer version.

## Symptoms

[Upgrading Longhorn system](https://longhorn.io/docs/1.2.3/deploy/upgrade/) includes 2 steps: first upgrade Longhorn manager to the latest version,
then upgrade the Longhorn engine to the latest version using the latest Longhorn manager.
When doing the second step (upgrading Longhorn engine), you may hit the problem that some volumes are stuck in engine upgrading.
You may also see that volume attachment/detachment cannot finish (e.g., Longhorn volumes are stuck in detaching or attaching state).

## Reason

There is a bug Longhorn version <= v1.1.1 which leads to a deadlock in the instance manager pods.
See more details at https://github.com/longhorn/longhorn/issues/2697.
When you upgrade Longhorn from version <= v1.1.1 to a newer version, you may hit this bug in a cluster with a few hundred volumes.

## Solution

### Prevent the deadlock from happening

We fixed this bug in Longhorn version >= v1.1.2.
If you are planning to upgrade Longhorn to a version >= v1.1.2, you can follow the following steps to avoid the bug:

1. If you have enabled the [Automatically Upgrading Longhorn Engine](https://longhorn.io/docs/1.2.3/deploy/upgrade/auto-upgrade-engine/), please disable it.
1. Upgrade Longhorn manager as normal. See https://longhorn.io/docs/1.2.3/deploy/upgrade/longhorn-manager/
1. At this moment, there will be 2 different instance-manager versions running side by side in your cluster (1 pod for the old version and 1 new pod for the new version).
   The engine/replica processes will continue to live inside the old instance-manager pods.
1. Now, we want to make each Longhorn volume going through attach/detach cycle.
   Longhorn will stop the engine/replica processes in the old pods and start them on the new instance-manager pods when the volumes are reattached.
   You can trigger this by draining each node that is having Longhorn volumes attaching to it.
   The drain command should have flags so it only drains the appropriate workload but not Longhorn components.
   For example, this drain command skips Longhorn components `kubectl drain --pod-selector='!longhorn.io/component,app!=csi-attacher,app!=csi-provisioner,app!=csi-snapshotter,app!=csi-resizer,app!=longhorn-driver-deployer,app!=longhorn-ui' <NODE-NAME> --ignore-daemonsets`
1. After all volumes' engine/replica processes move to the new instance-manager pods, Longhorn will delete the old instance-manager pods.
1. Wait until the old instance manager pods are deleted by Longhorn.
1. Follow the steps [here](https://longhorn.io/docs/1.2.3/deploy/upgrade/auto-upgrade-engine/) to upgrade Longhorn engine.

### How to recover from the deadlock when it happens

1. Stop upgrading Longhorn engine upgrade.
   If you have enabled the [Automatically Upgrading Longhorn Engine](https://longhorn.io/docs/1.2.3/deploy/upgrade/auto-upgrade-engine/), please disable it.
1. Find the instance managers that are stuck in deadlock by:
    1. Find the IPs of `instance-manager-e-xxxxxxxx` pods inside `longhorn-system` namespace.
       Let's call it `INSTANCE-MANAGER-IP`.
    1. Exec into one of the `longhorn-manager-xxxxx` pod inside `longhorn-system` namespace.
    1. Run the following command to find the stuck instance manager pod:
        ```bash
        # Install grpcurl
        apt-get update
        apt-get install -y wget
        wget https://github.com/fullstorydev/grpcurl/releases/download/v1.8.0/grpcurl_1.8.0_linux_x86_64.tar.gz
        tar -zxvf grpcurl_1.8.0_linux_x86_64.tar.gz
        mv grpcurl /usr/local/bin/
        # Call instance manager gRPC APIs
        wget https://raw.githubusercontent.com/longhorn/longhorn-instance-manager/master/pkg/rpc/rpc.proto
        wget https://raw.githubusercontent.com/grpc/grpc/master/src/proto/grpc/health/v1/health.proto
        # check the health of grpc server on the instance manager instance-manager-e-f386c595
        grpcurl -d '' -plaintext -import-path ./ -proto health.proto <INSTANCE-MANAGER-IP>:8500 grpc.health.v1.Health/Check
        # Server returns "status": "SERVING"
        grpcurl -d '' -plaintext -import-path ./ -proto rpc.proto <INSTANCE-MANAGER-IP>:8500 ProcessManagerService/ProcessList
        # If the server never returns response, this is a stuck instance manager pod
        ```
1. Find the node of the stuck instance manager pod.
   Scale down all workload pods that are using Longhorn volumes on the node.
   All volumes on the node will be stuck in detaching state.
1. Kill the stuck instance manager pod
1. Scale up the workload pods
1. Once you get out of the deadlock state, follow the steps at [Prevent the deadlock from happening](#prevent-the-deadlock-from-happening) to finish upgrading Longhorn.

## Related information

- Longhorn issue comment: https://github.com/longhorn/longhorn/issues/2697
