---
title: Setting a Backup Target
weight: 1
---

A backup target is the endpoint used to access a backupstore in Longhorn. A backupstore is a NFS server or S3 compatible server that stores the backups of Longhorn volumes. The backup target can be set at `Settings/General/BackupTarget`.

For more information about how the backupstore works in Longhorn, see the [concepts section.](../../../concepts/#3-backups-and-secondary-storage)

If you don't have access to AWS S3 or want to give the backupstore a try first, we've also provided a way to [setup a local S3 testing backupstore](#set-up-a-local-testing-backupstore) using [Minio](https://minio.io/).

Longhorn also supports setting up recurring snapshot/backup jobs for volumes, via Longhorn UI or Kubernetes Storage Class. See [here](../../scheduling-backups-and-snapshots) for details.

This page covers the following topics:

- [Set up AWS S3 Backupstore](#set-up-aws-s3-backupstore)
- [Set up a Local Testing Backupstore](#set-up-a-local-testing-backupstore)
- [NFS Backupstore](#nfs-backupstore)

### Set up AWS S3 Backupstore

1. Create a new bucket in [AWS S3.](https://aws.amazon.com/s3/)

2. Follow the [guide](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_users_create.html#id_users_create_console) to create a new AWS IAM user, with the following permissions set. Edit the `Resource` section to use your S3 bucket name:

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

3. Create a Kubernetes secret with a name such as `aws-secret` in the namespace where longhorn is placed(`longhorn-system` by default). For help creating a secret, refer to the [Kubernetes documentation.](https://kubernetes.io/docs/concepts/configuration/secret/) The secret must be created in the `longhorn-system` namespace for Longhorn to access it. Put the following key-value pairs in the secret:

    ```shell
    AWS_ACCESS_KEY_ID: <your_aws_access_key_id>
    AWS_SECRET_ACCESS_KEY: <your_aws_secret_access_key>
    ```

4. Go to the Longhorn UI. In the top navigation bar, click **Settings.** In the Backup section, set **Backup Target** to:

    ```text
    s3://<your-bucket-name>@<your-aws-region>/
    ```

    Make sure that you have `/` at the end, otherwise you will get an error.

   Also make sure you've set **`<your-aws-region>` in the URL**. For example, for Google Cloud Storage, you can find the region code [here.](https://cloud.google.com/storage/docs/locations)

5.  Set `Settings/General/BackupTargetSecret` to

    ```
    aws-secret
    ```
    This is the secret name with AWS keys from the third step.

**Result:** Longhorn can store backups in S3. To create a backup, see [this section.](../create-a-backup)

### Set up a Local Testing Backupstore
We provides two testing purpose backupstore based on NFS server and Minio S3 server for testing, in `./deploy/backupstores`.

1. Use following command to setup a Minio S3 server for the backupstore after `longhorn-system` was created.

    ```
    kubectl create -f https://raw.githubusercontent.com/longhorn/longhorn/master/deploy/backupstores/minio-backupstore.yaml
    ```

2. Go to the Longhorn UI. In the top navigation bar, click **Settings.** In the Backup section, set **Backup Target** to

    ```
    s3://backupbucket@us-east-1/
    ```
    And set `Settings/General/BackupTargetSecret` to:
    ```
    minio-secret
    ```

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
      AWS_ENDPOINTS: aHR0cHM6Ly9taW5pby1zZXJ2aWNlLmRlZmF1bHQ6OTAwMA== # https://minio-service.default:9000
      AWS_CERT: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUREekNDQWZlZ0F3SUJBZ0lSQU91d1oybTZ6SXl3c1h2a2UyNS9LYzB3RFFZSktvWklodmNOQVFFTEJRQXcKRWpFUU1BNEdBMVVFQ2hNSFFXTnRaU0JEYnpBZUZ3MHlNREEwTWpVd01qRTJNalphRncweU1UQTBNalV3TWpFMgpNalphTUJJeEVEQU9CZ05WQkFvVEIwRmpiV1VnUTI4d2dnRWlNQTBHQ1NxR1NJYjNEUUVCQVFVQUE0SUJEd0F3CmdnRUtBb0lCQVFEWkpyWVUraVJhc1huSExvb1d0Tm9OQWpxN0U3YWNlQTJQZnQ1ZFM3aExzVUtCbExMOVVQMmUKZ0QrVFl3RmtCWVJNU3BsV0tNT0tuWEErNDZSVkRwSkhwSTF4YjhHNDV0L3gzVXhVaWc2WUFVbDBnTFV6N01rMQpYSUtRaWZZUllaL0FjUzJqU0VOYjRISFJ1aFZ5NzV0ZDdCaXNhd2J2TTJwTXI0dWNSR1lwZ3J6Z2V2eFBXSHZ1CnkxT29yRnIvNjFwV28wcG9aSXhtRmM2YXMzekw0NWlrRzRHN1A2ejJPamc4NGdrdnR4RFUzYVdmWXRNb3VhL3gKQVhkRlRCd2NqMkNHMHJtdmd4cE5KeEx5Kzl5NDVLVGU1SFlSd0xxUjVCeWtnVGt2RGplcWdXTnJyQWdCL3lLTApwU1ZjRmZkKzBWNjhyQmtNMEt3VlQ3bXF2WWRsZDVrTkFnTUJBQUdqWURCZU1BNEdBMVVkRHdFQi93UUVBd0lDCnBEQVRCZ05WSFNVRUREQUtCZ2dyQmdFRkJRY0RBVEFQQmdOVkhSTUJBZjhFQlRBREFRSC9NQ1lHQTFVZEVRUWYKTUIyQ0ZXMXBibWx2TFhObGNuWnBZMlV1WkdWbVlYVnNkSWNFZndBQUFUQU5CZ2txaGtpRzl3MEJBUXNGQUFPQwpBUUVBdDBQYjM5QWliS0EyU1BPTHJHSmVRVlNaVTdZbFUyU0h0M2lhcFVBS1Rtb2o1RTQrTU8yV2NnbktoRktrCnNxeW9CYjBPYTNPMHdXUnRvVnhNUGdPQS9FaXNtZExQWmJIVTUzS2w3SDVWMm8rb0tQY0YydTk2ajdlcUZxSkUKMlltQkpBTHlUVks5LzZhS1hOSnRYZE5xRmpPMWJRcDJRTURXbjQyZGgyNjJLZmgvekM4enRyK0h4RzhuTVpQQwpsZUpxbzU3S0tkZ0YvZHVBWTdUaUI2cThTelE4RmViMklQQ2FhdVVLNzdBZ0d5b3kzK1JuWkdZV2U1MG1KVnN6CmdkQTFURmg0TVdMeUxWSFdIbnl2cEFvTjJIUjQrdzhYRkpJS2VRRFM1YklJM1pFeU5OQUZNRDg0bTVReGY4cjUKMEovQWhXTVVyMFUwcCtiRi9KM3FDQVNSK3c9PQotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tCg==
    ```
    For more information on creating a secret, see [the Kubernetes documentation.](https://kubernetes.io/docs/concepts/configuration/secret/#creating-a-secret-manually) The secret must be created in the `longhorn-system` namespace for Longhorn to access it.

    > Note: Make sure to use `echo -n` when generating the base64 encoding, otherwise an new line will be added at the end of the string and it will cause error when accessing the S3.

3. Click the **Backup** tab in the UI. It should report an empty list without any errors.

**Result:** Longhorn can store backups in S3. To create a backup, see [this section.](../create-a-backup)

### Using a self-signed SSL certificate for S3 communication
If you want to use a self-signed SSL certificate, you can specify AWS_CERT in the Kubernetes secret you provided to Longhorn. See the example in [Set up a Local Testing Backupstore](#set-up-a-local-testing-backupstore).
It's important to note that the certificate needs to be in PEM format, and must be its own CA. Or one must include a certificate chain that contains the CA certificate.
To include multiple certificates, one can just concatenate the different certificates (PEM files).

### NFS Backupstore

For using NFS server as backupstore, NFS server must support NFSv4.

The target URL should look like this:

```
nfs://longhorn-test-nfs-svc.default:/opt/backupstore
```

You can find an example NFS backupstore for testing purpose [here](https://github.com/longhorn/longhorn/blob/master/deploy/backupstores/nfs-backupstore.yaml).

**Result:** Longhorn can store backups in NFS. To create a backup, see [this section.](../create-a-backup)
