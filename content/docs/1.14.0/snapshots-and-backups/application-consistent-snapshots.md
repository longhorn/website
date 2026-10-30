---
title: Application-Consistent Snapshots
weight: 3
---

A Longhorn snapshot is crash-consistent: it captures only what has reached the volume. The [`freeze-filesystem-for-snapshot`](../../references/settings#freeze-filesystem-for-snapshot) setting freezes the filesystem first, but the application is never asked to pause, so it can be caught mid-operation. It also freezes each volume on its own, so a multi-volume application gets no common point in time.

An application-consistent snapshot closes both gaps. The application is paused, all snapshots are taken, then it is resumed. Together they capture one consistent moment.

Longhorn provides this through snapshot hooks on a [snapshot group](../snapshot-groups). A group created with `hooks: command` runs a pre-command in the application's pods before the snapshots are taken, usually to stop writes, and a post-command after, to resume them. Both commands live in a `VolumeHookPolicy` resource that you create in the application's own namespace.

A snapshot group is application-consistent only when `spec.hooks` is `command` and `status.phase` is `Ready`.

## How It Works

When a hooked group is created, Longhorn pauses the application, takes the member snapshots, and then resumes the application. The group moves through the following phases:

```
RunningPreHooks   pre-commands run in the application's pods,
   |      |       one member at a time, in spec.volumes order
   |      v
   |    Failed    a pre-command failed or the deadline passed;
   |              recorded pods are released
   v
InProgress        member snapshots are taken
   |
   v
Ready | Failed    post-commands run, members in reverse order
```

The commands are run by the hook executor, a dedicated Deployment in `longhorn-system`. It is the only Longhorn component that can run commands in application pods, and only in namespaces where the admin has allowed it.

The post-commands run as soon as the group reaches `Ready` or `Failed`, the group is deleted, or the deadline passes, whichever happens first.

Hooks apply only to a `SnapshotGroup` created with `hooks: command`. Snapshots and backups taken any other way, per volume or by a recurring job, do not run hooks. When a `VolumeHookPolicy` covers such a volume, Longhorn emits a `HookPolicyBypassed` warning so the bypass is visible.

## Prerequisites

The hook executor must have permission to run commands in the application's namespace. Longhorn does not grant this permission itself; the namespace admin must apply the following RoleBinding in the application's namespace:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: longhorn-hook-executor
  namespace: default                   # the application's namespace
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: longhorn-hook-executor
subjects:
- kind: ServiceAccount
  name: longhorn-hook-executor
  namespace: longhorn-system
```

Without this RoleBinding, creating a hooked group that includes a volume from the namespace fails, and the error message includes this manifest.

## Writing Hook Commands

Longhorn runs the commands but cannot verify what they do. It only checks that a command exits with code 0 and that the pod remains unchanged until the snapshots are taken.

- **The pause must last until the snapshots are taken.** The command runs as a process in the pod; a pause that ends with that process, for example a MySQL session lock, is released before the first snapshot.
- **Both commands must be safe to run more than once.** A pod that mounts several member volumes runs them once per member, and a post-command may run again if Longhorn was unable to record that the first run finished, for example after a restart.
- **The post-command must work even if the pre-command never finished.** Longhorn gives up on a slow pre-command but cannot kill it, so the pre-command may still be running when the post-command runs.
- **Both commands must finish their work before they exit.** Exit code 0 tells Longhorn the pause is in place; a command that starts the pause in the background exits too early.

## Create a VolumeHookPolicy

A `VolumeHookPolicy` selects a set of PVCs and defines the commands to run in the pods that mount them. Create the policy in the application's namespace:

```yaml
apiVersion: longhorn.io/v1beta2
kind: VolumeHookPolicy
metadata:
  name: demo
  namespace: default                     # the application's namespace
spec:
  pvcSelector:
    matchLabels: {app-group: demo}       # PVCs in this namespace with this label
  # pvcNames: [data-demo-0]              # or select by name; exactly one of pvcSelector / pvcNames
  hooks:                                 # commands to run in every running pod that uses a selected PVC
  - exec:
      container: app                     # which container runs the commands; required if the pod has more than one
      preCommand:  ['sh', '-c', 'pause.sh -p "$DB_PASS"']
      postCommand: ['sh', '-c', 'resume.sh -p "$DB_PASS"']
```

> **Warning:** Never write a credential into a policy. The exec request's URL, which includes the command, is recorded in the API audit log, and the policy is readable by the built-in `view` role. Instead, pass credentials through the container's environment as shown above: the commands run through `sh -c`, so `$DB_PASS` is expanded inside the pod and the policy stores only the variable name.

A policy with a single unnamed hook, as above, reports it under the name `default` in the group's status and events. A hook runs for both snapshots and backups unless its `operations` list restricts it. Use multiple hooks when pods sharing a volume need different commands. Each hook then needs a `name` and a `podSelector`. Replace the `hooks` list above with:

```yaml
  hooks:
  - name: app-1
    exec:
      podSelector:
        matchLabels: {app: app-1}
      container: app
      preCommand:  ['sh', '-c', 'pause.sh -p "$DB_PASS"']
      postCommand: ['sh', '-c', 'resume.sh -p "$DB_PASS"']
  - name: app-2
    exec:
      podSelector:
        matchLabels: {app: app-2}
      container: app
      preCommand:  ['pause-app-2.sh']
      postCommand: ['resume.sh']
```

Every pod must match exactly one hook. A pod that matches none, or more than one, fails the group with `HookNotMatched`.

## Create the Hooked Group

### With kubectl

Create a `SnapshotGroup` in the `longhorn-system` namespace:

```yaml
apiVersion: longhorn.io/v1beta2
kind: SnapshotGroup
metadata:
  name: demo
  namespace: longhorn-system
spec:
  volumes: [pvc-1f3a2b8c, pvc-8c2e4d9a]  # Longhorn volume names; list order is pause order
  hooks: command                         # none (default) | command
  deadlineSeconds: 60                    # time limit for the pause and the snapshots together
```

- Longhorn pauses members in `volumes` list order and releases them in reverse order. When the order matters, list the volumes explicitly instead of using `volumeSelector`.
- A group created with kubectl always takes snapshots. Pausing for a backup is supported only [through CSI](#through-csi).
- `deadlineSeconds` is the time limit for the pause and the snapshots together. With hooks, the default is 60 and the valid range is 10 to 3600. Size it to roughly the sum of the pre-command times plus the longest single snapshot time. Two things can make a run take longer:
  - Hooks run once per member volume, so a pod that mounts two member volumes runs its pre-command twice.
  - If a pod is shutting down when its turn comes, Longhorn waits for it instead of skipping it, so a rolling restart that overlaps the run can add a full termination grace period.

### Through CSI

Set `hooks: command` and `deadlineSeconds` as parameters on a `VolumeGroupSnapshotClass`. A `VolumeGroupSnapshot` that uses the class creates the hooked group. The class `type` decides what the hooks pause for: `snap` for a snapshot, `bak` for a backup. For details, see [CSI VolumeGroupSnapshot](../csi-snapshot-support/csi-volume-group-snapshot).

A CSI group selects PVCs by label, so its members pause in no particular order. When order matters, create the group [with kubectl](#with-kubectl) instead.

## Check the Group Status

Check the group's progress with kubectl:

```shell
kubectl -n longhorn-system get snapshotgroups
NAME   PHASE   HOOKPROGRESS   READYTOUSE   CREATIONTIME           AGE
demo   Ready   post done      true         2026-10-29T03:28:00Z   1m
```

The `HOOKPROGRESS` column shows how far the hooks have progressed: `pre <done>/<members>` while pausing, `pre done` when every pre-command has run, `post <done>/<pods>` while releasing, and `post done` when every pod has been released. `pre failed` or `post failed <n>/<pods>` means a hook went wrong. To tell whether the group succeeded, check `PHASE`, not `HOOKPROGRESS`.

For the full record, use `kubectl get -o yaml` and read `status.hooks[]`: each member records its PVC and its pods, and each pod records its hook, phase, exit code, and reason. The policy each member used is pinned in `spec.members[].hookPolicyRef`.

The group's events record each step: `PreHooksSucceeded`, `PostHooksSucceeded`, and on problems the events listed in [Troubleshooting](#troubleshooting). A `Ready` group that used over 80% of its deadline also gets a `HookDeadlineNearlyExceeded` event, with a breakdown of where the time went.

## Troubleshooting

Longhorn always attempts to release the application. In the Group column, `Unchanged` means the problem happens during release, after the group has already reached its phase: the snapshots were taken while the application was paused, so a `Ready` group stays `Ready`.

| Situation | Application | Group | Where to look |
|---|---|---|---|
| A member's PVC has no policy or more than one, has no running pod, or its namespace has not allowed the executor | Untouched | Rejected | The creation error message |
| The policy is deleted or edited, or the pod stops running, before the pause starts | Untouched | `Failed` | `PreHookFailed`, member `reason` |
| A member volume, or a pod that mounts one, is already claimed by another hooked group | Untouched | `Failed` | Member `reason`: `VolumeConflict` or `PodConflict` |
| A pre-command fails or hangs | Every recorded pod is resumed | `Failed` | `PreHookFailed`, pod `reason` |
| A pod or container restarts, or a pod is replaced, during the window | Recorded pods are resumed | `Failed` | `(pod-changed)` in `status.error` |
| The snapshots take longer than the deadline | Resumed at the deadline | `Failed` | `HookDeadlineExceeded` |
| A post-command fails or hangs | Release is run up to `hook-release-attempts` times, then left for you to release by hand | Unchanged | `PostHookFailed`, pod `PostFailed` |
| The hook is removed from the policy while the application is paused | Left for you to release by hand | Unchanged | Pod `reason: HookNotFound` |
| The API server, node, or kubelet is unreachable at release time | Stays paused until reachable; retried without limit | Unchanged | `HookReleaseBlocked` |
| The RoleBinding is removed while the application is paused | Stays paused until the admin reapplies it | Unchanged | `HookReleaseBlocked`, with the RoleBinding to apply |

### Manually Release a Paused Pod

After the release finishes, check each pod's phase. `PostDone` means the pod was released; a reason may add detail, such as `PodNotFound` (the pod was already gone) or `PolicyChanged` (the policy changed after the pause, but the release still ran). Only a `PostFailed` pod can still be paused.

To release a `PostFailed` pod manually:

1. Find the policy through the member's `spec.members[].hookPolicyRef`.
2. In the policy, find the hook named by the pod's `hookName`.
3. Run that hook's `postCommand` in its `container`. If the hook does not name a container, the pod has only one eligible container.

When the group has already been deleted (`HookReleaseAbandoned`), there is no member record to read. Find the policy in the pod's namespace that covers its PVC, and the hook that selects the pod; a policy with a single unnamed hook applies to every pod.

If the policy or the hook is gone (`PolicyNotFound`, `HookNotFound`), run the resume command from your own records:

```shell
kubectl exec -n <namespace> <pod> -c <container> -- <postCommand>
```

## Delete a Hooked Group

Deleting a hooked group releases the application first: the post-commands run, and the deletion waits for every recorded pod to be released, for as long as the release settings allow. After that, the group is removed anyway, and a `HookReleaseAbandoned` event names every pod that was not released; release those by hand as described in [Manually Release a Paused Pod](#manually-release-a-paused-pod).

## Configure the Hook Executor

When Longhorn is installed with Helm, the `longhornHookExecutor` values configure the hook executor Deployment. Two of them affect how the feature behaves:

- `replicas` (default `2`): One pod is the active leader and the rest are warm standbys, so when a node fails, a standby takes over instead of leaving the application paused while a new pod starts.
- `pauseWorkers` (default `5`): How many snapshot groups may run their pre-commands at the same time. Post-commands run in a separate pool that is at least as large, so resuming an application never waits behind pause work.

When enabling the `podDisruptionBudget` values, keep `maxUnavailable` at least 1 so a node drain can always proceed while a standby takes over.

For the full list of values, see [Helm Values](../../references/helm-values#longhorn-hook-executor-settings).

## Limitations

- Any pod change during the window fails the group with `(pod-changed)`:
  - A recorded pod restarts, is replaced, or starts terminating.
  - A new pod mounts a member claim.
  - A short-lived pod, such as a Job, mounted a member claim and finished.

  The group fails even when a container restarts after the last snapshot and the data is consistent, because Longhorn cannot verify that. Delete the group and create a new one; a group created through CSI retries automatically.
- Longhorn cannot stop a command after starting it. A command that exceeds its time limit continues running in the pod until it exits.
- A volume can belong to only one hooked group at a time, from the group's creation until every recorded pod is released.

## History

- [GitHub Issue #2128](https://github.com/longhorn/longhorn/issues/2128)

Available since v1.14.0.
