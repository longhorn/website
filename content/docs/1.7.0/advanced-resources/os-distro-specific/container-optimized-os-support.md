---
title:  Container-Optimized OS (COS) Support
weight: 5
---

## Requirements

> **Note:**
> Longhorn currently supports Container-Optimized OS only when used as the base image for Google Kubernetes Engine (GKE), which includes a pre-configured Kubernetes environment. The following information may not apply to manually created Kubernetes environments, including Kubernetes provisioned with other orchestrators.

The [Container-Optimized OS (COS)](https://cloud.google.com/container-optimized-os/docs) does not include a package manager and does not allow non-containerized applications to run. Additionally, its root filesystem is mounted as read-only, which poses a challenge for IO operations.

In GKE, Kubernetes tackles these constraints by housing necessary dependencies in a chroot environment (`/home/kubernetes/containerized_mounter/rootfs`) and mounting directories within it, enabling the execution of required tasks.

Longhorn provides a GKE COS node agent daemonset, which leverages GKE Kubernetes solutions to configure and run necessary dependencies. This agent is responsible for the following operations:

- Mounting the Longhorn data path.
- Loading the kernel module.
- Installing and running the iSCSI daemon.

## GKE COS Node Agent Installation
1. Configure the Longhorn GKE COS node agent. You can use the default settings, if applicable.
    > **Tip:**
    > You can use a comma-separated list when specifying values for the `node-agent` container's environment variable (`LONGHORN_DATA_PATHS`).
    >
    > Example:
    >
    > ```yaml
    >  containers:
    >    - name: node-agent
    >      env:
    >        - name: LONGHORN_DATA_PATHS
    >          value: /var/lib/longhorn1,/var/lib/longhorn2


1. Install the Longhorn GKE COS node agent.
    ```
    kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/v{{< current-version >}}/deploy/prerequisite/longhorn-gke-cos-node-agent.yaml
    ```

1. Check the agent pod's status.
    Example:
    ```
    $ kubectl get pod -l app=longhorn-gke-cos-node
    NAME                                READY   STATUS    RESTARTS      AGE
    longhorn-gke-cos-node-agent-222w8   1/1     Running   1 (86m ago)   86m
    longhorn-gke-cos-node-agent-8r26h   1/1     Running   1 (86m ago)   86m
    longhorn-gke-cos-node-agent-nwhsw   1/1     Running   1 (86m ago)   86m
    ```

1. Check the installation result in the agent pod logs.
    ```
    Completed!
    Keep the container running for iscsi daemon
    ```
    > **Note:**
    > The agent installs the iSCSI daemon (iscsid) in a container using a package manager. However, the package manager attempts to initiate iSCSI services through systemd, which the container environment does not fully support. As a result, you will likely see error logs similar to `System has not been booted with systemd as init system (PID 1). Can't operate`. To work around this, the script manually starts the daemon instead of relying on systemd. You can disregard the mentioned errors in this context.

1. Verify that the dependent kernel module is loaded. You must run the command on the host.
    ```
    $ lsmod | grep -q iscsi_tcp && echo "The iSCSI module is loaded" || echo "The iSCSI module is NOT loaded"
    The iSCSI module is loaded
    ```

1. Verify that the iSCSI daemon is running. You must run the command on the host.
    ```
    $ ps aux | grep -q '[i]scsid' && echo "The iSCSI daemon is running" || echo "The iSCSI daemon is NOT running"
    The iSCSI daemon is running
    ```

1. Verify that the Longhorn data path (`/var/lib/longhorn`) is mounted on the host. If you specified multiple Longhorn data paths, run the command for each path on the host.
    ```
    $ findmnt --noheadings "/var/lib/longhorn"
    /var/lib/longhorn /dev/sda1[/var/lib/longhorn] ext4   rw,relatime,commit=30
    ```

## Limitations

In COS clusters, Longhorn currently supports only V1 data volumes.

## References

- [[FEATURE] Container-Optimized OS support](https://github.com/longhorn/longhorn/issues/6165)