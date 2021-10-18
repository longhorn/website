---
title: "Troubleshooting: Generate pprof runtime profiling data"
author: Derek Su
draft: false
date: 2021-10-18
categories:
  - "pprof"
---

## Applicable versions

Longhorn >= v1.1.2.

## Symptoms

Not able to investigate the longhorn-manager performance bottlenecks from the external state of the longhorn processes.

## Solution

To invesigate the longhorn-manager performance bottlenecks, the runtime CPU profiling data can be collected by pprof.

1. Forward the port 6060 from the longhorn-manager pod to local port 6060:
   ```
   kubectl port-forward ${pod-name} -n longhorn-system 6060:6060
   ```

2. Collect a 180-second CPU profile:
   ```
   wget -O profile.out "http://localhost:6060/debug/pprof/profile?seconds=180"
   ```

## Related information

* Related Longhorn issue: https://github.com/longhorn/longhorn/issues/2715
