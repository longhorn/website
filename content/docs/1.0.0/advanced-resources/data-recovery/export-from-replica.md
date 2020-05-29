---
title: Exporting a Volume from a Single Replica
weight: 2
---

Each replica of a Longhorn volume contains the full data for the volume.

If the whole Kubernetes cluster or Longhorn system goes offline, the following steps can be used to retrieve the data of the volume.

1. Identify the volume.

    Longhorn uses the disks on the node to store the replica data.
    
    By default, the data is stored at the directory specified by the setting [`Default Data Path`](https://longhorn.io/docs/0.8.1/references/settings/#default-data-path).
    
    More disks can be added to a node by either using the Longhorn UI or by using [a node label and annotation](../../default-disk-and-node-config/).

    You can either keep a copy of the path of those disks, or use the following command to find the disks that have been used by Longhorn. For example:
    
    ```
    # find / -name longhorn-disk.cfg
    /var/lib/longhorn/longhorn-disk.cfg
    ```

    The result above shows that the path `/var/lib/longhorn` has been used by Longhorn to store data.

2. Check the path found in step 1 to see if it contains the data.

    The data will be stored in the `/replicas` directory, for example:

    ```
    # ls /var/lib/longhorn/replicas/
    pvc-06b4a8a8-b51d-42c6-a8cc-d8c8d6bc65bc-d890efb2
    pvc-71a266e0-5db5-44e5-a2a3-e5471b007cc9-fe160a2c
    ```

    The directory naming pattern is:
   
    ```
    <volume_name>-<8 bytes UUID>
    ```
   
    So in the example above, there are two volumes stored here, which are `pvc-06b4a8a8-b51d-42c6-a8cc-d8c8d6bc65bc` and `pvc-71a266e0-5db5-44e5-a2a3-e5471b007cc9`.

    The volume name matches the Kubernetes PV name.

3. Use the `lsof` command to make sure no one is currently using the volume, e.g.
   ```
   # lsof pvc-06b4a8a8-b51d-42c6-a8cc-d8c8d6bc65bc-d890efb2/
   COMMAND    PID USER   FD   TYPE DEVICE SIZE/OFF   NODE NAME
   longhorn 14464 root  cwd    DIR    8,0     4096 541456 pvc-06b4a8a8-b51d-42c6-a8cc-d8c8d6bc65bc-d890efb2
   ```
   The above result shows that the data directory is still being used, so don't proceed to the next step. If it's not being used, `lsof` command should return empty result.
4. Check the volume size of the volume you want to restore using the following command inside the directory:
   ```
   # cat pvc-06b4a8a8-b51d-42c6-a8cc-d8c8d6bc65bc-d890efb2/volume.meta 
    {"Size":1073741824,"Head":"volume-head-000.img","Dirty":true,"Rebuilding":false,"Parent":"","SectorSize":512,"BackingFileName":""}
   ```
   From the result above, you can see the volume size is `1073741824` (1 GiB). Note the size.
5. To export the content of the volume, use the following command to create a single replica Longhorn volume container:

   ```
   docker run -v /dev:/host/dev -v /proc:/host/proc -v <data_path>:/volume --privileged longhornio/longhorn-engine:v1.0.0 launch-simple-longhorn <volume_name> <volume_size>
   ```

   For example, based on the information above, the command should be:

   ```
   docker run -v /dev:/host/dev -v /proc:/host/proc -v /var/lib/longhorn/replicas/pvc-06b4a8a8-b51d-42c6-a8cc-d8c8d6bc65bc-d890efb2:/volume --privileged longhornio/longhorn-engine:v1.0.0 launch-simple-longhorn pvc-06b4a8a8-b51d-42c6-a8cc-d8c8d6bc65bc 1073741824 
   ```
**Result:** Now you should have a block device created on `/dev/longhorn/<volume_name>` for this device, such as `/dev/longhorn/pvc-06b4a8a8-b51d-42c6-a8cc-d8c8d6bc65bc` for the example above. Now you can mount the block device to get the access to the data.

> To avoid accidental change of the volume content, it's recommended to use `mount -o ro` to mount the directory as `readonly`.

After you are done accessing the volume content, use `docker stop` to stop the container. The block device should disappear from the `/dev/longhorn/` directory after the container is stopped.