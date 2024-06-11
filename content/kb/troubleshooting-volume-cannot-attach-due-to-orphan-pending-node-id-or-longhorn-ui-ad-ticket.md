---
title: "After upgrading Longhorn, Volume Cannot Attach Because of The Leftover non-empty volume.status.PendingNodeID or Longhorn UI Attachment Ticket"
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

## Reason

There are 2 reasons which might cause this issue:

1. Longhorn volume cannot attach because of the leftover non-empty `volume.status.PendingNodeID`
1. Longhorn volume cannot attach to new node due to unexpected longhorn-ui attachment ticket

## Solution

### Longhorn volume cannot attach because of the leftover non-empty `volume.status.PendingNodeID`

We fixed this bug in Longhorn version >= v1.5.5. If you hit this bug in v1.5.0/v1.5.1/v1.5.2/v1.5.3/v1.5.4, you can use the workaround: run `kubectl edit volumes -n longhorn-system VOLUME-NAME --subresource=status` and set `volume.status.PendingNodeID` to empty string `""`

### Longhorn volume cannot attach to new node due to unexpected longhorn-ui attachment ticket

The root cause of this issue is still being investigated at https://github.com/longhorn/longhorn/issues/8339. If you hit this issue, you can use this workaround:
1. Check the Longhorn VolumeAttachment CR by `kubectl -n longhorn-system edit volumeattachments.longhorn.io VOLUME-NAME`
1. If it has the `longhorn-ui` ticket like this:
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
