---
title:  Manage Node-Group on AWS EKS
weight: 1
---

EKS supports configuring the same launch template. The nodes in the node-group will be recycled by new nodes with new configurations when updating the launch template version.

See [Launch template support](https://docs.aws.amazon.com/eks/latest/userguide/launch-templates.html) for more information.

The following is an example to replace cluster nodes with new storage size.


## Storage Expansion

1. In Longhorn, set `replica-replenishment-wait-interval` to `0`.

2. Go to the launch template of the EKS cluster node-group. You can find in the EKS cluster tab `Configuration/Compute/<node-group-name>` and click the launch template.

3. Click `Modify template (Create new version)` in the `Actions` drop-down menu.

4. Choose the `Source template version` in the `Launch template name and version description`.

5. Follow steps to [Expand volume](#expand-volume), or [Create additional volume](#create-additional-volume).
> **Note:** If you choose to expand by [create additional volume](#create-additional-volume), the disks need to be manually added to the disk list of the nodes after the EKS cluster upgrade.


### Expand volume
1. Update the volume size in `Configure storage`.

2. Click `Create template version` to save changes.

3. Go to the EKS cluster node-group and change `Launch template version` in `Node Group configuration`. Track the status in the `Update history` tab.


### Create additional volume
1. Click `Advanced` then `Add new volume` in `Configure storage` and fill in the fields.

2. Adjust the auto-mount script and add to `User data` in `Advanced details`. Make sure the `DEV_PATH` matches the `Device name` of the additional volume.
    ```
    MIME-Version: 1.0
    Content-Type: multipart/mixed; boundary="==MYBOUNDARY=="

    --==MYBOUNDARY==
    Content-Type: text/x-shellscript; charset="us-ascii"

    #!/bin/bash

    # https://docs.aws.amazon.com/eks/latest/userguide/launch-templates.html#launch-template-user-data
    echo "Running custom user data script"

    DEV_PATH="/dev/sdb"
    mkfs -t ext4 ${DEV_PATH}

    MOUNT_PATH="/mnt/longhorn"
    mkdir ${MOUNT_PATH}
    mount ${DEV_PATH} ${MOUNT_PATH}
    ```

3. Click `Create template version` to save changes.

4. Go to the EKS cluster node-group and change `Launch template version` in `Node Group configuration`. Track the status in the `Update history` tab.

5. In Longhorn, add the path of the mounted disk into the disk list of the nodes.
