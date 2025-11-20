---
title: Longhorn Metrics for Monitoring
weight: 3
---
## Volume

| Name | Description  | Example |
|---|---|---|
| longhorn_volume_actual_size_bytes | Actual space used by each replica of the volume on the corresponding node | longhorn_volume_actual_size_bytes{pvc_namespace="default",node="worker-2",pvc="testvol",volume="testvol"} 1.1917312e+08 |
| longhorn_volume_capacity_bytes | Configured size in bytes for this volume | longhorn_volume_capacity_bytes{pvc_namespace="default",node="worker-2",pvc="testvol",volume="testvol"} 6.442450944e+09 |
| longhorn_volume_state | Volume state. This metric uses the `state` label to indicate the current volume state. The value is 1 for the current state and 0 for others. States: creating, attached, detached, attaching, detaching, deleting | longhorn_volume_state{pvc_namespace="default",node="worker-2",pvc="testvol",volume="testvol",state="attached"} 1 |
| longhorn_volume_robustness | Volume robustness. This metric uses the `state` label to indicate the current robustness. The value is 1 for the current state and 0 for others. States: unknown, healthy, degraded, faulted | longhorn_volume_robustness{pvc_namespace="default",node="worker-2",pvc="testvol",volume="testvol",state="healthy"} 1 |
| longhorn_volume_read_throughput | Read throughput of this volume (Bytes/s) | longhorn_volume_read_throughput{pvc_namespace="default",node="worker-2",pvc="testvol",volume="testvol"} 5120000 |
| longhorn_volume_write_throughput | Write throughput of this volume (Bytes/s) | longhorn_volume_write_throughput{pvc_namespace="default",node="worker-2",pvc="testvol",volume="testvol"} 512000 |
| longhorn_volume_read_iops | Read IOPS of this volume | longhorn_volume_read_iops{pvc_namespace="default",node="worker-2",pvc="testvol",volume="testvol"} 100 |
| longhorn_volume_write_iops | Write IOPS of this volume | longhorn_volume_write_iops{pvc_namespace="default",node="worker-2",pvc="testvol",volume="testvol"} 100 |
| longhorn_volume_read_latency | Read latency of this volume (ns) | longhorn_volume_read_latency{pvc_namespace="default",node="worker-2",pvc="testvol",volume="testvol"} 100000 |
| longhorn_volume_write_latency | Write latency of this volume (ns) | longhorn_volume_write_latency{pvc_namespace="default",node="worker-2",pvc="testvol",volume="testvol"} 100000 |
| longhorn_volume_file_system_read_only | This metric indicates that the volume is now in read-only mode. The metric is either 1 or no record for each volume | longhorn_volume_file_system_read_only{node="worker-2",pvc="testvol",pvc_namespace="default",volume="testvol"} 1

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

## Replica

| Name | Description | Example |
|---|---|---|
| longhorn_replica_info | Static metadata for each Replica CR | longhorn_replica_info{replica="testvol-r-abc", volume="testvol", node="node-1", disk_path="/dev/xda", data_engine="v2"} 1 |
| longhorn_replica_state | Current runtime state of the replica: running, stopped, error, starting, stopping, unknown | longhorn_replica_state{replica="testvol-r-abc", volume="testvol", node="node-1", state="running"} 1 |

## Engine

| Name | Description | Example |
|---|---|---|
| longhorn_engine_info | Static metadata for each Engine CR | longhorn_engine_info{engine="testvol-e-0", volume="testvol", node="node-1", data_engine="v2", frontend="blockdev", image="longhorn-instance-manager:latest"} 1 |
| longhorn_engine_state | Runtime state of an engine: running, stopped, error, starting, stopping, unknown | longhorn_engine_state{engine="testvol-e-0", volume="testvol", node="node-1", state="running"} 1 |
| longhorn_engine_replica_mode | The mode reported for each replica by the engine: RW, WO, ERR | longhorn_engine_replica_mode{volume="testvol", engine="testvol-e-0", replica="testvol-r-abc", mode="RW"} 1 |
| longhorn_engine_rebuild_progress | Engine rebuild progress (0–100%). Visible only during replica rebuilding. | longhorn_engine_rebuild_progress{pvc_namespace="default",pvc="testvol",engine="testvol-e-0",rebuild_src="10.42.1.215:20036",rebuild_dst="10.42.0.131:20922"} 42 |

