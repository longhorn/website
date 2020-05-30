---
  title: Longhorn CSI on RKE and CoreOS
  weight: 2
---

For minimalist Linux Operating systems, you'll need a little extra configuration to use Longhorn with RKE (Rancher Kubernetes Engine).  This document outlines the requirements for using RKE and CoreOS.

###  Background 

CSI doesn't work with CoreOS + RKE before Longhorn v0.4.1. The reason is that in the case of CoreOS, RKE sets the argument `root-dir=/opt/rke/var/lib/kubelet` for the kubelet , which is different from the default value `/var/lib/kubelet`.
                                                                             
**For k8s v1.12+**, the kubelet will detect the `csi.sock` according to argument `<--kubelet-registration-path>` passed in by Kubernetes CSI driver-registrar, and `<drivername>-reg.sock` (for Longhorn, it's `io.rancher.longhorn-reg.sock`) on kubelet path `<root-dir>/plugins`.
   
  **For k8s v1.11,** the kubelet will find both sockets on kubelet path `/var/lib/kubelet/plugins`.
   
By default, Longhorn CSI driver creates and expose these two sock files on the host path `/var/lib/kubelet/plugins`. Then the kubelet cannot find `<drivername>-reg.sock`, so CSI driver doesn't work.

Furthermore, the kubelet will instruct the CSI plugin to mount the Longhorn volume on `<root-dir>/pods/<pod-name>/volumes/kubernetes.io~csi/<volume-name>/mount`. But this path inside the CSI plugin container won't be bind mounted on the host path. And the mount operation for the Longhorn volume is meaningless.

Therefore, in this case, Kubernetes cannot connect to Longhorn using the CSI driver without additional configuration.

### Requirements

  -  Kubernetes v1.11 or higher.
  -  Longhorn v0.4.1 or higher.

###  1. Add extra binds for the kubelet

> This step is only required for For CoreOS + and Kubernetes v1.11. It is not needed for Kubernetes v1.12+.

Add extra_binds for kubelet in RKE `cluster.yml`:

```

services:
  kubelet:
    extra_binds:
    - "/opt/rke/var/lib/kubelet/plugins:/var/lib/kubelet/plugins" 

```

This makes sure the kubelet plugins directory is exposed for CSI driver installation.

### 2. Start the iSCSI Daemon

If you want to enable iSCSI daemon automatically at boot, you need to enable the systemd service:

```
sudo su
systemctl enable iscsid
reboot
```

Or just start the iSCSI daemon for the current session:

```
sudo su
systemctl start iscsid
```

### Troublshooting

#### Failed to get arg root-dir: Cannot get kubelet root dir, no related proc for root-dir detection ...

This error happens because Longhorn cannot detect the root dir setup for the kubelet, so the CSI plugin installation failed.

User can override the root-dir detection by manually setting argument `kubelet-root-dir` here: https://github.com/longhorn/longhorn/blob/master/deploy/longhorn.yaml#L329

#### How to find `root-dir`?
 
Run `ps aux | grep kubelet` and get the argument `--root-dir` on host node. 

For example,
```

$ ps aux | grep kubelet
root      3755  4.4  2.9 744404 120020 ?       Ssl  00:45   0:02 kubelet --root-dir=/opt/rke/var/lib/kubelet --volume-plugin-dir=/var/lib/kubelet/volumeplugins

```
You will find `root-dir` in the cmdline of proc `kubelet`. If it's not set, the default value `/var/lib/kubelet` would be used. In the case of CoreOS, the root-dir would be `/opt/rke/var/lib/kubelet` as shown above.

If the kubelet is using a configuration file, you need to check the configuration file to locate the `root-dir` parameter.

### References
https://github.com/kubernetes-csi/driver-registrar

https://coreos.com/os/docs/latest/iscsi.html
