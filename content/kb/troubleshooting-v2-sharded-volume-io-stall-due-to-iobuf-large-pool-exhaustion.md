---
title: "Troubleshooting: V2 Sharded Volume I/O Stalls When Stacked NVMe-oF Targets Exhaust the SPDK iobuf Large Pool"
authors:
- "Chin-Ya Huang"
draft: false
date: 2026-08-25
versions:
- "v1.12.1 and later"
categories:
- "v2 data engine"
- "sharding-storage"
---

## Applicable Versions

- Only v2 sharded volumes (experimental, [longhorn/longhorn#1061](https://github.com/longhorn/longhorn/issues/1061)) are affected. Their data path is the only one that stacks three NVMe-oF targets in one `spdk_tgt` process.
- The workaround requires the `data-engine-iobuf-large-pool-size` setting, available since Longhorn v1.12.1.

## Symptoms

- Workload I/O on a v2 sharded volume stops making progress. `fio` or the application sits in the `D` (uninterruptible sleep) state.
- Nothing is logged by the instance manager, the engine, or the kernel when the stall begins. The first visible event comes when the host NVMe `io_timeout` expires (30 seconds by default): the kernel resets the controller, and a disconnect and reconnect loop follows.
- The stall does not resolve on its own, and the `D` state also blocks pod deletion: the workload pod stays in `Terminating`.

## Root Cause

Every NVMe-oF target in an SPDK process draws payload buffers from the [same per-process pool](https://github.com/longhorn/spdk/blob/324634bf30515f64f1cf8812d604f3a58e66e605/lib/nvmf/transport.c#L195-L204), the iobuf large pool: by default [1024 buffers](https://github.com/longhorn/spdk/blob/324634bf30515f64f1cf8812d604f3a58e66e605/lib/thread/iobuf.c#L15) of [132 KiB](https://github.com/longhorn/spdk/blob/324634bf30515f64f1cf8812d604f3a58e66e605/lib/thread/iobuf.c#L24). A target [takes a buffer when it starts a request](https://github.com/longhorn/spdk/blob/324634bf30515f64f1cf8812d604f3a58e66e605/lib/nvmf/tcp.c#L2726) and [returns it only when the request completes](https://github.com/longhorn/spdk/blob/324634bf30515f64f1cf8812d604f3a58e66e605/lib/nvmf/tcp.c#L3331-L3347). A request carries [at most 128 KiB](https://github.com/longhorn/spdk/blob/324634bf30515f64f1cf8812d604f3a58e66e605/lib/nvmf/tcp.c#L45), so one started request pins one buffer.

The v2 sharded data path stacks three NVMe-oF targets inside one `spdk_tgt` process on the engine node, and all three draw from that one pool:

```
workload (kernel NVMe initiator)
  |
  v
instance-manager pod: one spdk_tgt process, ONE shared iobuf large pool (1024)

  frontend target ............ holds buffers for every started write
    -> raid1 bdev
    -> NVMe-oF loopback hop 1
  ShardGroup target .......... holds more buffers for the same payloads
    -> head lvol -> lvstore -> EC bdev
    -> NVMe-oF loopback hop 2
  local shard target ......... needs buffers to START each shard write
    -> shard lvol -> disk

(remote shards are served by other nodes and use their own pools)
```

The same payload claims a buffer at every hop. Under a deep queue, the upper two targets can hold the entire pool while their writes wait on the bottom target. The bottom target cannot start those writes without a buffer, and no buffer is freed until some request completes. Every request that could complete is waiting on the bottom target, so nothing completes, nothing is freed, and the volume stalls permanently.

Waiting for a buffer is [normal SPDK flow control, not an error path](https://github.com/longhorn/spdk/blob/324634bf30515f64f1cf8812d604f3a58e66e605/lib/thread/iobuf.c#L724-L729), so nothing is logged. The deadlock stops only the I/O requests; the `spdk_tgt` process itself keeps running normally. That is why the Diagnosis commands below still work during the stall, and why the kernel's reconnects in Symptoms succeed without ever reviving the I/O.

## Diagnosis

Two checks: first that I/O is stuck inside the SPDK target, then that the iobuf pool is the blocker, because other causes can look the same at the first level.

### Check 1: is I/O stuck inside the SPDK target?

Run the script below from a machine with `kubectl` and `python3` while the workload is writing. The header comment explains what it does and how to read the result.

```bash
#!/bin/bash
#
# check-ec-io-progress.sh
#
# Checks if I/O is still moving inside the SPDK target of a Longhorn v2
# (EC) volume.
#
# What it does:
#   1. Finds the instance-manager pod that runs the volume, from the
#      engine CR.
#   2. Reads the I/O counters of every bdev in that pod.
#   3. Waits a few seconds.
#   4. Reads the counters again and compares.
#
# While a workload (for example fio) is writing to the volume, the
# counters must go up. If none of them change, the I/O is stuck inside
# the SPDK target. This is the symptom of longhorn/longhorn#13789.
#
# How to run:
#   Start fio against the volume, then run this script while fio is
#   still running:
#
#     ./check-ec-io-progress.sh [instance-manager-pod-name]
#
#   If you do not give a pod name, the script uses the pod named by the
#   first engine CR.
#
# Exit codes:
#   0  counters moved: I/O is working (PASS)
#   1  counters did not move: I/O is stuck (FAIL)
#   2  could not run the check (pod not found, RPC failed, ...)
#
# Files written to the current directory:
#   iostat-1.json, iostat-2.json, bdevs.json

set -uo pipefail

NAMESPACE="${NAMESPACE:-longhorn-system}"
SPDK_SOCK="${SPDK_SOCK:-/var/tmp/spdk.sock}"
INTERVAL="${INTERVAL:-5}"

# The engine CR names the instance-manager pod that runs the volume.
IM="${1:-}"
if [ -z "$IM" ]; then
    IM=$(kubectl -n "$NAMESPACE" get engines.longhorn.io \
        -o jsonpath='{.items[0].status.instanceManagerName}') || true
fi
if [ -z "$IM" ]; then
    echo "ERROR: could not find the instance-manager pod." >&2
    echo "Is the volume attached? You can also pass the pod name as an argument." >&2
    exit 2
fi
echo "Instance manager pod: $IM"
echo "Wait between samples: ${INTERVAL}s"
echo

# Send one JSON-RPC call to spdk_tgt through its unix socket.
# The pod image does not ship the rpc.py python package, so this talks
# to the socket directly.
spdk_rpc() {
    kubectl -n "$NAMESPACE" exec "$IM" -- python3 -c '
import socket, json, sys
s = socket.socket(socket.AF_UNIX)
s.connect(sys.argv[2])
req = {"jsonrpc": "2.0", "id": 1, "method": sys.argv[1], "params": {}}
s.sendall(json.dumps(req).encode())
buf = b""
while True:
    buf += s.recv(1 << 16)
    try:
        resp = json.loads(buf)
        break
    except ValueError:
        pass
if "error" in resp:
    sys.stderr.write("RPC error: %s\n" % resp["error"])
    sys.exit(1)
print(json.dumps(resp["result"], indent=1))
' "$1" "$SPDK_SOCK"
}

echo "Taking first sample..."
spdk_rpc bdev_get_iostat > iostat-1.json || exit 2
sleep "$INTERVAL"
echo "Taking second sample..."
spdk_rpc bdev_get_iostat > iostat-2.json || exit 2
spdk_rpc bdev_get_bdevs > bdevs.json || exit 2
echo

# Compare the two samples. The dR/dW/dU columns show how many reads,
# writes, and unmaps finished between the two samples. The WHAT IS THIS
# column explains the job of each bdev, taken from bdevs.json.
python3 - iostat-1.json iostat-2.json bdevs.json <<'EOF'
import json, sys

def load_iostat(path):
    with open(path) as f:
        return {b["name"]: b for b in json.load(f)["bdevs"]}

first = load_iostat(sys.argv[1])
second = load_iostat(sys.argv[2])
with open(sys.argv[3]) as f:
    details = {b["name"]: b for b in json.load(f)}

def describe(name):
    b = details.get(name)
    if b is None:
        return "unknown (not in bdevs.json)"
    product = b.get("product_name", "")
    if product == "ErasureCode Volume":
        return "EC bdev: splits each write into data+parity pieces, one per shard"
    if product == "Logical Volume":
        base = b.get("driver_specific", {}).get("lvol", {}).get("base_bdev", "?")
        if details.get(base, {}).get("product_name") == "ErasureCode Volume":
            return f"volume data, stored on the EC bdev ({base})"
        return f"logical volume on disk ({base})"
    if product == "NVMe disk":
        if name.startswith("shard-shard-"):
            return "one shard of the EC group (a piece on one disk, attached over NVMe-oF)"
        return "NVMe connection to another exported bdev"
    if product in ("AIO disk", "URING bdev"):
        return "physical disk"
    return product

has_ec = any(b.get("product_name") == "ErasureCode Volume"
             for b in details.values())

header = (f"{'BDEV':40s} {'WRITES':>10} {'UNMAPS':>7} "
          f"{'dR':>5} {'dW':>5} {'dU':>4}  WHAT IS THIS")
print(header)
print("-" * 120)

ops_finished = 0
for name in sorted(second):
    now = second[name]
    before = first.get(name, now)
    w = now["num_write_ops"]
    u = now.get("num_unmap_ops", 0)
    dr = now["num_read_ops"] - before["num_read_ops"]
    dw = w - before["num_write_ops"]
    du = u - before.get("num_unmap_ops", 0)
    ops_finished += dr + dw + du
    print(f"{name:40s} {w:>10} {u:>7} {dr:>5} {dw:>5} {du:>4}  {describe(name)}")

print()
print("How to read this:")
print("  WRITES/UNMAPS are totals since the SPDK target started.")
print("  dR/dW/dU are how many reads/writes/unmaps finished during the")
print("  wait between the two samples.")
print()
print("  The I/O path is: volume data -> EC bdev -> shards.")
print("  The EC bdev splits each write into pieces and sends one piece")
print("  to each shard. Each shard lives on a different disk.")
print("  While fio is writing, dW must be above zero on every step of")
print("  this path. All zeros means the I/O is stuck.")
print()

if not has_ec:
    print("RESULT: ERROR - this pod has no EC bdev. Wrong pod, or the EC")
    print("volume is not attached. Pass the right pod name as an argument.")
    sys.exit(2)
if ops_finished == 0:
    print("RESULT: FAIL - no I/O finished between the two samples.")
    print("If a workload is still writing to the volume, the I/O is stuck")
    print("inside the SPDK target (issue 13789 symptom).")
    sys.exit(1)
print(f"RESULT: PASS - I/O is working ({ops_finished} ops finished in the interval).")
EOF
```

`RESULT: FAIL` means no I/O finished inside the target during the interval (the output explains how to read the per-bdev columns). Continue with check 2.

### Check 2: is the pool the blocker?

Send the `iobuf_get_stats` RPC raw, the same way the check 1 script does, using the pod name it reported:

```bash
IM=<instance-manager pod reported by check 1>
rpc() {
  kubectl -n longhorn-system exec "$IM" -- python3 -c '
import socket, json, sys
s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
s.connect("/var/tmp/spdk.sock")
req = {"jsonrpc": "2.0", "id": 1, "method": sys.argv[1]}
if len(sys.argv) > 2:
    req["params"] = json.loads(sys.argv[2])
s.sendall(json.dumps(req).encode())
reply = b""
while True:
    reply += s.recv(65536)
    try:
        print(json.dumps(json.loads(reply.decode()), indent=2))
        break
    except ValueError:
        pass
' "$@"
}

rpc iobuf_get_stats; sleep 5; rpc iobuf_get_stats
```

In the output, find the `retry` counter under `large_pool` in the `nvmf_TCP` module. It increments each time a request has to wait for a buffer. Compare the two samples:

- Nonzero and unchanged: no buffer was freed during the wait. This is the deadlock described here.
- Growing: buffers are still being freed and I/O still completes, just slowly. The pool is too small for the load; raising the pool size helps, but this is not the permanent stall described here.
- 0 in both samples: the pool is not the blocker. The stall has another cause, such as the EC-layer race fixed in [longhorn/spdk#78](https://github.com/longhorn/spdk/pull/78).

## Workaround

Raise the [Data Engine iobuf Large Pool Size](https://longhorn.io/docs/1.13.0/references/settings/#data-engine-iobuf-large-pool-size) setting (`data-engine-iobuf-large-pool-size`) so the pool covers the worst-case demand of all NVMe-oF targets in one `spdk_tgt` process.

### Step 1: calculate the value

Run the script below while the volumes are attached. It asks SPDK for the worst-case number of in-flight writes each instance-manager pod can have, sizes the pool for it with 20% headroom, and prints the `kubectl patch` command for the setting.

```bash
#!/bin/bash
#
# calc-iobuf-pool-size.sh
#
# Purpose:
#   Each SPDK process has one shared pool of "large" I/O buffers (132 KiB each,
#   default count 1024). Every in-flight NVMe-oF write holds one buffer until it
#   completes. If all targets in one instance-manager pod can together have more
#   writes in flight than the pool holds, the pool can run dry and the pod
#   deadlocks (longhorn/longhorn#13789).
#
# What this script does:
#   1. For every instance-manager pod, ask SPDK two questions:
#        - how many I/O queue pairs exist (nvmf_get_stats)
#        - how deep each queue pair is   (nvmf_get_transports)
#   2. Worst case buffers needed = queue_pairs x queue_depth x buffers_per_write
#   3. Add 20% headroom, round up to a power of two.
#   4. Print the largest result as the value for the cluster-wide setting
#      data-engine-iobuf-large-pool-size.
#
# Run this while the volumes are attached.

NS=longhorn-system
BIGGEST_RECOMMENDATION=1024   # SPDK default; never recommend below it

# Runs inside one IM pod. Talks raw JSON-RPC to the SPDK unix socket
POD_SCRIPT='
import socket, json

def rpc(method):
    s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    s.connect("/var/tmp/spdk.sock")
    s.sendall(json.dumps({"jsonrpc": "2.0", "id": 1, "method": method}).encode())
    reply = b""
    while True:
        reply += s.recv(65536)
        try:
            return json.loads(reply.decode())["result"]
        except ValueError:
            continue  # reply not complete yet, keep reading

# Step 1: how many I/O queue pairs does this pod serve?
# io_qpairs never decreases and reconnects count again, so this
# may overestimate the demand but never underestimates it.
poll_groups = rpc("nvmf_get_stats")["poll_groups"]
queue_pairs = sum(pg["io_qpairs"] for pg in poll_groups)

# Step 2: how many writes can each queue pair have in flight,
# and how many buffers does one write hold?
tcp = next(t for t in rpc("nvmf_get_transports") if t["trtype"].lower() == "tcp")
queue_depth = tcp["max_queue_depth"]
buffers_per_write = (tcp["max_io_size"] + tcp["io_unit_size"] - 1) // tcp["io_unit_size"]

# Step 3: worst case demand, plus 20% headroom, rounded up to a power of two.
worst_case = queue_pairs * queue_depth * buffers_per_write
with_headroom = int(worst_case * 1.2)
recommended = 1
while recommended < with_headroom:
    recommended *= 2

print("queue pairs (high-water):  %d" % queue_pairs)
print("queue depth:               %d" % queue_depth)
print("buffers per write:         %d" % buffers_per_write)
print("worst-case buffers needed: %d" % worst_case)
print("recommended:               %d  (uses %d MiB of hugepages)"
      % (recommended, recommended * 132 // 1024))
'

IM_PODS=$(kubectl get pods -n "$NS" -l longhorn.io/component=instance-manager \
          -o jsonpath='{.items[*].metadata.name}')

for POD in $IM_PODS; do
    echo "=== $POD ==="
    if OUTPUT=$(kubectl exec -n "$NS" "$POD" -- python3 -c "$POD_SCRIPT" 2>/dev/null); then
        echo "$OUTPUT"
        POD_RECOMMENDATION=$(echo "$OUTPUT" | awk '/^recommended:/ {print $2}')
        if [ "$POD_RECOMMENDATION" -gt "$BIGGEST_RECOMMENDATION" ]; then
            BIGGEST_RECOMMENDATION=$POD_RECOMMENDATION
        fi
    else
        echo "(skipped: pod serves no instances, no spdk.sock)"
    fi
    echo
done

echo "==================================================================="
CURRENT_SETTING=$(kubectl -n "$NS" get settings.longhorn.io \
                  data-engine-iobuf-large-pool-size -o jsonpath='{.value}' 2>/dev/null)
echo "Current setting:        ${CURRENT_SETTING:-<unset, SPDK default 1024>}"
echo "Recommended (max pod):  $BIGGEST_RECOMMENDATION"

if [ "$BIGGEST_RECOMMENDATION" -le 1024 ]; then
    echo "The default already covers this topology. No change needed."
    exit 0
fi

echo
echo "Apply with:"
echo "  kubectl -n $NS patch settings.longhorn.io data-engine-iobuf-large-pool-size \\"
echo "    --type merge -p '{\"value\":\"{\\\"v2\\\":\\\"$BIGGEST_RECOMMENDATION\\\"}\"}'"
```

### Step 2: apply it

Run the `kubectl patch` command the script printed.

> **Warning: Hugepage Memory Budget**
> Each buffer is 132 KiB, meaning a pool of 4096 uses 528 MiB of hugepage memory. This memory is taken from the fixed [Data Engine Memory Size](https://longhorn.io/docs/1.13.0/references/settings/#data-engine-memory-size) budget. If the larger pool no longer fits within that budget, you must increase the memory setting. Doing so grows the instance-manager pod's hugepage request by the same amount, so make sure the node has enough hugepages allocated to cover it. **If the node lacks sufficient hugepages, Longhorn will refuse to recreate the instance-manager pod.**

> **Note on application timing:**
> The pool is sized when `spdk_tgt` starts, so each instance-manager pod picks up the new value only when its pod is recreated.
> * Longhorn recreates pods with no running instances automatically.
> * A pod currently serving volumes keeps the old size until you detach the volumes on that node or manually delete the pod.

### Step 3: verify

Rerun the workload and repeat Diagnosis Check 2. With a sufficient pool, the `large_pool` `retry` counter will stay at `0`.

## Why Raising the Pool Is a Workaround, Not the Fix

A larger pool only moves the threshold. The structural cause remains: one payload crosses several NVMe-oF loopback hops inside one process and claims a buffer at every hop. Removing the loopback hops between co-located components is the real fix; that work is tracked in [longhorn/longhorn#13827](https://github.com/longhorn/longhorn/issues/13827).

## Related Information

- Issue: [longhorn/longhorn#13789](https://github.com/longhorn/longhorn/issues/13789)
- Structural fix, reducing the stacked NVMe-oF hops: [longhorn/longhorn#13827](https://github.com/longhorn/longhorn/issues/13827)
- V2 sharding feature: [longhorn/longhorn#1061](https://github.com/longhorn/longhorn/issues/1061)