## Disk

| Name | Description  | Example |
|---|---|---|
| longhorn_disk_capacity_bytes | The storage capacity of this disk | longhorn_disk_capacity_bytes{disk="default-disk-8b28ee3134628183",node="worker-3"} 8.3987283968e+10 |
| longhorn_disk_usage_bytes | The used storage of this disk | longhorn_disk_usage_bytes{disk="default-disk-8b28ee3134628183",node="worker-3"} 9.060941824e+09 |
| longhorn_disk_reservation_bytes | The reserved storage for other applications and system on this disk | longhorn_disk_reservation_bytes{disk="default-disk-8b28ee3134628183",node="worker-3"} 2.519618519e+10 |
| longhorn_disk_status | The status of this disk | longhorn_disk_status{condition="ready",condition_reason="",disk="default-disk-ca0300000000",node="worker-3"} |
| longhorn_disk_read_throughput | Read throughput of this disk (Bytes/s) | longhorn_disk_read_throughput{disk="default-disk-8b28ee3134628183",node="worker-3",disk_path="/dev/sda"} 10485760 |
| longhorn_disk_write_throughput | Write throughput of this disk (Bytes/s) | longhorn_disk_write_throughput{disk="default-disk-8b28ee3134628183",node="worker-3",disk_path="/dev/sda"} 2097152 |
| longhorn_disk_read_iops | Read IOPS of this disk | longhorn_disk_read_iops{disk="default-disk-8b28ee3134628183",node="worker-3",disk_path="/dev/sda"} 200 |
| longhorn_disk_write_iops | Write IOPS of this disk | longhorn_disk_write_iops{disk="default-disk-8b28ee3134628183",node="worker-3",disk_path="/dev/sda"} 150 |
| longhorn_disk_read_latency | Read latency of this disk (nanoseconds) | longhorn_disk_read_latency{disk="default-disk-8b28ee3134628183",node="worker-3",disk_path="/dev/sda"} 85000 |
| longhorn_disk_write_latency | Write latency of this disk (nanoseconds) | longhorn_disk_write_latency{disk="default-disk-8b28ee3134628183",node="worker-3",disk_path="/dev/sda"} 95000 |


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
| longhorn_backup_actual_size_bytes | Actual size of this backup | longhorn_backup_actual_size_bytes{backup="backup-4ab66eca0d60473e",volume="testvol", recurring_job="backup"} 6.291456e+07 |
| longhorn_backup_state | State of this backup: 0=New, 1=Pending, 2=InProgress, 3=Completed, 4=Error, 5=Unknown | longhorn_backup_state{backup="backup-4ab66eca0d60473e",volume="testvol", recurring_job=""} 3 |

## Snapshot

| Name | Description  | Example |
|---|---|---|
| longhorn_snapshot_actual_size_bytes | Actual size of this snapshot | longhorn_snapshot_actual_size_bytes{snapshot="f4468111-2efa-45f5-aef6-63109e30d92c",user_created="false",volume="testvol"} 1.048576e+07 |


## BackingImage

| Name | Description  | Example |
|---|---|---|
| longhorn_backing_image_actual_size_bytes | Actual size of this backing image | longhorn_backing_image_actual_size_bytes{backing_image="parrot",disk="ca203ce8-2cad-4cd1-92a7-542851f50518",node="kworker1"} 3.3554432e+07 |
| longhorn_backing_image_state | State of this backing image: 0=Pending, 1=Starting, 2=InProgress, 3=ReadyForTransfer, 4=Ready, 5=Failed, 6=FailedAndCleanUp, 7=Unknown | longhorn_backing_image_state{backing_image="parrot",disk="ca203ce8-2cad-4cd1-92a7-542851f50518",node="kworker1"} 4 |

## BackupBackingImage

| Name | Description  | Example |
|---|---|---|
| longhorn_backup_backing_image_actual_size_bytes | Actual size of this backup backing image | longhorn_backup_backing_image_actual_size_bytes{backup_backing_image="parrot"} 3.3554432e+07 |
| longhorn_backup_backing_image_state | State of this backup backing image: 0=New, 1=Pending, 2=InProgress, 3=Completed, 4=Error, 5=Unknown | longhorn_backup_backing_image_state{backup_backing_image="parrot"} 3 |

