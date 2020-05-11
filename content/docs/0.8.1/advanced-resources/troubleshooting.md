---
title: Troubleshooting
weight: 6
---

There are a few components in Longhorn: Manager, Engine, Driver and UI. All of those components run as pods in the `longhorn-system` namespace by default inside the Kubernetes cluster.

Most of the logs are included in the Support Bundle. To download a zip file containing Longhorn-related configuration and logs for Longhorn components, click the **Generate Support Bundle** link at the bottom of the Longhorn UI.

Not included in the Support Bundle is the `dmesg`, which would need to be retrieved from each node.

### Troubleshooting with the UI
Make use of the Longhorn UI is a good start for the troubleshooting. For example, if Kubernetes cannot mount one volume correctly, after stopping the workload, try to attach and mount that volume manually on one node and access the content to check if volume is intact.

Also, the event logs in the UI dashboard provides some information of probable issues. Check for the event logs in `Warning` level.

### Longhorn Manager and Engine Logs

You can get logs from Longhorn Manager and Engines to help with the troubleshooting. The most useful logs are from `longhorn-manager-xxx`, and the logs inside Longhorn instance managers, e.g. `instance-manager-e-xxxx` and `instance-manager-r-xxxx`.

Since normally there are multiple Longhorn Managers running at the same time, we recommend using [kubetail,](https://github.com/johanhaleby/kubetail) which is a great tool to keep track of the logs of multiple pods. To track the Manager logs in real time, you can use:

```
kubetail longhorn-manager -n longhorn-system
```

### CSI Driver Logs

For CSI driver, check the logs for `csi-attacher-0` and `csi-provisioner-0`, as well as containers in `longhorn-csi-plugin-xxx`.

### Troubleshooting the Flexvolume Driver

The FlexVolume driver is deprecated as of Longhorn v0.8.0 and should no longer be used.

First check where the driver has been installed on the node. Check the log of `longhorn-driver-deployer-xxxx` for that information.

Then check the kubelet logs. Flexvolume driver itself doesn't run inside the container. It would run along with the kubelet process.

If kubelet is running natively on the node, you can use the following command to get the logs:

```
journalctl -u kubelet
```

Or if the kubelet is running as a container (e.g. in RKE), use the following command instead:

```
docker logs kubelet
```

For even more detailed logs of Longhorn Flexvolume, run the following command on the node or inside the container (if kubelet is running as a container, e.g. in RKE):

```
touch /var/log/longhorn_driver.log
```

### Common Issues

#### Volume can be attached/detached from UI, but Kubernetes Pod/StatefulSet etc cannot use it

If you are using the Flexvolume plugin, check if the volume plugin directory has been set correctly. This is automatically detected unless the user explicitly sets it.

By default, Kubernetes uses `/usr/libexec/kubernetes/kubelet-plugins/volume/exec/`, as stated in the [official documentation](https://github.com/kubernetes/community/blob/master/contributors/devel/sig-storage/flexvolume.md).

Some vendors choose to change the directory for various reasons. For example, GKE uses `/home/kubernetes/flexvolume` instead.

To find the correct directory, run:

    ps aux|grep kubelet

on the host and check the `--volume-plugin-dir` parameter. If there is none, the default `/usr/libexec/kubernetes/kubelet-plugins/volume/exec/` will be used.