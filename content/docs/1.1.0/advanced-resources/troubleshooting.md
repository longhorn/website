---
title: Troubleshooting
weight: 6
---

You can click `Generate Support Bundle` link at the bottom of the UI to download a zip file contains Longhorn related configuration and logs.

## Common issues
### Volume can be attached/detached from UI, but Kubernetes Pod/StatefulSet etc cannot use it

#### Using with Flexvolume Plugin
Check if the volume plugin directory has been set correctly. This is automatically detected unless user explicitly set it.

By default, Kubernetes uses `/usr/libexec/kubernetes/kubelet-plugins/volume/exec/`, as stated in the [official document](https://github.com/kubernetes/community/blob/master/contributors/devel/sig-storage/flexvolume.md/#prerequisites).

Some vendors choose to change the directory for various reasons. For example, GKE uses `/home/kubernetes/flexvolume` instead.

The correct directory can be found by running `ps aux|grep kubelet` on the host and check the `--volume-plugin-dir` parameter. If there is none, the default `/usr/libexec/kubernetes/kubelet-plugins/volume/exec/` will be used.

## Troubleshooting guide

There are a few compontents in Longhorn: Manager, Engine, Driver and UI. By default, all of those components run as pods in the `longhorn-system` namespace in the Kubernetes cluster.

Most of the logs are included in the Support Bundle. You can click the **Generate Support Bundle** link at the bottom of the UI to download a zip file that contains Longhorn-related configuration and logs.

One exception is the `dmesg`, which needs to be retrieved from each node by the user.

### UI
Make use of the Longhorn UI is a good start for the troubleshooting. For example, if Kubernetes cannot mount one volume correctly, after stop the workload, try to attach and mount that volume manually on one node and access the content to check if volume is intact.

Also, the event logs in the UI dashboard provides some information of probably issues. Check for the event logs in `Warning` level.

### Manager and Engines
You can get the logs from the Longhorn Manager and Engines to help with troubleshooting. The most useful logs are the ones from `longhorn-manager-xxx`, and the logs inside Longhorn instance managers, e.g. `instance-manager-e-xxxx` and `instance-manager-r-xxxx`.

Since normally there are multiple Longhorn Managers running at the same time, we recommend using [kubetail,](https://github.com/johanhaleby/kubetail) which is a great tool to keep track of the logs of multiple pods. To track the manager logs in real time, you can use:

```
kubetail longhorn-manager -n longhorn-system
```


### CSI driver

For the CSI driver, check the logs for `csi-attacher-0` and `csi-provisioner-0`, as well as containers in `longhorn-csi-plugin-xxx`.

### Flexvolume Driver

The FlexVolume driver is deprecated as of Longhorn v0.8.0 and should no longer be used.

First check where the driver has been installed on the node. Check the log of `longhorn-driver-deployer-xxxx` for that information.

Then check the kubelet logs. The FlexVolume driver itself doesn't run inside the container. It would run along with the kubelet process.

If kubelet is running natively on the node, you can use the following command to get the logs:
```
journalctl -u kubelet
```

Or if kubelet is running as a container (e.g. in RKE), use the following command instead:
```
docker logs kubelet
```

For even more detailed logs of Longhorn FlexVolume, run the following command on the node or inside the container (if kubelet is running as a container, e.g. in RKE):
```
touch /var/log/longhorn_driver.log
```
