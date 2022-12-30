---
title: What's New in Longhorn 1.4
author: David Ko
draft: false
date: 2022-12-30
categories:
  - "announcement"
---

**Longhorn 1.4.0** is just released on December 30, 2022! It comes out with tons of new features, improvements, bug fixes, experimental features generally available, Kubernetes 1.25 support, and so on. In this post, I will brief the primary achievements we have done for 1.4.0. For more details, please visit the document [here](https://longhorn.io/docs/1.4.0/).

## Kubernetes 1.25 Support
In the previous versions, Longhorn relies on Pod Security Policy (PSP) to authorize Longhorn components for privileged operations. From Kubernetes 1.25, PSP has been removed and replaced with Pod Security Admission (PSA). Longhorn v1.4.0 supports opt-in PSP enablement, so it can support Kubernetes versions with or without PSP.

## ARM64 GA
ARM64 has been experimental from Longhorn v1.1.0. After receiving more user feedback and increasing testing coverage, ARM64 distribution has been stabilized with quality as per our regular regression testing, so it is qualified for general availability.

## RWX GA
RWX has been experimental from Longhorn v1.1.0, but it lacks availability support when the Longhorn Share Manager component behind becomes unavailable. Longhorn v1.4.0 supports NFS recovery backend based on Kubernetes built-in resource, ConfigMap, for recovering NFS client connection during the fail-over period. Also, the NFS client hard mode introduction will further avoid previous potential data loss. For the detail, please check the issue and enhancement proposal.

## Volume Snapshot Checksum
Data integrity is a continuous effort for Longhorn. In this version, Snapshot Checksum has been introduced w/ some settings to allow users to enable or disable checksum calculation with different modes.

## Volume Bit-rot Protection
When enabling the Volume Snapshot Checksum feature, Longhorn will periodically calculate and check the checksums of volume snapshots, find corrupted snapshots, then fix them.

## Volume Replica Rebuilding Speedup
When enabling the Volume Snapshot Checksum feature, Longhorn will use the calculated snapshot checksum to avoid needless snapshot replication between nodes for improving replica rebuilding speed and resource consumption.

## Volume Trim
Longhorn engine supports UNMAP SCSI command to reclaim space from the block volume.

## Online Volume Expansion
Longhorn engine supports optional parameters to pass size expansion requests when updating the volume frontend to support online volume expansion and resize the filesystem via CSI node driver.

## Local Volume via Data Locality Strict Mode
Local volume is based on a new Data Locality setting, Strict Local. It will allow users to create one replica volume staying in a consistent location, and the data transfer between the volume frontend and engine will be through a local socket instead of the TCP stack to improve performance and reduce resource consumption.

## Volume Recurring Job Backup Restore
Recurring jobs binding to a volume can be backed up to the remote backup target together with the volume backup metadata. They can be restored back as well for a better operation experience.

## Volume IO Metrics
Longhorn enriches Volume metrics by providing real-time IO stats including IOPS, latency, and throughput of R/W IO. Users can set up a monotoning solution like Prometheus to monitor volume performance.

## Longhorn System Backup & Restore
Users can back up the longhorn system to the remote backup target. Afterward, it's able to restore back to an existing cluster in place or a new cluster for specific operational purposes.

## Support Bundle Enhancement
Longhorn introduces a new support bundle integration based on a general support bundle kit solution. This can help us collect more complete troubleshooting info and simulate the cluster environment.

## Tunable Timeout between Engine and Replica
In the current Longhorn versions, the default timeout between the Longhorn engine and replica is fixed without any exposed user settings. This will potentially bring some challenges for users having a low-spec infra environment. By exporting the setting configurable, it will allow users adaptively tune the stability of volume operations.

Besides the above outstanding achievements, other significant items are introduced to this release, for instance, faster new replica rebuilding. Highly recommend reviewing the latest document to learn more about them.

For the coming 2023, there are many essential plans in the roadmap, for example, a new data plane based on SPDK, local volume passthrough, object storage gateway, instance manager consolidation to reduce resource consumption, continuous data integrity improvement, space efficiency improvement via periodical automatic snapshot cleanup, etc. Would you like to know more about the roadmap? Review the Longhorn roadmap [here](https://github.com/longhorn/longhorn/wiki/Roadmap). Any feedback is welcome to make Longhorn successful and fulfill market needs.

Lastly, Happy New Year for 2023 🎆 and look forward to your feedback of Longhorn 1.4!
