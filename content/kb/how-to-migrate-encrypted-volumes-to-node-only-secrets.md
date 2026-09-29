---
title: "How to Migrate Encrypted Volumes to Node-Only Secret References"
authors:
- "Raphanus Lo"
draft: false
date: 2026-09-21
versions:
- "v1.13.0 and later"
categories:
- "instruction"
- "upgrade"
- "Encrypted volume"
---

## Scope

This optional guide is for administrators running Longhorn v1.13.0 or later who choose to disable controller-side Secret access and want to clean historical provisioner-only Secret parameters from Longhorn StorageClasses. Complete the upgrade to v1.13.0 or later before following this procedure; the controller-specific permission opt-out is not available in v1.12.x or earlier. This is a StorageClass-only migration. It does not migrate a volume, change an encryption key, replace a PV or PVC, or change a data engine.

The v1.13.0 Helm chart and static installation manifests grant the CSI controller service account broad, cluster-wide `get` access to core Secrets by default, regardless of StorageClass parameters. Cleaning a StorageClass does not revoke that static grant. Keep the grant while cleaning the StorageClasses below, then disable it in step 4. Removing access first can break new provisioning with historical provisioner-side Secret parameters.

The supported migration trigger is exact: a Longhorn StorageClass (`provisioner: driver.longhorn.io`) has one or more parameter keys beginning with `csi.storage.k8s.io/provisioner-secret-`. A key triggers this optional cleanup even when its value is empty. This guide does not rewrite or promise compatibility for custom controller, generic Secret, or deprecated parameter configurations.

> **Warning:** Controller-side Secret access is broad. This procedure only removes historical provisioner-only parameters and does not change existing PVs, workloads, or encryption Secrets. Do not rotate keys, replace PVs, or delete the original encryption Secret.

## What remains unchanged

Keep the original encryption Secret and all node-side Secret parameters and PV references:

- `csi.storage.k8s.io/node-stage-secret-name` and `csi.storage.k8s.io/node-stage-secret-namespace`
- `csi.storage.k8s.io/node-publish-secret-name` and `csi.storage.k8s.io/node-publish-secret-namespace`
- `csi.storage.k8s.io/node-expand-secret-name` and `csi.storage.k8s.io/node-expand-secret-namespace`

Do not expose Secret values in exports, manifests, logs, or issue reports. Existing PVCs, PVs, Longhorn volumes, PV deletion annotations, reclaim policies, finalizers, and CSI volume handles are not changed. No backup, workload detach, PVC deletion, PV deletion, rebind, or PV replacement is required.

This guide intentionally covers only historical provisioner-only parameters. Do not assume that custom `controller-publish-secret-*`, `controller-expand-secret-*`, generic `csi.storage.k8s.io/secret-name` or `csi.storage.k8s.io/secret-namespace`, deprecated `csiProvisionerSecretName`, `csiProvisionerSecretNamespace`, `csiControllerPublishSecretName`, or `csiControllerPublishSecretNamespace` configurations become safe or preserve controller-side expansion behavior after this cleanup.

## 1. Inventory only the supported legacy trigger

Set the Longhorn namespace if it differs from the example. This command prints StorageClass names and matching parameter keys, not parameter values. It checks every Longhorn StorageClass, including unused classes. Empty values still appear because presence of the key is the trigger.

```bash
export LH_NS=longhorn-system

kubectl get storageclass -o json |
  jq -r '
    .items[]
    | select(.provisioner == "driver.longhorn.io")
    | . as $sc
    | [($sc.parameters // {} | keys[]
       | select(startswith("csi.storage.k8s.io/provisioner-secret-")))] as $legacy
    | select(($legacy | length) > 0)
    | [$sc.metadata.name, ($legacy | join(","))]
    | @tsv
  '
```

Record the names printed by the command. If a StorageClass also contains controller, generic, or deprecated Secret parameters, stop and obtain guidance for that configuration; this guide does not rewrite or declare it safe.

## 2. Export each triggering StorageClass

Pause GitOps, autoscalers, and other automation that could create a StorageClass or provision a volume while the class is briefly absent. There is a narrow temporary provisioning gap between deleting and recreating a same-name StorageClass. Coordinate this window with the teams that submit PVCs.

Export each triggering class for review and recovery; do not publish the export because parameter values can identify Secret names or templates.

```bash
export SC=longhorn-crypto-global
export WORKDIR="$(mktemp -d)"
chmod 700 "$WORKDIR"

kubectl get storageclass "$SC" -o json > "$WORKDIR/$SC.json"
jq '{name: .metadata.name,
     defaultAnnotations: (.metadata.annotations // {} |
       with_entries(select(.key == "storageclass.kubernetes.io/is-default-class" or
                           .key == "storageclass.beta.kubernetes.io/is-default-class"))),
     parameterKeys: (.parameters // {} | keys)}' "$WORKDIR/$SC.json"
```

