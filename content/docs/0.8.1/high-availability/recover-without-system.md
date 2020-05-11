---
title: Recovering from a Longhorn Backup without System Installed
weight: 4
---
In this section, you'll learn how to restore a backup to a `raw` image or a `qcow2` image.

If the backup is based on a backing file, the backing file should be provided as a `qcow2` image with `--backing file` parameter.

1. Copy the YAML template: Make a copy of this [restore-to-file Pod](../../references/examples/#restore-to-file) as e.g. `restore.yaml`.
    
2. Set the node which the output file should be placed on by replacing `<NODE_NAME>`, e.g. `node1`.

3. Specify the host path of the output file by modifying the field `hostpath` of the volume named `disk-directory`. By default the directory is `/tmp/restore/`.

4. Set the backup URL by replacing `<BACKUP_URL>`. In this example, the backup URL is the path to a backup in an S3 bucket: `s3://backupbucket@us-east-1/backupstore?backup=backup-bd326da2c4414b02&volume=volumeexamplename`. Do not delete `''`.

5. Replace `<OUTPUT_FILE>` with your output file, e.g. `volume.raw` or `volume.qcow2`.

6. Set argument `output-format` by replacing `<OUTPUT_FORMAT>`. The supported formats are `raw` and `qcow2`.

7. Set the S3 Credential Secret by replacing `<S3_SECRET_NAME>`, e.g. `minio-secret`. 

8. Execute the YAML using e.g. `kubectl create -f restore.yaml`.

9. To watch the result, run:

    ```
    kubectl -n longhorn-system get pod restore-to-file -w
    ```

**Result:** After the pod status changes to `Completed`, you should able to find `<OUTPUT_FILE>` at e.g. `/tmp/restore` on the `<NODE_NAME>`.
