---
title: "Troubleshooting: Migratable RWX volume migration stuck"
authors:
- "Raphanus Lo"
draft: false
date: 2025-06-23
versions:
- "all"
categories:
- "Migratable RWX volume"
---

## Applicable versions

**Confirmed working with**:

- Longhorn `v1.7.3`

**Potentially applicable to**:

- Any Longhorn version
- Various Linux distributions and versions

## Symptoms

During the VM platform node pre-drain stage, the migration of a Longhorn Migratable RWX volume is triggered. Although the engine and replicas on the destination node are ready, the node becomes stuck in the pre-drain stage.

Example volume state:

```yaml
Volume: pvc-abcdefg
  spec.nodeID: s1
  status:
    robustness: degraded
    state: attached

  Engine:
    name: pvc-abcdefg-e-1
    spec.nodeID: s1
    status:
      currentState: running
      currentReplicaAddressMap:
        - pvc-abcdefg-r-5d917bb3: 10.52.8.201:11840
        - pvc-abcdefg-r-fe42a309: 10.52.2.101:11812

    name: pvc-abcdefg-e-2
    spec.nodeID: t2
    status:
      currentState: running
      currentReplicaAddressMap:
        - pvc-abcdefg-r-3f99a289: 10.52.2.101:11823
        - pvc-abcdefg-r-aa3ef1d9: 10.52.8.201:11850
```

Longhorn Volume CR indicating migration is in progress:

```bash
$ kubectl describe lhv pvc-abcdefg
```

```yaml
apiVersion: longhorn.io/v1beta2
kind: Volume
metadata:
  labels:
    longhornvolume: pvc-abcdefg
  name: pvc-abcdefg
  namespace: longhorn-system
  ...
spec:
  accessMode: rwx
  backingImage: default-image-klmt7
  dataEngine: v1
  image: longhornio/longhorn-engine:v1.7.3
  migratable: true
  migrationNodeID: t2
  nodeID: s1
  numberOfReplicas: 3
  ...
status:
  currentMigrationNodeID: t2
  currentNodeID: s1
  ownerID: s1
  robustness: degraded
  state: attached
  ...
```

VolumeAttachment CR confirms that the migration ticket has been satisfied:

```bash
$ kubectl -n longhorn-system describe lhva pvc-abcdefg
```

```yaml
Name:         pvc-abcdefg
Namespace:    longhorn-system
Kind:         VolumeAttachment
Spec:
  Attachment Tickets:
    csi-473853237b61d7ea80ea8f3b9306d82c55ccf36744ee88212ee95c4c2f299edb:
      Type:                csi-attacher
      ...
    csi-bf34f58ee9ac935d1120e60253c7a4f9c1e73afc411677278848d0f1bcaace96:
      Type:                csi-attacher
      ...
  Volume:                  pvc-abcdefg
Status:
  Attachment Ticket Statuses:
    csi-473853237b61d7ea80ea8f3b9306d82c55ccf36744ee88212ee95c4c2f299edb:
      Conditions:
        Last Transition Time:  2025-06-19T07:24:07Z
        Message:               The migrating attachment ticket is satisfied
        Status:                True
        Type:                  Satisfied
      Generation:              0
      Id:                      csi-473853237b61d7ea80ea8f3b9306d82c55ccf36744ee88212ee95c4c2f299edb
      Satisfied:               true
    csi-bf34f58ee9ac935d1120e60253c7a4f9c1e73afc411677278848d0f1bcaace96:
      Conditions:
        Last Transition Time:  2025-06-19T06:01:18Z
        Status:                True
        Type:                  Satisfied
      Generation:              0
      Id:                      csi-bf34f58ee9ac935d1120e60253c7a4f9c1e73afc411677278848d0f1bcaace96
      Satisfied:               true
```

## Reason

There are cases where Longhorn fails to finalise Migratable RWX volume migration even after successful attachment on the destination node. For example, potential issue in Kubelet:

