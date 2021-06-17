---
title: Profiling
weight: 6
---

Longhorn uses [pprof](https://golang.org/pkg/net/http/pprof/) to sample profiles of the manager application. You will be able to access the profilers remotely with the exported Longhorn backend endpoint or from the cluster.

## Export Endpoint
To sample profilers remotely, the cluster needs to expose the Longhorn backend endpoint first.

Here is an example use `NodePort`.
```
54.151.190.215 # kubectl -n longhorn-system patch svc longhorn-backend -p '{"spec": {"type":"NodePort"}}'
service/longhorn-backend patched (no change)
54.151.190.215 # kubectl -n longhorn-system get svc/longhorn-backend
NAME               TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
longhorn-backend   NodePort   10.43.124.246   <none>        9500:30103/TCP   13m
```
The `longhorn-backend` service is now exported to `30103`, then the available profiles and descriptions are accessible with a web browser at `http://54.151.190.215:30103/debug/pprof`.

Most of the profiler can be opened with the web browser, but they can be hard to read. To make means out of the profiles you can leverage on `go tool pprof` and `go tool trace`.

## Profile Sampling

### URL Interaction
With runtime interactive sampling and analysis, you can access the profiles with `go tool pprof http://<node>:<port>/debug/pprof/<profiler>`, for example:

```
go tool pprof http://54.151.190.215:30103/debug/pprof/heap

go tool pprof http://54.151.190.215:30103/debug/pprof/profile
```

### Save to File
You can also collect and save the profiles for later use with `curl http:/<node>:<longhorn-backend-port>/debug/pprof/<profiler> -o <save>.gz`. For example:
```
curl http://54.151.190.215:30103/debug/pprof/heap -o heap-$(date "+%Y.%m.%d-%H.%M.%S").gz
```
