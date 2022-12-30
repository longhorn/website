---
title: Recovering from a Longhorn Backup without System Installed
weight: 5
---

This command gives users the ability to restore a backup to a `raw` image or a `qcow2` image. If the backup is based on a backing file, users should provide the backing file as a `qcow2` image with `--backing file` parameter.

1. Copy the [yaml template](https://github.com/longhorn/longhorn/blob/v{{< current-version >}}/examples/restore_to_file.yaml.template): Make a copy of `examples/restore_to_file.yaml.template` as e.g. `restore.yaml`.
    
2. Set the node which the output file should be placed on by replacing `<NODE_NAME>`, e.g. `node1`.

3. Specify the host path of output file by modifying field `hostpath` of volume `disk-directory`. By default the directory is `/tmp/restore/`.

4. Set the first argument (backup url) by replacing `<BACKUP_URL>`, e.g. `s3://<your-bucket-name>@<your-aws-region>/backupstore?backup=<backup-name>&volume=<volume-name>`.

    - `<backup-name>` and `<volume-name>` can be retrieved from backup.cfg stored in the backup destination folder, e.g. `backup_backup-72bcbdad913546cf.cfg`. The content will be like below: 

        ```json
        {"Name":"backup-72bcbdad913546cf","VolumeName":"volume_1","SnapshotName":"79758033-a670-4724-906f-41921f53c475"}
        ```

5. Set argument `output-file` by replacing `<OUTPUT_FILE>`, e.g. `volume.raw` or `volume.qcow2`.

6. Set argument `output-format` by replacing `<OUTPUT_FORMAT>`. The supported options are `raw` or `qcow2`.

7. Set the S3 Credential Secret by replacing `<S3_SECRET_NAME>`, e.g. `minio-secret`.  

    - The credential secret can be referenced [here](https://longhorn.io/docs/{{< current-version >}}/snapshots-and-backups/backup-and-restore/set-backup-target/#set-up-aws-s3-backupstore) and must be created in the `longhorn-system' namespace.

8. Execute the yaml using e.g.:

        kubectl create -f restore.yaml

9. Watch the result using:

        kubectl -n longhorn-system get pod restore-to-file -w

After the pod status changed to `Completed`, you should able to find `<OUTPUT_FILE>` at e.g. `/tmp/restore` on the `<NODE_NAME>`.
