---
title: Troubleshooting Problems
weight: 1
---

- [Troubleshooting Guide](#troubleshooting-guide)
  - [UI](#ui)
  - [Manager and Engines](#manager-and-engines)
  - [CSI driver](#csi-driver)
  - [FlexVolume Driver](#flexvolume-driver)
- [Common Issues](#common-issues)
  - [A volume can be attached/detached from the UI, but Kubernetes Pods/StatefulSets cannot use it](#a-volume-can-be-attacheddetached-from-the-ui-but-kubernetes-podsstatefulsets-cannot-use-it)
    - [Using with FlexVolume Plug-in](#using-with-flexvolume-plug-in)
  - ["Package 'linux-modules-extra-x.x.x-x-generic' Has No Installation Candidate" Error During Installation on Debian Machines](#package-linux-modules-extra-xxx-x-generic-has-no-installation-candidate-error-during-installation-on-debian-machines)
  - ["Invalid argument" Error in Disk Status After Adding a Block-Type Disk](#invalid-argument-error-in-disk-status-after-adding-a-block-type-disk)

## Troubleshooting Guide

> For a more in-depth troubleshooting flow please see [Longhorn Troubleshooting](https://github.com/longhorn/longhorn/wiki/Troubleshooting).

There are a few components in Longhorn: Manager, Engine, Driver and UI. By default, all those components run as pods in the `longhorn-system` namespace in the Kubernetes cluster.

Most of the logs are included in the Support Bundle. You can click the **Generate Support Bundle** link at the bottom of the UI to download a zip file that contains Longhorn-related configuration and logs.

See [Support Bundle](../support-bundle) for detail.

One exception is the `dmesg`, which needs to be retrieved from each node by the user.

### UI

Make use of the Longhorn UI is a good start for the troubleshooting. For example, if Kubernetes cannot mount one volume correctly, after stop the workload, try to attach and mount that volume manually on one node and access the content to check if volume is intact.

Also, the event logs in the UI dashboard provides information of probable issues. Check for the event logs in `Warning` level.

### Manager and Engines

You can get the logs from the Longhorn Manager and Engines to help with troubleshooting. The most useful logs are the ones from `longhorn-manager-xxx`, and the logs inside Longhorn instance managers, for example, `instance-manager-xxxx`, `instance-manager-e-xxxx` and `instance-manager-r-xxxx`.

Since normally there are multiple Longhorn Managers running at the same time, we recommend using [kubetail](https://github.com/johanhaleby/kubetail), which is a great tool to keep track of the logs of multiple pods. To track the manager logs in real time, you can use:

```bash
kubetail longhorn-manager -n longhorn-system
```

### CSI driver

For the CSI driver, check the logs for `csi-attacher-0` and `csi-provisioner-0`, as well as containers in `longhorn-csi-plugin-xxx`.

### FlexVolume Driver

The FlexVolume driver is deprecated as of Longhorn v0.8.0 and should no longer be used.

First check where the driver has been installed on the node. Check the log of `longhorn-driver-deployer-xxxx` for that information.

Then check the kubelet logs. The FlexVolume driver itself does not run inside the container. It would run along with the kubelet process.

If kubelet is running natively on the node, you can use the following command to get the logs:

```bash
journalctl -u kubelet
```

Or if kubelet is running as a container (for example, in RKE), use the following command instead:

```bash
docker logs kubelet
```

For even more detailed logs of Longhorn FlexVolume, run the following command on the node or inside the container (if kubelet is running as a container, for example, in RKE):

```bash
touch /var/log/longhorn_driver.log
```

## Common Issues

### A volume can be attached/detached from the UI, but Kubernetes Pods/StatefulSets cannot use it

#### Using with FlexVolume Plug-in

Check if the volume plug-in directory has been set correctly. This is automatically detected unless the user explicitly sets it.

By default, Kubernetes uses `/usr/libexec/kubernetes/kubelet-plugins/volume/exec/`, as stated in the [official document](https://github.com/kubernetes/community/blob/master/contributors/devel/sig-storage/flexvolume.md/#prerequisites).

Some vendors choose to change the directory for several reasons. For example, GKE uses `/home/kubernetes/flexvolume` instead.

The correct directory can be found by running `ps aux|grep kubelet` on the host and check the `--volume-plugin-dir` parameter. If there is none, the default `/usr/libexec/kubernetes/kubelet-plugins/volume/exec/` will be used.

### "Package 'linux-modules-extra-x.x.x-x-generic' Has No Installation Candidate" Error During Installation on Debian Machines

For Debian machines, if you encounter errors similar to the below when installing Linux kernel extra modules, you need to find an available version in the pkg collection websites like [this](https://pkgs.org/search/?q=linux-modules-extra) rather than directly relying on `uname -r` instead:

```log
apt install -y linux-modules-extra-`uname -r`
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
Package linux-modules-extra-5.15.0-67-generic is not available, but is referred to by another package.
This may mean that the package is missing, has been obsoleted, or
is only available from another source

E: Package 'linux-modules-extra-5.15.0-67-generic' has no installation candidate
```

For example, for Ubuntu 22.04, one valid version is `linux-modules-extra-5.15.0-76-generic`:

```bash
apt update -y
apt install -y linux-modules-extra-5.15.0-76-generic
```

### "Invalid argument" Error in Disk Status After Adding a Block-Type Disk

After adding a block-type disk, the disk status displays error messages:

```plaintext
Disk disk-1(/dev/nvme1n1) on node dereksu-ubuntu-pool1-bf77ed93-2d2p9 is not ready: 
failed to generate disk config: error: rpc error: code = Internal desc = rpc error: code = Internal 
desc = failed to add block device: failed to create AIO bdev: error sending message, id 10441, 
method bdev_aio_create, params {disk-1 /host/dev/nvme1n1 4096}: {"code": -22,"message": "Invalid argument"}
```

Next, inspect the log message of the instance-manager pod on the same node. If the log reveals the following:

```log
[2023-06-29 08:51:53.762597] bdev_aio.c: 762:create_aio_bdev: *WARNING*: Specified block size 4096 does not match auto-detected block size 512
[2023-06-29 08:51:53.762640] bdev_aio.c: 788:create_aio_bdev: *ERROR*: Disk size 100000000000 is not a multiple of block size 4096
```

These messages indicate that the size of your disk is not a multiple of the block size 4096 and is not supported by Longhorn system.

To resolve this issue, you can follow the steps:

1. Remove the newly added block-type disk from the node.
2. Partition the block-type disk using the `fdisk` utility and ensure that the partition size is a multiple of the block size 4096.
3. Add the partitioned disk to the Longhorn node.

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

### SPDK - Failed to bind NVMe disk (Error -22)

If `instance-manager` logs show `failed to bind NVMe disk` or `vfio-pci: probe ... failed with error -22`, your NVMe likely shares an IOMMU group with a PCIe bridge.

**Validation**: Run `lspci -t` or check `/sys/kernel/iommu_groups/`. If the NVMe and Bridge are in the same group, you must switch the disk to **AIO mode** in the Longhorn UI.
