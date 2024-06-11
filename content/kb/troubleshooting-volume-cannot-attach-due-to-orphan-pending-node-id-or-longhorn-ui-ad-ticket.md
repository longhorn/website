---
title: "Failure to Attach Volumes After Upgrade to Longhorn v1.5.x"
authors:
- "Phan Le"
draft: false
date: 2024-05-31
versions:
- "See Applicable Versions"
categories:
- "volume attach detach"
---

## Applicable versions

Longhorn v1.4.x upgrading to v1.5.x

## Symptoms

In some situations, volumes are unable to attach after Longhorn is upgraded from v1.4.x to v1.5.x. Workloads that use the affected volumes become stuck in the *Pending* state.

## Possible Causes and Solutions

- Cause 1: Leftover non-empty `volume.status.PendingNodeID`

  This bug no longer exists in Longhorn v1.5.5 and later releases. If you encounter this bug in v1.5.0, v1.5.1, v1.5.2, v1.5.3, or v1.5.4, run the command `kubectl edit volumes -n longhorn-system VOLUME-NAME --subresource=status` and set `volume.status.PendingNodeID` to an empty string `""`.

- Cause 2: Unexpected `longhorn-ui` attachment ticket

  The root cause is still being investigated (see [Issue #8339](https://github.com/longhorn/longhorn/issues/8339)). If you encounter this issue, check the Longhorn VolumeAttachment CR by running the command `kubectl -n longhorn-system edit volumeattachments.longhorn.io VOLUME-NAME`. If the following `longhorn-ui` ticket exists, remove the whole block.
    ```yaml
          longhorn-ui:
            generation: 0
            id: longhorn-ui
            nodeID: k3s-agent-acf067
            parameters:
              disableFrontend: "false"
            type: longhorn-api
    ```
    You can directly remove the whole block.

## Related information

- https://github.com/longhorn/longhorn/issues/7994
- https://github.com/longhorn/longhorn/issues/8339