Review the exported object and confirm that it is the intended Longhorn class. Preserve its provisioner, all non-Secret parameters, allowed topologies, volume binding mode, reclaim policy, expansion setting, labels, annotations, and default-class designation. Remove only parameters whose keys start with `csi.storage.k8s.io/provisioner-secret-`; this removes an unexpected historical provisioner key without altering node-side keys.

Create a cleaned same-name object. This removes Kubernetes-generated metadata and status while retaining the StorageClass name and all user-managed fields, including default-class annotations:

```bash
jq '
  del(.metadata.uid,
      .metadata.resourceVersion,
      .metadata.creationTimestamp,
      .metadata.generation,
      .metadata.managedFields,
      .status) |
  .parameters = ((.parameters // {}) |
    with_entries(select(
      (.key | startswith("csi.storage.k8s.io/provisioner-secret-")) | not
    )))
' "$WORKDIR/$SC.json" > "$WORKDIR/$SC-cleaned.json"

jq -e '
  (.provisioner == "driver.longhorn.io") and
  ([((.parameters // {}) | keys[]) |
    select(startswith("csi.storage.k8s.io/provisioner-secret-"))] | length == 0)
' "$WORKDIR/$SC-cleaned.json"
jq '{name: .metadata.name,
     defaultAnnotations: (.metadata.annotations // {} |
       with_entries(select(.key == "storageclass.kubernetes.io/is-default-class" or
                           .key == "storageclass.beta.kubernetes.io/is-default-class"))),
     parameterKeys: (.parameters // {} | keys)}' "$WORKDIR/$SC-cleaned.json"
```

## 3. Replace each StorageClass under the same name

StorageClass parameters cannot be patched. After reviewing the cleaned manifest and confirming the provisioning pause, delete and recreate the StorageClass with the same name:

```bash
kubectl delete storageclass "$SC" --wait=true
kubectl create -f "$WORKDIR/$SC-cleaned.json"
kubectl get storageclass "$SC" -o json |
  jq '{provisioner, parameters, reclaimPolicy, volumeBindingMode,
       allowVolumeExpansion, allowedTopologies, annotations: .metadata.annotations}'
```

The deletion and recreation affect only the StorageClass object. They do not touch existing PVCs, PVs, Longhorn volumes, Secret objects, volume handles, or default-class annotations. Provisioning of a new PVC can fail during the short gap, so update the Helm/GitOps/source manifest to the cleaned StorageClass before resuming automation, and keep the pause in place until the replacement is confirmed.

Repeat this step until the inventory command in step 1 prints no rows. Do not leave an unused Longhorn StorageClass with a matching provisioner-secret key. Existing classes that never had a matching key do not need to be recreated.

## 4. Disable controller-side Secret access

After the upgrade to Longhorn v1.13.0 or later is complete and every triggering StorageClass has been cleaned or deleted, persist the opt-out in the installation source:

- **Helm:** Set `csi.allowControllerSecretAccess: false` in your release values and upgrade the existing release. Helm removes both `longhorn-csi-secret-role` and `longhorn-csi-secret-bind`.
- **Release manifests:** Remove `longhorn-csi-secret-bind` from the manifest or overlay used for future applies, then run `kubectl delete clusterrolebinding longhorn-csi-secret-bind --ignore-not-found`. You may also remove the now-unbound role with `kubectl delete clusterrole longhorn-csi-secret-role --ignore-not-found`. Applying a manifest without an object does not by itself delete an existing object.

No driver-deployer restart is required. Verify that the binding is absent and the CSI service account cannot get Secrets:

```bash
kubectl get clusterrole longhorn-csi-secret-role --ignore-not-found
kubectl get clusterrolebinding longhorn-csi-secret-bind --ignore-not-found
kubectl auth can-i get secrets \
  --as="system:serviceaccount:${LH_NS}:longhorn-csi-service-account" \
  -n "$LH_NS"
```

The Secret ClusterRoleBinding should be absent, and the final authorization result should be `no`. Helm also removes its Secret ClusterRole; a manifest installation may retain that role unbound without granting access. If the binding reappears, correct the applied manifest or Helm value before relying on the denial. Resume GitOps only after the cleaned StorageClass and opt-out configuration are recorded in the source of truth.

Existing workloads can continue using their original PVCs and PVs. Continue to use the unchanged original encryption Secret and node-side references for staging, publishing, and node-side expansion.

## References

- [Important notes: optional restriction of CSI controller Secret access](../../docs/1.13.0/important-notes/#optional-restriction-of-csi-controller-secret-access)
- [Volume encryption](../../docs/1.13.0/advanced-resources/security/volume-encryption/)
- [Kubernetes StorageClass](https://kubernetes.io/docs/concepts/storage/storage-classes/)
- [Kubernetes StorageClass parameters](https://kubernetes.io/docs/concepts/storage/storage-classes/#storageclass-objects)
- [Longhorn issue #14020](https://github.com/longhorn/longhorn/issues/14020)
