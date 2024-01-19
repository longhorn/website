---
title: Longhorn Metrics for Monitoring
weight: 3
---
## Volume

| Name | Description  | Example |
|---|---|---|
| longhorn_volume_actual_size_bytes | Actual space used by each replica of the volume on the corresponding node | longhorn_volume_actual_size_bytes{pvc_namespace="default",node="worker-2",pvc="testvol",volume="testvol"} 1.1917312e+08 |
| longhorn_volume_capacity_bytes | Configured size in bytes for this volume | longhorn_volume_capacity_bytes{pvc_namespace="default",node="worker-2",pvc="testvol",volume="testvol"} 6.442450944e+09 |
| longhorn_volume_state | State of this volume: 1=creating, 2=attached, 3=Detached, 4=Attaching, 5=Detaching, 6=Deleting | longhorn_volume_state{pvc_namespace="default",node="worker-2",pvc="testvol",volume="testvol"} 2 |
| longhorn_volume_robustness | Robustness of this volume: 0=unknown, 1=healthy, 2=degraded, 3=faulted  | longhorn_volume_robustness{pvc_namespace="default",node="worker-2",pvc="testvol",volume="testvol"} 1 |
| longhorn_volume_read_throughput | Read throughput of this volume (Bytes/s) | longhorn_volume_read_throughput{pvc_namespace="default",node="worker-2",pvc="testvol",volume="testvol"} 5120000 |
| longhorn_volume_write_throughput | Write throughput of this volume (Bytes/s) | longhorn_volume_write_throughput{pvc_namespace="default",node="worker-2",pvc="testvol",volume="testvol"} 512000 |
| longhorn_volume_read_iops | Read IOPS of this volume | longhorn_volume_read_iops{pvc_namespace="default",node="worker-2",pvc="testvol",volume="testvol"} 100 |
| longhorn_volume_write_iops | Write IOPS of this volume | longhorn_volume_write_iops{pvc_namespace="default",node="worker-2",pvc="testvol",volume="testvol"} 100 |
| longhorn_volume_read_latency | Read latency of this volume (ns) | longhorn_volume_read_latency{pvc_namespace="default",node="worker-2",pvc="testvol",volume="testvol"} 100000 |
| longhorn_volume_write_latency | Write latency of this volume (ns) | longhorn_volume_write_latency{pvc_namespace="default",node="worker-2",pvc="testvol",volume="testvol"} 100000 |

## Node

| Name | Description  | Example |
|---|---|---|
| longhorn_node_status | Status of this node: 1=true, 0=false | longhorn_node_status{condition="ready",condition_reason="",node="worker-2"} 1 |
| longhorn_node_count_total | Total number of nodes in the Longhorn system | longhorn_node_count_total 4 |
| longhorn_node_cpu_capacity_millicpu | The maximum allocatable CPU on this node | longhorn_node_cpu_capacity_millicpu{node="worker-2"} 2000 |
| longhorn_node_cpu_usage_millicpu | The CPU usage on this node | longhorn_node_cpu_usage_millicpu{node="pworker-2"} 186 |
| longhorn_node_memory_capacity_bytes | The maximum allocatable memory on this node | longhorn_node_memory_capacity_bytes{node="worker-2"} 4.031229952e+09 |
| longhorn_node_memory_usage_bytes |  The memory usage on this node | longhorn_node_memory_usage_bytes{node="worker-2"} 1.833582592e+09 |
| longhorn_node_storage_capacity_bytes | The storage capacity of this node | longhorn_node_storage_capacity_bytes{node="worker-3"} 8.3987283968e+10 |
| longhorn_node_storage_usage_bytes | The used storage of this node | longhorn_node_storage_usage_bytes{node="worker-3"} 9.060941824e+09 |
| longhorn_node_storage_reservation_bytes | The reserved storage for other applications and system on this node | longhorn_node_storage_reservation_bytes{node="worker-3"} 2.519618519e+10 |

## Disk

| Name | Description  | Example |
|---|---|---|
| longhorn_disk_capacity_bytes | The storage capacity of this disk | longhorn_disk_capacity_bytes{disk="default-disk-8b28ee3134628183",node="worker-3"} 8.3987283968e+10 |
| longhorn_disk_usage_bytes | The used storage of this disk | longhorn_disk_usage_bytes{disk="default-disk-8b28ee3134628183",node="worker-3"} 9.060941824e+09 |
| longhorn_disk_reservation_bytes | The reserved storage for other applications and system on this disk | longhorn_disk_reservation_bytes{disk="default-disk-8b28ee3134628183",node="worker-3"} 2.519618519e+10 |
| longhorn_disk_status | The status of this disk | longhorn_disk_status{condition="ready",condition_reason="",disk="default-disk-ca0300000000",node="worker-3"} |

## Instance Manager

| Name | Description  | Example |
|---|---|---|
| longhorn_instance_manager_cpu_usage_millicpu |  The cpu usage of this longhorn instance manager | longhorn_instance_manager_cpu_usage_millicpu{instance_manager="instance-manager-e-2189ed13",instance_manager_type="engine",node="worker-2"} 80 |
| longhorn_instance_manager_cpu_requests_millicpu | Requested CPU resources in kubernetes of this Longhorn instance manager | longhorn_instance_manager_cpu_requests_millicpu{instance_manager="instance-manager-e-2189ed13",instance_manager_type="engine",node="worker-2"} 250 |
| longhorn_instance_manager_memory_usage_bytes | The memory usage of this longhorn instance manager | longhorn_instance_manager_memory_usage_bytes{instance_manager="instance-manager-e-2189ed13",instance_manager_type="engine",node="worker-2"} 2.4072192e+07 |
| longhorn_instance_manager_memory_requests_bytes | Requested memory in Kubernetes of this longhorn instance manager | longhorn_instance_manager_memory_requests_bytes{instance_manager="instance-manager-e-2189ed13",instance_manager_type="engine",node="worker-2"} 0 |
| longhorn_instance_manager_proxy_grpc_connection | The number of proxy gRPC connection of this longhorn instance manager | longhorn_instance_manager_proxy_grpc_connection{instance_manager="instance-manager-e-814dfd05", instance_manager_type="engine", node="worker-2"} 0

## Manager

| Name | Description  | Example |
|---|---|---|
| longhorn_manager_cpu_usage_millicpu |  The CPU usage of this Longhorn Manager | longhorn_manager_cpu_usage_millicpu{manager="longhorn-manager-5rx2n",node="worker-2"} 27 |
| longhorn_manager_memory_usage_bytes | The memory usage of this Longhorn Manager | longhorn_manager_memory_usage_bytes{manager="longhorn-manager-5rx2n",node="worker-2"} 2.6144768e+07|

## Backup

| Name | Description  | Example |
|---|---|---|
| longhorn_backup_actual_size_bytes | Actual size of this backup | longhorn_backup_actual_size_bytes{backup="backup-4ab66eca0d60473e",volume="testvol"} 6.291456e+07 |
| longhorn_backup_state | State of this backup: 0=New, 1=Pending, 2=InProgress, 3=Completed, 4=Error, 5=Unknown | longhorn_backup_state{backup="backup-4ab66eca0d60473e",volume="testvol"} 3 |

## Snapshot

| Name | Description  | Example |
|---|---|---|
| longhorn_snapshot_actual_size_bytes | Actual size of this snapshot | longhorn_snapshot_actual_size_bytes{snapshot="f4468111-2efa-45f5-aef6-63109e30d92c",user_created="false",volume="testvol"} 1.048576e+07 |
