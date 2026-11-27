---
title: Troubleshooting Problems
weight: 1
---
- [Troubleshooting Guide](#troubleshooting-guide)
  - [UI](#ui)
  - [Manager and Engines](#manager-and-engines)
  - [CSI driver](#csi-driver)
  - [Flexvolume Driver](#flexvolume-driver)
- [Common issues](#common-issues)
  - [Volume can be attached/detached from UI, but Kubernetes Pod/StatefulSet etc cannot use it](#volume-can-be-attacheddetached-from-ui-but-kubernetes-podstatefulset-etc-cannot-use-it)
    - [Using with Flexvolume Plugin](#using-with-flexvolume-plugin)

## Troubleshooting Guide

> For a more in-depth troubleshooting flow please see https://github.com/longhorn/longhorn/wiki/Troubleshooting

There are a few components in Longhorn: Manager, Engine, Driver and UI. By default, all of those components run as pods in the `longhorn-system` namespace in the Kubernetes cluster.

Most of the logs are included in the Support Bundle. You can click the **Generate Support Bundle** link at the bottom of the UI to download a zip file that contains Longhorn-related configuration and logs.
See [Support Bundle](../support-bundle) for detail.

One exception is the `dmesg`, which needs to be retrieved from each node by the user.

### UI
Make use of the Longhorn UI is a good start for the troubleshooting. For example, if Kubernetes cannot mount one volume correctly, after stop the workload, try to attach and mount that volume manually on one node and access the content to check if volume is intact.

Also, the event logs in the UI dashboard provides some information of probably issues. Check for the event logs in `Warning` level.

### Manager and Engines
You can get the logs from the Longhorn Manager and Engines to help with troubleshooting. The most useful logs are the ones from `longhorn-manager-xxx`, and the logs inside Longhorn instance managers, e.g. `instance-manager-xxxx`, `instance-manager-e-xxxx` and `instance-manager-r-xxxx`.

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


## Common issues
### Volume can be attached/detached from UI, but Kubernetes Pod/StatefulSet etc cannot use it

#### Using with Flexvolume Plugin
Check if the volume plugin directory has been set correctly. This is automatically detected unless the user explicitly sets it.

By default, Kubernetes uses `/usr/libexec/kubernetes/kubelet-plugins/volume/exec/`, as stated in the [official document](https://github.com/kubernetes/community/blob/master/contributors/devel/sig-storage/flexvolume.md/#prerequisites).

Some vendors choose to change the directory for various reasons. For example, GKE uses `/home/kubernetes/flexvolume` instead.

The correct directory can be found by running `ps aux|grep kubelet` on the host and check the `--volume-plugin-dir` parameter. If there is none, the default `/usr/libexec/kubernetes/kubelet-plugins/volume/exec/` will be used.

## Profiling

### Engine, replica, and sync agent runtime

You can enable the `pprof` server dynamically to perform runtime profiling.
To enable profiling, you can:

1. Shell into the instance manager pod.
2. Identify the runtime process and its port using `ps`:
    ```bash
    $ ps aux | more

    USER         PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
    ...
    root        1996  0.0  0.6 1990080 20996 ?       Sl   Jul25   0:05 /host/var/lib/longhorn/engine-binaries/longhornio-longhorn-engine-v1.10.0/longhorn --volume-name     vol replica /host/var/lib/longhorn/replicas/vol-3004fc59 --size 1073741824 --disableRevCounter --replica-instance-name vol-r-ec7e35e4 --snapshot-max-count 250     --snapshot-max-size 0 --sync-agent-port-count 7 --listen 0.0.0.0:10000
    root        2004  0.0  0.6 1695152 22708 ?       Sl   Jul25   0:09 /host/var/lib/longhorn/engine-binaries/longhornio-longhorn-engine-v1.10.0/longhorn --volume-name     vol sync-agent --listen 0.0.0.0:10002 --replica 0.0.0.0:10000 --listen-port-range 10003-10009 --replica-instance-name vol-r-ec7e35e4
    root        2031  0.0  0.6 1916348 23760 ?       Sl   Jul25   0:46 /engine-binaries/longhornio-longhorn-engine-v1.10.0/longhorn --engine-instance-name vol-e-0     controller vol --frontend tgt-blockdev --disableRevCounter --size 1073741824 --current-size 0 --engine-replica-timeout 8 --file-sync-http-client-timeout 30     --snapshot-max-count 250 --snapshot-max-size 0 --replica tcp://10.42.2.7:10000 --replica tcp://10.42.0.15:10000 --replica tcp://10.42.1.7:10000 --listen 0.0.0.0:10010
    ```
3. Enable the `pprof` server for the desired runtime (for example, sync-agent):
    > In this example, the sync-agent process listens on port `10002`.
    ```bash
    $ /host/var/lib/longhorn/engine-binaries/longhornio-longhorn-engine-v1.10.0/longhorn --url http://localhost:10002 profiler enable --port 36060
    $ /host/var/lib/longhorn/engine-binaries/longhornio-longhorn-engine-v1.10.0/longhorn --url http://localhost:10002 profiler show

    Profiler enabled at Addr: *:36060
    ```
    > The `pprof` server is now accessible at `http://localhost:36060` *inside the instance manager pod*.
4. Use the `pprof` interface for runtime inspection. For more details, refer to the [official pprof documentation](https://pkg.go.dev/net/http/pprof#hdr-Usage_examples).
5. Disable the profiler after completing your analysis:
    ```bash
    $ /host/var/lib/longhorn/engine-binaries/longhornio-longhorn-engine-v1.10.0/longhorn --url http://localhost:10002 profiler disable

    Profiler is disabled!
    ```
