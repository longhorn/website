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
    kubectl create -f https://raw.githubusercontent.com/longhorn/longhorn/v{{< current-version >}}/deploy/backupstores/minio-backupstore.yaml
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
      AWS_CERT: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURMRENDQWhTZ0F3SUJBZ0lSQU1kbzQycGhUZXlrMTcvYkxyWjVZRHN3RFFZSktvWklodmNOQVFFTEJRQXcKR2pFWU1CWUdBMVVFQ2hNUFRHOXVaMmh2Y200Z0xTQlVaWE4wTUNBWERUSXdNRFF5TnpJek1EQXhNVm9ZRHpJeApNakF3TkRBek1qTXdNREV4V2pBYU1SZ3dGZ1lEVlFRS0V3OU1iMjVuYUc5eWJpQXRJRlJsYzNRd2dnRWlNQTBHCkNTcUdTSWIzRFFFQkFRVUFBNElCRHdBd2dnRUtBb0lCQVFEWHpVdXJnUFpEZ3pUM0RZdWFlYmdld3Fvd2RlQUQKODRWWWF6ZlN1USs3K21Oa2lpUVBvelVVMmZvUWFGL1BxekJiUW1lZ29hT3l5NVhqM1VFeG1GcmV0eDBaRjVOVgpKTi85ZWFJNWRXRk9teHhpMElPUGI2T0RpbE1qcXVEbUVPSXljdjRTaCsvSWo5Zk1nS0tXUDdJZGxDNUJPeThkCncwOVdkckxxaE9WY3BKamNxYjN6K3hISHd5Q05YeGhoRm9tb2xQVnpJbnlUUEJTZkRuSDBuS0lHUXl2bGhCMGsKVHBHSzYxc2prZnFTK3hpNTlJeHVrbHZIRXNQcjFXblRzYU9oaVh6N3lQSlorcTNBMWZoVzBVa1JaRFlnWnNFbQovZ05KM3JwOFhZdURna2kzZ0UrOElXQWRBWHExeWhqRDdSSkI4VFNJYTV0SGpKUUtqZ0NlSG5HekFnTUJBQUdqCmF6QnBNQTRHQTFVZER3RUIvd1FFQXdJQ3BEQVRCZ05WSFNVRUREQUtCZ2dyQmdFRkJRY0RBVEFQQmdOVkhSTUIKQWY4RUJUQURBUUgvTURFR0ExVWRFUVFxTUNpQ0NXeHZZMkZzYUc5emRJSVZiV2x1YVc4dGMyVnlkbWxqWlM1awpaV1poZFd4MGh3Ui9BQUFCTUEwR0NTcUdTSWIzRFFFQkN3VUFBNElCQVFDbUZMMzlNSHVZMzFhMTFEajRwMjVjCnFQRUM0RHZJUWozTk9kU0dWMmQrZjZzZ3pGejFXTDhWcnF2QjFCMVM2cjRKYjJQRXVJQkQ4NFlwVXJIT1JNU2MKd3ViTEppSEtEa0Jmb2U5QWI1cC9VakpyS0tuajM0RGx2c1cvR3AwWTZYc1BWaVdpVWorb1JLbUdWSTI0Q0JIdgpnK0JtVzNDeU5RR1RLajk0eE02czNBV2xHRW95YXFXUGU1eHllVWUzZjFBWkY5N3RDaklKUmVWbENtaENGK0JtCmFUY1RSUWN3cVdvQ3AwYmJZcHlERFlwUmxxOEdQbElFOW8yWjZBc05mTHJVcGFtZ3FYMmtYa2gxa3lzSlEralAKelFadHJSMG1tdHVyM0RuRW0yYmk0TktIQVFIcFc5TXUxNkdRakUxTmJYcVF0VEI4OGpLNzZjdEg5MzRDYWw2VgotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tCg==
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

You can find an example NFS backupstore for testing purpose [here](https://github.com/longhorn/longhorn/blob/v{{< current-version >}}/deploy/backupstores/nfs-backupstore.yaml).

**Result:** Longhorn can store backups in NFS. To create a backup, see [this section.](../create-a-backup)