## CSI

The CSI sidecar component has built-in metrics for users to get insights into CSI operations. The CSI operations metrics cover total count, error count, and call latency. Longhorn enables the metrics by adding the flag `--http-endpoint` for each CSI sidecar component. You can use [Prometheus's PodMonitor](https://github.com/prometheus-operator/prometheus-operator/blob/main/Documentation/api.md#podmonitor) to collect these metrics. 

| Name | Port |
|---|---|
| longhorn-csi-attacher | 8000 | 
| longhorn-csi-provisioner | 8000 |
| longhorn-csi-resizer | 8000 |
| longhorn-csi-snapshotter | 8000 |

The metrics provided by the CSI sidecar component are provided in a histogram format. For example, you can obtain metrics observing the time it takes to create a Longhorn Volume for the PVC.

```
csi_sidecar_operations_seconds_bucket{driver_name="driver.longhorn.io",grpc_status_code="OK",method_name="/csi.v1.Controller/ControllerPublishVolume",le="0.1"} 0
csi_sidecar_operations_seconds_bucket{driver_name="driver.longhorn.io",grpc_status_code="OK",method_name="/csi.v1.Controller/ControllerPublishVolume",le="0.25"} 0
csi_sidecar_operations_seconds_bucket{driver_name="driver.longhorn.io",grpc_status_code="OK",method_name="/csi.v1.Controller/ControllerPublishVolume",le="0.5"} 0
csi_sidecar_operations_seconds_bucket{driver_name="driver.longhorn.io",grpc_status_code="OK",method_name="/csi.v1.Controller/ControllerPublishVolume",le="1"} 0
csi_sidecar_operations_seconds_bucket{driver_name="driver.longhorn.io",grpc_status_code="OK",method_name="/csi.v1.Controller/ControllerPublishVolume",le="2.5"} 3
csi_sidecar_operations_seconds_bucket{driver_name="driver.longhorn.io",grpc_status_code="OK",method_name="/csi.v1.Controller/ControllerPublishVolume",le="5"} 3
csi_sidecar_operations_seconds_bucket{driver_name="driver.longhorn.io",grpc_status_code="OK",method_name="/csi.v1.Controller/ControllerPublishVolume",le="10"} 3
csi_sidecar_operations_seconds_bucket{driver_name="driver.longhorn.io",grpc_status_code="OK",method_name="/csi.v1.Controller/ControllerPublishVolume",le="15"} 9
csi_sidecar_operations_seconds_bucket{driver_name="driver.longhorn.io",grpc_status_code="OK",method_name="/csi.v1.Controller/ControllerPublishVolume",le="25"} 9
csi_sidecar_operations_seconds_bucket{driver_name="driver.longhorn.io",grpc_status_code="OK",method_name="/csi.v1.Controller/ControllerPublishVolume",le="50"} 9
csi_sidecar_operations_seconds_bucket{driver_name="driver.longhorn.io",grpc_status_code="OK",method_name="/csi.v1.Controller/ControllerPublishVolume",le="120"} 9
csi_sidecar_operations_seconds_bucket{driver_name="driver.longhorn.io",grpc_status_code="OK",method_name="/csi.v1.Controller/ControllerPublishVolume",le="300"} 9
csi_sidecar_operations_seconds_bucket{driver_name="driver.longhorn.io",grpc_status_code="OK",method_name="/csi.v1.Controller/ControllerPublishVolume",le="600"} 9
csi_sidecar_operations_seconds_bucket{driver_name="driver.longhorn.io",grpc_status_code="OK",method_name="/csi.v1.Controller/ControllerPublishVolume",le="+Inf"} 9
csi_sidecar_operations_seconds_sum{driver_name="driver.longhorn.io",grpc_status_code="OK",method_name="/csi.v1.Controller/ControllerPublishVolume"} 66.816478825
csi_sidecar_operations_seconds_count{driver_name="driver.longhorn.io",grpc_status_code="OK",method_name="/csi.v1.Controller/ControllerPublishVolume"} 9
```
