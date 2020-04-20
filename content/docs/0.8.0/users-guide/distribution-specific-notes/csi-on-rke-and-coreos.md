---
  title: Longhorn CSI on Rancher Kubernetes Engine (RKE) and CoreOS
  weight: 40
---

## Introduction

For minimalist Linux Operating systems, you'll need a little extra configuration to use Longhorn.  This document outlines the requirements for using RKE and CoreOS.

## Requirements

  -  Kubernetes v1.11 or higher.
  -  Longhorn v0.4.1 or higher.

### For CoreOS + Kubernetes v1.11 only 

*** The following step is not needed for Kubernetes v1.12+. ***

Add extra_binds for kubelet in RKE `cluster.yml`:

```yaml

services:
  kubelet:
    extra_binds:
    - "/opt/rke/var/lib/kubelet/plugins:/var/lib/kubelet/plugins" 

```

This makes sure the kubelet plugins directory is exposed for CSI driver installation.

##  If you want to enable iSCSI daemon automatically at boot, you need to enable the systemd service:

```
sudo su
systemctl enable iscsid
reboot
```

##  Or just start the iSCSI daemon for the current session:

```
sudo su
systemctl start iscsid
```

## Troublshooting Common Issues

### Failed to get arg root-dir: Cannot get kubelet root dir, no related proc for root-dir detection ...

This error is due to Longhorn cannot detect where is the root dir setup for Kubelet, so the CSI plugin installation failed.

User can override the root-dir detection by manually setting argument `kubelet-root-dir` here: 
https://github.com/longhorn/longhorn/blob/master/deploy/longhorn.yaml#L329

#### How to find `root-dir`?
 
Run `ps aux | grep kubelet` and get argument `--root-dir` on host node. 

e.g.
```

$ ps aux | grep kubelet
root      3755  4.4  2.9 744404 120020 ?       Ssl  00:45   0:02 kubelet --root-dir=/opt/rke/var/lib/kubelet --volume-plugin-dir=/var/lib/kubelet/volumeplugins

```
You will find `root-dir` in the cmdline of proc `kubelet`. If it's not set, the default value `/var/lib/kubelet` would be used. In the case of CoreOS, the root-dir would be `/opt/rke/var/lib/kubelet` as shown above.

If kubelet is using a configuration file, you would need to check the configuration file to locate the `root-dir` parameter.

###  Background 

CSI doesn't work with CoreOS + RKE before Longhorn v0.4.1. The reason is:

1. RKE sets argument `root-dir=/opt/rke/var/lib/kubelet` for kubelet in the case of CoreOS, which is different from the default value `/var/lib/kubelet`.
                                                                             
2. **For k8s v1.12+**

     Kubelet will detect the `csi.sock` according to argument `<--kubelet-registration-path>` passed in by Kubernetes CSI driver-registrar, and `<drivername>-reg.sock` (for Longhorn, it's `io.rancher.longhorn-reg.sock`) on kubelet path `<root-dir>/plugins`.
   
   **For k8s v1.11**
   
     Kubelet will find both sockets on kubelet path `/var/lib/kubelet/plugins`.
   
3. By default, Longhorn CSI driver create and expose these 2 sock files on host path `/var/lib/kubelet/plugins`.

4. Then kubelet cannot find `<drivername>-reg.sock`, so CSI driver doesn't work.

5. Furthermore, kubelet will instruct CSI plugin to mount Longhorn volume on `<root-dir>/pods/<pod-name>/volumes/kubernetes.io~csi/<volume-name>/mount`.

   But this path inside CSI plugin container won't be binded mount on host path. And the mount operation for Longhorn volume is meaningless.
   
   Hence Kubernetes cannot connect to Longhorn using CSI driver.

## Reference
https://github.com/kubernetes-csi/driver-registrar

https://coreos.com/os/docs/latest/iscsi.html
