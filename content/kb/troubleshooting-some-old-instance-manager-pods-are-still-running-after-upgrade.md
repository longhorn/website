---
title: "Troubleshooting: Some old instance manager pods are still running after upgrade"
author: Derek Su
draft: false
date: 2021-11-09
categories:
  - "Longhorn Upgrade"
---

## Applicable versions

Longhorn >= v0.8.0.

## Symptoms

Some old instance manager pods are still running after upgrade.

## Details

**This behavior is an expected behavior rather than a bug.** In the following paragraphs, we will explain why.

Let us first take a look of the example. We created a pod with a volume backed by 3 replicas in a Kubernetes cluster with 1 master and 4 workers nodes. The running volume is associated with the engine instance manager pod `instance-manager-e-ec3eb207`.

- Before upgrade, what the current instance manager pods are and which node the volume is on:
```
# kubectl -n longhorn-system get pods --sort-by=.metadata.name -o go-template='{{range .items}}{{.metadata.name}} {{.spec.nodeName}}{{"\n"}}{{end}}' | grep instance-manager

instance-manager-e-1ce9451d worker4
instance-manager-e-7a505ed8 worker2
instance-manager-e-9e3a3735 worker1
instance-manager-e-11d7bb9b worker3
instance-manager-e-ec3eb207 master
instance-manager-r-6ee37472 master
instance-manager-r-38dd4e09 worker3
instance-manager-r-476c588c worker1
instance-manager-r-89006932 worker2
instance-manager-r-fe73789e worker4

# kubectl -n longhorn-system get lhv
NAME                                       STATE      ROBUSTNESS   SCHEDULED   SIZE         NODE          AGE
pvc-6d229727-ab78-4a72-a4db-9a3279086935   attached   healthy      True        2147483648   master        41m
```

- After upgrade, what the current instance manager pods are:
```
# kubectl -n longhorn-system get pods --sort-by=.metadata.name -o go-template='{{range .items}}{{.metadata.name}} {{.spec.nodeName}}{{"\n"}}{{end}}' | grep instance-manager

instance-manager-e-3b116993 worker2
instance-manager-e-3e2c9378 worker4
instance-manager-e-9d47a09c worker1
instance-manager-e-c40c5c0b master
instance-manager-e-ec3eb207 master
instance-manager-e-fdf751f1 worker3
instance-manager-r-1eb97e64 worker2
instance-manager-r-159a9d78 worker4
instance-manager-r-398ef22a worker1
instance-manager-r-24632920 master
instance-manager-r-de4dd72c worker3
```

Longhorn utilizes the cleanup strategy that all non-default old engine and replica instance manager pods (instance-manager-e/r) are cleaned up immediately once no engine and replica processes run in them.

After the engine image of the running volume upgrade, the new replica processes are invoked and run in the new replica instance manager pods.

Then, to avoid interruption of data IO, Longhorn cannot launch a new engine process using the upgraded engine image in the new engine instance manager pod. Instead, the old engine manager pod is still responsible for managing the lifecycle of the new engine process until the volume is detached. Hence, the new engine process is created in the old instance manager pod, `instance-manager-e-ec3eb207`.

After the corresponding new engine process is created, the data path will be switched to the new one, and the old processes will be terminated.

According to the cleanup strategy, the old instance manager pods without running replica and engine processes are cleaned up immediately. Thus, in the above example, all the old instance manager pods are cleaned up, but the old engine instance manager pod, `instance-manager-e-ec3eb207`, still exists for managing the new engine process.

## Tips

- The user can check which volumes are still using the old engine manager pods from `Volume > Name > Volume Details > Instance Manager` on Longhorn UI.

- If the user wants to clean up old instance manager pods, all volumes using the old engine manager pods need to be detached and then perform the live upgrade.

## Related information

[Longhorn issue #2144](https://github.com/longhorn/longhorn/issues/2144)
