---
title: Disaster Recovery Volumes
weight: 18
---

A **disaster recovery volume** is a volume that stores data in a backup cluster in case the whole main cluster goes down. Disaster recovery volumes are used to increase the resiliency of Longhorn volumes.


A disaster recovery volume can be created from a volume's backup in the backup store. And Longhorn will monitor its
original backup volume and incrementally restore from the latest backup. Once the original volume in the main cluster goes
down and users decide to activate the disaster recovery volume in the backup cluster, the disaster recovery volume can be
activated immediately in the most condition, so it will greatly reduced the time needed to restore the data from the
backup store to the volume in the backup cluster.
