---
title: Setting a Backup Target
weight: 1
---

A backup target represents a backupstore in Longhorn. The backup target can be set at `Settings/General/BackupTarget`.

A backup in Longhorn represents a volume state (a Snapshot) at a given time, stored in the secondary storage (backupstore in Longhorn word) which is outside of the Longhorn system. Backup creation will involving copying the data through the network, so it will take time.

These operations happen automatically, but can also be done as needed.

A corresponding snapshot is needed for creating a backup. And user can choose to backup any snapshot previous created.

Longhorn also supports setting up recurring snapshot/backup jobs for volumes, via Longhorn UI or Kubernetes Storage Class. See [here](./scheduling-backups-and-snapshots) for details.

This page covers the following topics:

- [Set up BackupTarget](#set-up-backuptarget)
  - [Set up AWS S3 Backupstore](#set-up-aws-s3-backupstore)
  - [Set up a Local Testing Backupstore](#set-up-a-local-testing-backupstore)
  - [NFS Backupstore](#nfs-backupstore)

## Set up BackupTarget

The user can setup a S3 or NFS type backupstore to store the backups of Longhorn volumes.

If the user doesn't have access to AWS S3 or want to give a try first, we've also provided a way to [setup a local S3 testing backupstore](../../users-guide/backup-and-restore/backupstores-and-backuptargets#setup-a-local-testing-backupstore) using [Minio](https://minio.io/).

### Set up AWS S3 Backupstore

1. Create a new bucket in AWS S3.

2. Follow the [guide](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_users_create.html#id_users_create_console) to create a new AWS IAM user, with the following permissions set:

  ```json
  {
      "Version": "2012-10-17",
      "Statement": [
          {
              "Sid": "GrantLonghornBackupstoreAccess0",
              "Effect": "Allow",
              "Action": [
                  "s3:PutObject",
                  "s3:GetObject",
                  "s3:ListBucket",
                  "s3:DeleteObject"
              ],
              "Resource": [
                  "arn:aws:s3:::<your-bucket-name>",
                  "arn:aws:s3:::<your-bucket-name>/*"
              ]
          }
      ]
  }
  ```

3. Create a Kubernetes secret with a name such as `aws-secret` in the namespace where longhorn is placed(`longhorn-system` by default). Put the following keys in the secret:

  ```shell
  AWS_ACCESS_KEY_ID: <your_aws_access_key_id>
  AWS_SECRET_ACCESS_KEY: <your_aws_secret_access_key>
  ```

4. Go to the Longhorn UI and set `Settings/General/BackupTarget` to

  ```text
  s3://<your-bucket-name>@<your-aws-region>/
  ```

Pay attention that you should have `/` at the end, otherwise you will get an error.

Also please make sure you've set **`<your-aws-region>` in the URL**.

For example, for Google Cloud Storage, you can find the region code here: https://cloud.google.com/storage/docs/locations

5.  Set `Settings/General/BackupTargetSecret` to

  ```
  aws-secret
  ```
Your secret name with AWS keys from 3rd point.

### Set up a Local Testing Backupstore
We provides two testing purpose backupstore based on NFS server and Minio S3 server for testing, in `./deploy/backupstores`.

1. Use following command to setup a Minio S3 server for BackupStore after `longhorn-system` was created.

  ```
  kubectl create -f https://raw.githubusercontent.com/longhorn/longhorn/master/deploy/backupstores/minio-backupstore.yaml
  ```

2. Set `Settings/General/BackupTarget` to

  ```
  s3://backupbucket@us-east-1/
  ```
  And `Setttings/General/BackupTargetSecret` to
  ```
  minio-secret
  ```
3. Click the `Backup` tab in the UI. It should report an empty list without error out.

The `minio-secret` yaml looks like this:
```
apiVersion: v1
kind: Secret
metadata:
  name: minio-secret
  namespace: longhorn-system
type: Opaque
data:
  AWS_ACCESS_KEY_ID: bG9uZ2hvcm4tdGVzdC1hY2Nlc3Mta2V5 # longhorn-test-access-key
  AWS_SECRET_ACCESS_KEY: bG9uZ2hvcm4tdGVzdC1zZWNyZXQta2V5 # longhorn-test-secret-key
  AWS_ENDPOINTS: aHR0cDovL21pbmlvLXNlcnZpY2UuZGVmYXVsdDo5MDAw # http://minio-service.default:9000
```
Please follow [the Kubernetes documentation](https://kubernetes.io/docs/concepts/configuration/secret/#creating-a-secret-manually) to create the secret.

> Note: Make sure to use `echo -n` when generating the base64 encoding, otherwise an new line will be added at the end of the string and it will cause error when accessing the S3.

The secret must be created in the `longhorn-system` namespace for Longhorn to access.

### NFS Backupstore

For using NFS server as backupstore, NFS server must support NFSv4.

The target URL would looks like:
```
nfs://longhorn-test-nfs-svc.default:/opt/backupstore
```

You can find an example NFS backupstore for testing purpose [here](https://github.com/longhorn/longhorn/blob/master/deploy/backupstores/nfs-backupstore.yaml). 

