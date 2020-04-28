---
title: Kubernetes driver
weight: 21
---

If you're using [Kubernetes](https://kubernetes.io), you can use Longhorn to provide persistent storage using the Longhorn Container Storage Interface (CSI) driver.

{{< info title="Preferred driver" >}}
The CSI driver is preferred to the FlexVolume driver, which is deprecated as of Longhorn v0.8.0 and should no longer be used.
{{< /info >}}

Noted that the volume created and used through one driver won't be recognized by Kubernetes using the other driver. So please don't switch driver (e.g. during upgrade) if you have existing volumes created using the old driver. To switch from the FlexVolume driver to the CSI driver, see [here](../../install/upgrades/#migrating-from-the-flexvolume-driver-to-csi) for instructions.

## The CSI driver {#csi}

{{< requirement title="Requirements for the CSI driver" >}}
1. Kubernetes v1.10+
   1. CSI is in beta release for this version of Kubernetes, and enabled by default.
2. Mount propagation feature gate enabled.
   1. It's enabled by default in Kubernetes v1.10. But some early versions of RKE may not enable it.
   2. You can check it by using [environment check script](#environment-check-script).
{{< /requirement >}}

### Check if your setup satisfied CSI requirement

1. Use the following command to check your Kubernetes server version

    ```shell
    kubectl version
    ```

    Result:

    ```shell
    Client Version: version.Info{Major:"1", Minor:"10", GitVersion:"v1.10.3", GitCommit:"2bba0127d85d5a46ab4b778548be28623b32d0b0", GitTreeState:"clean", BuildDate:"2018-05-21T09:17:39Z", GoVersion:"go1.9.3", Compiler:"gc", Platform:"linux/amd64"}
    Server Version: version.Info{Major:"1", Minor:"10", GitVersion:"v1.10.1", GitCommit:"d4ab47518836c750f9949b9e0d387f20fb92260b", GitTreeState:"clean", BuildDate:"2018-04-12T14:14:26Z", GoVersion:"go1.9.3", Compiler:"gc", Platform:"linux/amd64"}
    ```

    The `Server Version` should be `v1.10` or above.

2. The result of [environment check script](#environment-check-script) should contain `MountPropagation is enabled!`.

### Environment check script

We've written a script to help you gather enough information about the factors. Before installing, run:

```shell
curl -sSfL https://raw.githubusercontent.com/longhorn/longhorn/master/scripts/environment_check.sh | bash
```

Example result:

```shell
daemonset.apps/longhorn-environment-check created
waiting for pods to become ready (0/3)
all pods ready (3/3)

  MountPropagation is enabled!

cleaning up...
daemonset.apps "longhorn-environment-check" deleted
clean up complete
```

### Successful CSI deployment example

```shell
$ kubectl -n longhorn-system get pod
NAME                                        READY     STATUS    RESTARTS   AGE
csi-attacher-6fdc77c485-8wlpg               1/1       Running   0          9d
csi-attacher-6fdc77c485-psqlr               1/1       Running   0          9d
csi-attacher-6fdc77c485-wkn69               1/1       Running   0          9d
csi-provisioner-78f7db7d6d-rj9pr            1/1       Running   0          9d
csi-provisioner-78f7db7d6d-sgm6w            1/1       Running   0          9d
csi-provisioner-78f7db7d6d-vnjww            1/1       Running   0          9d
engine-image-ei-6e2b0e32-2p9nk              1/1       Running   0          9d
engine-image-ei-6e2b0e32-s8ggt              1/1       Running   0          9d
engine-image-ei-6e2b0e32-wgkj5              1/1       Running   0          9d
longhorn-csi-plugin-g8r4b                   2/2       Running   0          9d
longhorn-csi-plugin-kbxrl                   2/2       Running   0          9d
longhorn-csi-plugin-wv6sb                   2/2       Running   0          9d
longhorn-driver-deployer-788984b49c-zzk7b   1/1       Running   0          9d
longhorn-manager-nr5rs                      1/1       Running   0          9d
longhorn-manager-rd4k5                      1/1       Running   0          9d
longhorn-manager-snb9t                      1/1       Running   0          9d
longhorn-ui-67b9b6887f-n7x9q                1/1       Running   0          9d
```
