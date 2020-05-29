---
title: Viewing Workloads that Use a Volume
weight: 2
---

Now users can identify current workloads or workload history for existing Longhorn persistent volumes (PVs) and their history of being bound to persistent volume claims (PVCs).

From the Longhorn UI, go to the **Volume** tab. Each Longhorn volume is listed on the page. The **Attached To** column displays the name of the workload using the volume. If you click the workload name, you will be able to see more details, including the workload type, pod name, and status.

Workload information is also available on the Longhorn volume detail page. To see the details, click the volume name:

```
State: attached
...
Namespace:default
PVC Name:longhorn-volv-pvc
PV Name:pvc-0edf00f3-1d67-4783-bbce-27d4458f6db7
PV Status:Bound
Pod Name:teststatefulset-0
Pod Status:Running
Workload Name:teststatefulset
Workload Type:StatefulSet
```

## History

After the a workload is no longer using the Longhorn volume, the volume detail page shows the historical status of the most recent workload that used the volume:

```
Last time used by Pod: a few seconds ago
...
Last Pod Name: teststatefulset-0
Last Workload Name: teststatefulset
Last Workload Type: Statefulset
``` 

If these fields are set, they indicate that currently no workload is using this volume.

When a PVC is no longer bound to the volume, the following status is shown:

```
Last time bound with PVC:a few seconds ago
Last time used by Pod:32 minutes ago
Last Namespace:default
Last Bounded PVC Name:longhorn-volv-pvc
```

If the `Last time bound with PVC` field is set, it indicates currently there is no bound PVC for this volume. The related fields will show the most recent workload using this volume.
