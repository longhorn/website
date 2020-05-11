---
  title: Recover Volume after Unexpected Detachment
  weight: 1
---

Longhorn can automatically reattach then remount volumes if an unexpected detachment happens, which can happen during a [Kubernetes upgrade](https://github.com/longhorn/longhorn/issues/703) or a [Docker reboot](https://github.com/longhorn/longhorn/issues/686).

> **Note:** This section assumes familiarity with Linux storage concepts such as attaching and mounting volumes, and [Kubernetes configuration of persistent volume storage.](https://kubernetes.io/docs/tasks/configure-pod-container/configure-persistent-volume-storage/#create-a-pod)

To enable Longhorn to restart workloads after automatically reattaching and remounting volumes

After reattachment and remount are complete, you may need to manually restart the related workload containers for the volume restoration if the following recommended setup is not applied.

- In a **reattachment,** Longhorn will reattach the volume if the volume engine dies unexpectedly.
- In a **remount,** Longhorn will detect and remount the filesystem for the volume after the reattachment.


## Requirements

The auto remount does not work for `xfs` filesystem.

Mounting one more layers with the `xfs` filesystem is not allowed and will trigger the error `XFS (sdb): Filesystem has duplicate UUID <filesystem UUID> - can't mount`.

If you use the `xfs` filesystem, you will need to manually unmount, then mount the `xfs` filesystem on the host. The device path on the host for the attached volume is `/dev/longhorn/<volume name>` . 

## Automatically Remount Volumes and Restart Workloads

In order to recover unexpectedly detached volumes automatically, set `restartPolicy` to `Always`, then add `livenessProbe` for the workloads using Longhorn volumes.

Then those workloads will be restarted automatically after reattachment and remount.

Here is one example for the setup:

```
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: longhorn-volv-pvc
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: longhorn
  resources:
    requests:
      storage: 2Gi
---
apiVersion: v1
kind: Pod
metadata:
  name: volume-test
  namespace: default
spec:
  restartPolicy: Always
  containers:
  - name: volume-test
    image: nginx:stable-alpine
    imagePullPolicy: IfNotPresent
    livenessProbe:
      exec:
        command:
        - ls
        - /data/lost+found
      initialDelaySeconds: 5
      periodSeconds: 5
    volumeMounts:
    - name: volv
      mountPath: /data
    ports:
    - containerPort: 80
  volumes:
  - name: volv
    persistentVolumeClaim:
      claimName: longhorn-volv-pvc
```
- The directory used in the `livenessProbe` will be `<volumeMount.mountPath>/lost+found`
- Don't set a short interval for `livenessProbe.periodSeconds`, e.g., 1s. The liveness command is CPU consuming.

## Manually Restart Workload Containers

This solution is applied only if:

- The Longhorn volume is reattached and remounted automatically.
- The above setup is not included when the related workload is launched. In this case, the [volume mount propagation](https://kubernetes.io/docs/concepts/storage/volumes/#mount-propagation) is not `Bidirectional`, and the Longhorn remount operation won't be propagated to the workload containers if the containers are not restarted.

To restart the workload containers,

1. Figure out on which node the related workload's containers are running
```
kubectl -n <namespace of your workload> get pods <workload's pod name> -o wide
```
2. Connect to the node. e.g., `ssh`
3. Figure out the containers belonging to the workload
```
docker ps
```
By checking the columns `COMMAND` and `NAMES` of the output, you can find the corresponding container

4. Restart the container
```
docker restart <the container ID of the workload>
```