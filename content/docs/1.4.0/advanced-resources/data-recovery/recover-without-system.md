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

7. Set argument `longhorn-version` by replacing `<LONGHORN_VERSION>`, e.g. `v{{< current-version >}}`

8. Set the S3 Credential Secret by replacing `<S3_SECRET_NAME>`, e.g. `minio-secret`.  

    - The credential secret can be referenced [here](https://longhorn.io/docs/{{< current-version >}}/snapshots-and-backups/backup-and-restore/set-backup-target/#set-up-aws-s3-backupstore) and must be created in the `longhorn-system' namespace.

9. Execute the yaml using e.g.:

        kubectl create -f restore.yaml

10. Watch the result using:

        kubectl -n longhorn-system get pod restore-to-file -w

After the pod status changed to `Completed`, you should able to find `<OUTPUT_FILE>` at e.g. `/tmp/restore` on the `<NODE_NAME>`.

We also provide a script, [restore-backup-to-file.sh](https://raw.githubusercontent.com/longhorn/longhorn/v{{< current-version >}}/scripts/restore-backup-to-file.sh), to restore a backup. The following parameters should be specified:
  - `--backup-url`: Specifies the backups S3/NFS URL. e.g., `s3://backupbucket@us-east-1/backupstore?backup=backup-bd326da2c4414b02&volume=volumeexamplename"`
  
  - `--output-file`: Set the output file name. e.g, `volume.raw`
  
  - `--output-format`: Set the output file format. e.g. `raw` or `qcow2`
  
  - `--version`: Specifies the version of Longhorn to use. e.g., `v{{< current-version >}}`

Optional parameters can be specified:

  - `--aws-access-key`: Specifies AWS credentials access key if backups is s3.
  
  - `--aws-secret-access-key`: Specifies AWS credentials access secret key if backups is s3.
  
  - `--backing-file`: backing image. e.g., `/tmp/backingfile.qcow2`

The output image files can be found in the `/tmp/restore` folder after the script has finished running.