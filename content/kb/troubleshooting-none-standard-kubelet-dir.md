---
title: "Troubleshooting: None-standard Kubelet directory"
author: Chin-Ya Huang
draft: false
date: 2021-06-18
categories:
  - "csi"
---

## Applicable versions

All Longhorn versions.

## Symptoms

When the Kubernetes cluster is using a non-standard Kubelet directory, longhorn-csi-plugin is unable to start.
```
ip-172-30-0-73:/home/ec2-user # kubectl -n longhorn-system get pod
NAME                                        READY   STATUS              RESTARTS   AGE
longhorn-ui-5b864949c4-4sgws                1/1     Running             0          7m35s
longhorn-manager-tx469                      1/1     Running             0          7m35s
longhorn-driver-deployer-5444f75b8f-kgq5v   1/1     Running             0          7m35s
longhorn-csi-plugin-s4fg7                   0/2     ContainerCreating   0          6m59s
instance-manager-r-d185a1e9                 1/1     Running             0          7m10s
instance-manager-e-b5e69e2d                 1/1     Running             0          7m10s
csi-attacher-7d975797bc-qpfrv               1/1     Running             0          7m
csi-snapshotter-7dbfc7ddc6-nqqtg            1/1     Running             0          6m59s
csi-attacher-7d975797bc-td6tw               1/1     Running             0          7m
csi-resizer-868d779475-v6jvv                1/1     Running             0          7m
csi-resizer-868d779475-2bbs2                1/1     Running             0          7m
csi-provisioner-5c6845945f-46qnb            1/1     Running             0          7m
csi-resizer-868d779475-n5vjn                1/1     Running             0          7m
csi-provisioner-5c6845945f-fjnrq            1/1     Running             0          7m
csi-snapshotter-7dbfc7ddc6-mhfpl            1/1     Running             0          6m59s
csi-provisioner-5c6845945f-4lx5c            1/1     Running             0          7m
csi-attacher-7d975797bc-flldq               1/1     Running             0          7m
csi-snapshotter-7dbfc7ddc6-cms2v            1/1     Running             0          6m59s
engine-image-ei-611d1496-dlqcs              1/1     Running             0          7m10s
```

## Reason

Caused by Longhorn cannot detect where is the root dir setup for Kubelet.

## Solution

### Longhorn installed via [longhorn.yaml](https://github.com/longhorn/longhorn/blob/master/deploy/longhorn.yaml)

  Uncomment and edit:
  ```
          #- name: KUBELET_ROOT_DIR
          #  value: /var/lib/rancher/k3s/agent/kubelet
  ```

### Longhorn installed via `Rancher - App`:

  Click `Customize Default Settings` to set Kubelet Root Directory

## Related information

* Longhorn issue: https://github.com/longhorn/longhorn/issues/2537
* More information can be found in Troubleshooting section under `OS/Distro Specific Configuration`.
