---
title: Volumes
description: Kubernetes Volumes in Longhorn
weight: 13
---

Volumes in Longhorn are Kubernetes Volumes, they are created and managed as the Longhorn Volume Manager.

The Longhorn Volume Manager container runs on each host in the Longhorn cluster. as a Kubernetes DaemonSet.  The Longhorn Volume Manager handles the API calls from the UI or the Flex Volume and CSI Kubernetes plugins.

When the Longhorn manager is asked to create a volume, it creates a controller container on the host the volume is attached to as well as the hosts where the replicas will be placed. Replicas should be placed on separate hosts to ensure maximum availability.

{{< figure src="/img/diagrams/concepts/volumes-and-replicas.png" >}}