---
title: Important Notes
weight: 1
---

This page lists important notes for Longhorn v{{< current-version >}}.
Please see [here](https://github.com/longhorn/longhorn/releases/tag/v{{< current-version >}}) for the full release note.


- [General](#general)
  - [CRD Upgrade Validation](#crd-upgrade-validation)

## General

### CRD Upgrade Validation

During the upgrade process, the Custom Resource Definition (CRD) may be applied after the new Longhorn manager has started. This sequencing ensures that the controller does not process objects with deprecated data or fields. However, this can result in the Longhorn manager failing during the initial upgrade phase if the CRD has not been applied yet.

If the Longhorn manager crashes during the upgrade, check the logs to determine if the failure is due to the CRD not being applied. In such cases, the logs may contain error messages similar to the following:

```
time="2025-03-27T06:59:55Z" level=fatal msg="Error starting manager: upgrade resources failed: BackingImage in version \"v1beta2\" cannot be handled as a BackingImage: strict decoding error: unknown field \"spec.diskFileSpecMap\", unknown field \"spec.diskSelector\", unknown field \"spec.minNumberOfCopies\", unknown field \"spec.nodeSelector\", unknown field \"spec.secret\", unknown field \"spec.secretNamespace\"" func=main.main.DaemonCmd.func3 file="daemon.go:94"
```