```
E0619 14:49:06.135666    3122 remote_runtime.go:366] "StopContainer from runtime service failed" err="rpc error: code = DeadlineExceeded desc = context deadline exceeded" containerID="0e225776b23476e5bdfda4aad7b6e411d79b6427f0130d4a0a818daed63ff5e8"
E0619 14:49:06.135711    3122 kuberuntime_container.go:784] "Container termination failed with gracePeriod" err="rpc error: code = DeadlineExceeded desc = > context deadline exceeded" pod="my-namespace/virt-launcher-my-pod" podUID="4b5de224-752c-4df4-8726-60758820bc67" containerName="compute" > containerID="containerd://0e225776b23476e5bdfda4aad7b6e411d79b6427f0130d4a0a818daed63ff5e8" gracePeriod=150
E0619 14:49:06.135733    3122 kuberuntime_container.go:822] "Kill container failed" err="rpc error: code = DeadlineExceeded desc = context deadline exceeded" > pod="my-namespace/virt-launcher-my-pod" podUID="4b5de224-752c-4df4-8726-60758820bc67" containerName="compute" containerID={"Type":"containerd","ID":"0e225776b23476e5bdfda4aad7b6e411d79b6427f0130d4a0a818daed63ff5e8"}
E0619 14:51:06.136339    3122 remote_runtime.go:222] "StopPodSandbox from runtime service failed" err="rpc error: code = DeadlineExceeded desc = failed to > stop container \"0e225776b23476e5bdfda4aad7b6e411d79b6427f0130d4a0a818daed63ff5e8\": an error occurs during waiting for container > \"0e225776b23476e5bdfda4aad7b6e411d79b6427f0130d4a0a818daed63ff5e8\" to be killed: wait container \"0e225776b23476e5bdfda4aad7b6e411d79b6427f0130d4a0a818daed63ff5e8\": context deadline exceeded" podSandboxID="f1b92f9befcc5cb2ef990a8b924937b1439523651513483e54514ca48b36769a"
E0619 14:51:06.136427    3122 kubelet.go:2049] [failed to "KillContainer" for "compute" with KillContainerError: "rpc error: code = DeadlineExceeded desc = > context deadline exceeded", failed to "KillPodSandbox" for "4b5de224-752c-4df4-8726-60758820bc67" with KillPodSandboxError: "rpc error: code = DeadlineExceeded>  desc = failed to stop container \"0e225776b23476e5bdfda4aad7b6e411d79b6427f0130d4a0a818daed63ff5e8\": an error occurs during waiting for container \"0e225776b23476e5bdfda4aad7b6e411d79b6427f0130d4a0a818daed63ff5e8\" to be killed: wait container \"0e225776b23476e5bdfda4aad7b6e411d79b6427f0130d4a0a818daed63ff5e8\": context deadline exceeded"]
E0619 14:51:06.136441    3122 pod_workers.go:1298] "Error syncing pod, skipping" err="[failed to \"KillContainer\" for \"compute\" with KillContainerError: > \"rpc error: code = DeadlineExceeded desc = context deadline exceeded\", failed to \"KillPodSandbox\" for \"4b5de224-752c-4df4-8726-60758820bc67\" with > KillPodSandboxError: \"rpc error: code = DeadlineExceeded desc = failed to stop container \\\"0e225776b23476e5bdfda4aad7b6e411d79b6427f0130d4a0a818daed63ff5e8\\\": an error occurs during waiting for container \\\"0e225776b23476e5bdfda4aad7b6e411d79b6427f0130d4a0a818daed63ff5e8\\\" to be killed: wait container \\\"0e225776b23476e5bdfda4aad7b6e411d79b6427f0130d4a0a818daed63ff5e8\\\": context deadline exceeded\"]" pod="my-namespace/virt-launcher-my-pod" podUID="4b5de224-752c-4df4-8726-60758820bc67"
```

This incomplete migration blocks VM workload live migration, leaving the node stuck in the pre-drain stage.

## Workaround

1. Inspect Kubernetes `volumeattachment` resources and remove any orphaned entries.
2. Shut down the affected VM workload.
3. Verify cleanup of both Longhorn and Kubernetes volume attachments (`volumeattachments.longhorn.io` and `volumeattachment`):
    ```bash
    $ kubectl get volumeattachments.longhorn.io -A | grep pvc-abcdefg
    $ kubectl get volumeattachment -A | grep pvc-abcdefg
    ```
4. Restart the VM workload if necessary.
5. Confirm that the pre-drain process continues successfully.

## Related Information

- [Longhorn Issue #11149](https://github.com/longhorn/longhorn/issues/11149): Original issue documenting this failure.
