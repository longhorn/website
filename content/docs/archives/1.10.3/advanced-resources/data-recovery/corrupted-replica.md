---
title: Identifying Corrupted Replicas
weight: 3
---

In the case that one of the disks used by Longhorn went bad, you might experience intermittent input/output errors when using a Longhorn volume. 

For example, one file sometimes cannot be read, but later it can. In this scenario, it's likely one of the disks went bad, resulting in one of the replicas returning incorrect data to the user.

To recover the volume, we can identify the corrupted replica and remove it from the volume:

1. Scale down the workload to detach the volume.
2. Find all the replicas' locations by checking the Longhorn UI. The directories used by the replicas will be shown as a tooltip for each replica in the UI.
3. Log in to each node that contains a replica of the volume and get to the directory that contains the replica data.

    For example, the replica might be stored at:
   
        /var/lib/longhorn/replicas/pvc-06b4a8a8-b51d-42c6-a8cc-d8c8d6bc65bc-d890efb2
4. Run a checksum for every file under that directory.

    For example:
    
    ```
    # sha512sum /var/lib/longhorn/replicas/pvc-06b4a8a8-b51d-42c6-a8cc-d8c8d6bc65bc-d890efb2/*
    fcd1b3bb677f63f58a61adcff8df82d0d69b669b36105fc4f39b0baf9aa46ba17bd47a7595336295ef807769a12583d06a8efb6562c093574be7d14ea4d6e5f4  /var/lib/longhorn/replicas/pvc-06b4a8a8-b51d-42c6-a8cc-d8c8d6bc65bc-d890efb2/revision.counter
    c53649bf4ad843dd339d9667b912f51e0a0bb14953ccdc9431f41d46c85301dff4a021a50a0bf431a931a43b16ede5b71057ccadad6cf37a54b2537e696f4780  /var/lib/longhorn/replicas/pvc-06b4a8a8-b51d-42c6-a8cc-d8c8d6bc65bc-d890efb2/volume-head-000.img
    f6cd5e486c88cb66c143913149d55f23e6179701f1b896a1526717402b976ed2ea68fc969caeb120845f016275e0a9a5b319950ae5449837e578665e2ffa82d0  /var/lib/longhorn/replicas/pvc-06b4a8a8-b51d-42c6-a8cc-d8c8d6bc65bc-d890efb2/volume-head-000.img.meta
    e6f6e97a14214aca809a842d42e4319f4623adb8f164f7836e07dc8a3f4816a0389b67c45f7b0d9f833d50a731ae6c4670ba1956833f1feb974d2d12421b03f7  /var/lib/longhorn/replicas/pvc-06b4a8a8-b51d-42c6-a8cc-d8c8d6bc65bc-d890efb2/volume.meta
    ```

5. Compare the output of each replica. One of them should fail or have different results compared to the others. This will be the one replica we need to remove from the volume.
6. Use the Longhorn UI to remove the identified replica from the volume.
7. Scale up the workload to make sure the error is gone.
