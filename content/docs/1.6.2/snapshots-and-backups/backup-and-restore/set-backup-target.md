---
title: Setting a Backup Target
weight: 1
---

A backup target is an endpoint used to access a backup store in Longhorn. A backup store is an NFS server, SMB/CIFS server, Azure Blob Storage server, or S3 compatible server that stores the backups of Longhorn volumes. The backup target can be set at `Settings/General/BackupTarget`.

Saving to an object store such as S3 is preferable because it generally offers better reliability.  Another advantage is that you do not need to mount and unmount the target, which can complicate failover and upgrades.

For more information about how the backupstore works in Longhorn, see the [concepts section.](../../../concepts/#3-backups-and-secondary-storage)

If you don't have access to AWS S3 or want to give the backupstore a try first, we've also provided a way to [setup a local S3 testing backupstore](#set-up-a-local-testing-backupstore) using [MinIO](https://minio.io/).

Longhorn also supports setting up recurring snapshot/backup jobs for volumes, via Longhorn UI or Kubernetes Storage Class. See [here](../../scheduling-backups-and-snapshots) for details.

This page covers the following topics:

- [Set up AWS S3 Backupstore](#set-up-aws-s3-backupstore)
- [Set up GCP Cloud Storage Backupstore](#set-up-gcp-cloud-storage-backupstore)
- [Set up a Local Testing Backupstore](#set-up-a-local-testing-backupstore)
- [Using a self-signed SSL certificate for S3 communication](#using-a-self-signed-ssl-certificate-for-s3-communication)
- [Enable virtual-hosted-style access for S3 compatible Backupstore](#enable-virtual-hosted-style-access-for-s3-compatible-backupstore)
- [Set up NFS Backupstore](#set-up-nfs-backupstore)
- [Set up SMB/CIFS Backupstore](#set-up-smbcifs-backupstore)
- [Set up Azure Blob Storage Backupstore](#set-up-azure-blob-storage-backupstore)

### Set up AWS S3 Backupstore

1. Create a new bucket in [AWS S3.](https://aws.amazon.com/s3/)

2. Set permissions for Longhorn. There are two options for setting up the credentials. The first is that you can set up a Kubernetes secret with the credentials of an AWS IAM user. The second is that you can use a third-party application to manage temporary AWS IAM permissions for a Pod via annotations rather than operating with AWS credentials.
  - Option 1: Create a Kubernetes secret with IAM user credentials

    1. Follow the [guide](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_users_create.html#id_users_create_console) to create a new AWS IAM user, with the following permissions set. Edit the `Resource` section to use your S3 bucket name:

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

    2. Create a Kubernetes secret with a name such as `aws-secret` in the namespace where Longhorn is placed (`longhorn-system` by default). The secret must be created in the `longhorn-system` namespace for Longhorn to access it:

       ```shell
       kubectl create secret generic <aws-secret> \
           --from-literal=AWS_ACCESS_KEY_ID=<your-aws-access-key-id> \
           --from-literal=AWS_SECRET_ACCESS_KEY=<your-aws-secret-access-key> \
           -n longhorn-system
       ```

  - Option 2: Set permissions with IAM temporary credentials by AWS STS AssumeRole (kube2iam or kiam)

    [kube2iam](https://github.com/jtblin/kube2iam) or [kiam](https://github.com/uswitch/kiam) is a Kubernetes application that allows managing AWS IAM permissions for Pod via annotations rather than operating on AWS credentials. Follow the instructions in the GitHub repository for kube2iam or kiam to install it into the Kubernetes cluster.

    1. Follow the [guide](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_create_for-service.html#roles-creatingrole-service-console) to create a new AWS IAM role for AWS S3 service, with the following permissions set:

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

    2. Edit the AWS IAM role with the following trust relationship:

       ```json
       {
         "Version": "2012-10-17",
         "Statement": [
           {
             "Effect": "Allow",
             "Principal": {
                 "Service": "ec2.amazonaws.com"
             },
             "Action": "sts:AssumeRole"
           },
           {
             "Effect": "Allow",
             "Principal": {
               "AWS": "arn:aws:iam::<AWS_ACCOUNT_ID>:role/<AWS_EC2_NODE_INSTANCE_ROLE>"
             },
             "Action": "sts:AssumeRole"
           }
         ]
       }
       ```

    3. Create a Kubernetes secret with a name such as `aws-secret` in the namespace where Longhorn is placed (`longhorn-system` by default). The secret must be created in the `longhorn-system` namespace for Longhorn to access it:

       ```shell
       kubectl create secret generic <aws-secret> \
           --from-literal=AWS_IAM_ROLE_ARN=<your-aws-iam-role-arn> \
           -n longhorn-system
       ```

3. Go to the Longhorn UI. In the top navigation bar, click **Settings.** In the Backup section, set **Backup Target** to:

    ```text
    s3://<your-bucket-name>@<your-aws-region>/
    ```

   Make sure that you have `/` at the end, otherwise you will get an error. A subdirectory (prefix) may be used:

    ```text
    s3://<your-bucket-name>@<your-aws-region>/mypath/
    ```

   Also make sure you've set **`<your-aws-region>` in the URL**.

   For example, For AWS, you can find the region codes [here.](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Concepts.RegionsAndAvailabilityZones.html)

   For Google Cloud Storage, you can find the region codes [here.](https://cloud.google.com/storage/docs/locations)

4.  In the Backup section set **Backup Target Credential Secret** to:

    ```
    aws-secret
    ```
    This is the secret name with AWS credentials or AWS IAM role.

**Result:** Longhorn can store backups in S3. To create a backup, see [this section.](../create-a-backup)

**Note:** If you operate Longhorn behind a proxy and you want to use AWS S3 as the backupstore, you must provide Longhorn information about your proxy in the `aws-secret` as below:
```shell
kubectl create secret generic <aws-secret> \
    --from-literal=AWS_ACCESS_KEY_ID=<your-aws-access-key-id> \
    --from-literal=AWS_SECRET_ACCESS_KEY=<your-aws-secret-access-key> \
    --from-literal=HTTP_PROXY=<your-proxy-ip-and-port> \
    --from-literal=HTTPS_PROXY=<your-proxy-ip-and-port> \
    --from-literal=NO_PROXY=<excluded-ip-list> \
    -n longhorn-system
```

Make sure `NO_PROXY` contains the network addresses, network address ranges and domains that should be excluded from using the proxy. In order for Longhorn to operate, the minimum required values for `NO_PROXY` are:
* localhost
* 127.0.0.1
* 0.0.0.0
* 10.0.0.0/8 (K8s components' IPs)
* 192.168.0.0/16 (internal IPs in the cluster)

### Set up GCP Cloud Storage Backupstore

1. Create a new bucket in [Google Cloud Storage](https://console.cloud.google.com/storage/browser?referrer=search&project=elite-protocol-319303)
2. Create a GCP serviceaccount in [IAM & Admin](https://console.cloud.google.com/iam-admin)
3. Give the GCP serviceaccount permissions to read, write, and delete objects in the bucket.

   The serviceaccount will require the `roles/storage.objectAdmin` role to read, write, and delete objects in the bucket.

   Here is a reference to the GCP IAM roles you have available for granting access to a serviceaccount https://cloud.google.com/storage/docs/access-control/iam-roles.

> Note: Consider creating an IAM condition to reduce how many buckets this serviceaccount has object admin access to.

4. Navigate to your [buckets in cloud storage](https://console.cloud.google.com/storage/browser) and select your newly created bucket.
5. Go to the cloud storage's settings menu and navigate to the [interoperability tab](https://console.cloud.google.com/storage/settings;tab=interoperability)
6. Scroll down to _Service account HMAC_ and press `+ CREATE A KEY FOR A SERVICE ACCOUNT`
7. Select the GCP serviceaccount you created earlier and press `CREATE KEY`
8. Save the _Access Key_ and _Secret_.

    Also note down the configured _Storage URI_ under the _Request Endpoint_ while you're in the interoperability menu.

- The Access Key will be mapped to the `AWS_ACCESS_KEY_ID` field in the Kubernetes secret we create later.
- The Secret will be mapped to the `AWS_SECRET_ACCESS_KEY` field in the Kubernetes secret we create later.
- The Storage URI will be mapped to the `AWS_ENDPOINTS` field in the Kubernetes secret we create later.

9. Go to the Longhorn UI. In the top navigation bar, click **Settings.** In the Backup section, set **Backup Target** to

```
s3://${BUCKET_NAME}@us/
```

And set **Backup Target Credential Secret** to:

```
longhorn-gcp-backups
```

10. Create a Kubernetes secret named `longhorn-gcp-backups` in the `longhorn-system` namespace with the following content:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: longhorn-gcp-backups
  namespace: longhorn-system
type: Opaque
stringData:
  AWS_ACCESS_KEY_ID: GOOG1EBYHGDE4WIGH2RDYNZWWWDZ5GMQDRMNSAOTVHRAILWAMIZ2O4URPGOOQ
  AWS_ENDPOINTS: https://storage.googleapis.com
  AWS_SECRET_ACCESS_KEY: BKoKpIW021s7vPtraGxDOmsJbkV/0xOVBG73m+8f
```
> Note: The secret can be named whatever you like as long as they match what's in longhorn's settings.

Once the secret is created and Longhorn's settings are saved, navigate to the backup tab in Longhorn. If there are any issues, they should pop up as a toast notification.

If you don't get any error messages, try creating a backup and confirm the content is pushed out to your new bucket.

### Set up a Local Testing Backupstore
Longhorn provides sample backupstore server setups for testing purposes.  You can find samples for AWS S3 (MinIO), Azure, CIFS and NFS in the `longhorn/deploy/backupstores` folder.

1. Set up a MinIO S3 server for the backupstore in the `longhorn-system` namespace.

    ```
    kubectl create -f https://raw.githubusercontent.com/longhorn/longhorn/v{{< current-version >}}/deploy/backupstores/minio-backupstore.yaml
    ```

2. Go to the Longhorn UI. In the top navigation bar, click **Settings.** In the Backup section, set **Backup Target** to

    ```
    s3://backupbucket@us-east-1/
    ```
   And set **Backup Target Credential Secret** to:
    ```
    minio-secret
    ```

   The `minio-secret` yaml looks like this:

    ```yaml
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
      AWS_CERT: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURMRENDQWhTZ0F3SUJBZ0lSQU1kbzQycGhUZXlrMTcvYkxyWjVZRHN3RFFZSktvWklodmNOQVFFTEJRQXcKR2pFWU1CWUdBMVVFQ2hNUFRHOXVaMmh2Y200Z0xTQlVaWE4wTUNBWERUSXdNRFF5TnpJek1EQXhNVm9ZRHpJeApNakF3TkRBek1qTXdNREV4V2pBYU1SZ3dGZ1lEVlFRS0V3OU1iMjVuYUc5eWJpQXRJRlJsYzNRd2dnRWlNQTBHCkNTcUdTSWIzRFFFQkFRVUFBNElCRHdBd2dnRUtBb0lCQVFEWHpVdXJnUFpEZ3pUM0RZdWFlYmdld3Fvd2RlQUQKODRWWWF6ZlN1USs3K21Oa2lpUVBvelVVMmZvUWFGL1BxekJiUW1lZ29hT3l5NVhqM1VFeG1GcmV0eDBaRjVOVgpKTi85ZWFJNWRXRk9teHhpMElPUGI2T0RpbE1qcXVEbUVPSXljdjRTaCsvSWo5Zk1nS0tXUDdJZGxDNUJPeThkCncwOVdkckxxaE9WY3BKamNxYjN6K3hISHd5Q05YeGhoRm9tb2xQVnpJbnlUUEJTZkRuSDBuS0lHUXl2bGhCMGsKVHBHSzYxc2prZnFTK3hpNTlJeHVrbHZIRXNQcjFXblRzYU9oaVh6N3lQSlorcTNBMWZoVzBVa1JaRFlnWnNFbQovZ05KM3JwOFhZdURna2kzZ0UrOElXQWRBWHExeWhqRDdSSkI4VFNJYTV0SGpKUUtqZ0NlSG5HekFnTUJBQUdqCmF6QnBNQTRHQTFVZER3RUIvd1FFQXdJQ3BEQVRCZ05WSFNVRUREQUtCZ2dyQmdFRkJRY0RBVEFQQmdOVkhSTUIKQWY4RUJUQURBUUgvTURFR0ExVWRFUVFxTUNpQ0NXeHZZMkZzYUc5emRJSVZiV2x1YVc4dGMyVnlkbWxqWlM1awpaV1poZFd4MGh3Ui9BQUFCTUEwR0NTcUdTSWIzRFFFQkN3VUFBNElCQVFDbUZMMzlNSHVZMzFhMTFEajRwMjVjCnFQRUM0RHZJUWozTk9kU0dWMmQrZjZzZ3pGejFXTDhWcnF2QjFCMVM2cjRKYjJQRXVJQkQ4NFlwVXJIT1JNU2MKd3ViTEppSEtEa0Jmb2U5QWI1cC9VakpyS0tuajM0RGx2c1cvR3AwWTZYc1BWaVdpVWorb1JLbUdWSTI0Q0JIdgpnK0JtVzNDeU5RR1RLajk0eE02czNBV2xHRW95YXFXUGU1eHllVWUzZjFBWkY5N3RDaklKUmVWbENtaENGK0JtCmFUY1RSUWN3cVdvQ3AwYmJZcHlERFlwUmxxOEdQbElFOW8yWjZBc05mTHJVcGFtZ3FYMmtYa2gxa3lzSlEralAKelFadHJSMG1tdHVyM0RuRW0yYmk0TktIQVFIcFc5TXUxNkdRakUxTmJYcVF0VEI4OGpLNzZjdEg5MzRDYWw2VgotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0t
    ```
   For more information on creating a secret, see [the Kubernetes documentation.](https://kubernetes.io/docs/concepts/configuration/secret/#creating-a-secret-manually) The secret must be created in the `longhorn-system` namespace for Longhorn to access it.

   > Note: Make sure to use `echo -n` when generating the base64 encoding, otherwise an new line will be added at the end of the string and it will cause error when accessing the S3.

3. Click the **Backup** tab in the UI. It should report an empty list without any errors.

**Result:** Longhorn can store backups in S3. To create a backup, see [this section.](../create-a-backup)

### Using a self-signed SSL certificate for S3 communication
If you want to use a self-signed SSL certificate, you can specify AWS_CERT in the Kubernetes secret you provided to Longhorn. See the example in [Set up a Local Testing Backupstore](#set-up-a-local-testing-backupstore).
It's important to note that the certificate needs to be in PEM format, and must be its own CA. Or one must include a certificate chain that contains the CA certificate.
To include multiple certificates, one can just concatenate the different certificates (PEM files).

### Enable virtual-hosted-style access for S3 compatible Backupstore
**You may need to enable this new addressing approach for your S3 compatible Backupstore when**
1. you want to switch to this new access style right now so that you won't need to worry about [Amazon S3 Path Deprecation Plan](https://aws.amazon.com/blogs/aws/amazon-s3-path-deprecation-plan-the-rest-of-the-story/);
2. the backupstore you are using supports virtual-hosted-style access only, e.g., Alibaba Cloud(Aliyun) OSS;
3. you have configurated `MINIO_DOMAIN` environment variable to [enable virtual-host-style requests for the MinIO server](https://docs.min.io/docs/minio-server-configuration-guide.html);
4. the error `...... error: AWS Error: SecondLevelDomainForbidden Please use virtual hosted style to access. .....` is triggered.

**The way to enable virtual-hosted-style access**
1. Add a new field `VIRTUAL_HOSTED_STYLE` with value `true` to your backup target secret. e.g.:
    ```yaml
    apiVersion: v1
    kind: Secret
    metadata:
      name: s3-compatible-backup-target-secret
      namespace: longhorn-system
    type: Opaque
    data:
      AWS_ACCESS_KEY_ID: bG9uZ2hvcm4tdGVzdC1hY2Nlc3Mta2V5
      AWS_SECRET_ACCESS_KEY: bG9uZ2hvcm4tdGVzdC1zZWNyZXQta2V5
      AWS_ENDPOINTS: aHR0cHM6Ly9taW5pby1zZXJ2aWNlLmRlZmF1bHQ6OTAwMA==
      VIRTUAL_HOSTED_STYLE: dHJ1ZQ== # true
    ```
2. Deploy/update the secret and set it in `Settings/General/BackupTargetSecret`.

### Set up NFS Backupstore

Ensure that the NFS server supports NFSv4 and that the target URL points to the service.

Example:

```
nfs://longhorn-test-nfs-svc.default:/opt/backupstore
```

The default mount options are `actimeo=1,soft,timeo=300,retry=2`.  To use other options, append the keyword "nfsOptions" and the options string to the target URL.  

Example:  
```
nfs://longhorn-test-nfs-svc.default:/opt/backupstore?nfsOptions=soft,timeo=330,retrans=3  
```

Any mount options that you specify will replace, not add to, the default options.

You can find an example NFS backupstore for testing purpose [here](https://github.com/longhorn/longhorn/blob/v{{< current-version >}}/deploy/backupstores/nfs-backupstore.yaml).

**Result:** Longhorn can store backups in NFS. To create a backup, see [this section.](../create-a-backup)

### Set up SMB/CIFS Backupstore

Before configuring a SMB/CIFS backupstore, a credential secret for the backupstore can be created and deployed by
  ```shell
  #!/bin/bash

  USERNAME=${Username of SMB/CIFS Server}
  PASSWORD=${Password of SMB/CIFS Server}

  CIFS_USERNAME=`echo -n ${USERNAME} | base64`
  CIFS_PASSWORD=`echo -n ${PASSWORD} | base64`

  cat <<EOF >>cifs_secret.yml
  apiVersion: v1
  kind: Secret
  metadata:
    name: cifs-secret
    namespace: longhorn-system
  type: Opaque
  data:
    CIFS_USERNAME: ${CIFS_USERNAME}
    CIFS_PASSWORD: ${CIFS_PASSWORD}
  EOF

  kubectl apply -f cifs_secret.yml
  ```

Then, navigate to Longhorn UI > Setting > General > Backup

1. Set **Backup Target**. The target URL should look like this:

    ```
    cifs://longhorn-test-cifs-svc.default/backupstore
    ```

	The default CIFS mount option is "soft".  To use other options, append the keyword "cifsOptions" and the options string to the target URL.  
	
	Example:
    ```
    cifs://longhorn-test-cifs-svc.default/backupstore?cifsOptions=rsize=65536,wsize=65536,soft
    ```

	Any mount options that you specify will replace, not add to, the default options.


2. Set **Backup Target Credential Secret**

    ```
    cifs-secret
    ```
    This is the secret name with CIFS credentials.

You can find an example CIFS backupstore for testing purpose [here](https://github.com/longhorn/longhorn/blob/v{{< current-version >}}/deploy/backupstores/cifs-backupstore.yaml).

**Result:** Longhorn can store backups in CIFS. To create a backup, see [this section.](../create-a-backup)

### Set up Azure Blob Storage Backupstore

1. Create a new container in [Azure Blob Storage Service](https://portal.azure.com/)

2. Before configuring an Azure Blob Storage backup store, create a Kubernetes secret with a name such as `azblob-secret` in the namespace where Longhorn is installed (`longhorn-system`). The secret must be created in the same namespace for Longhorn to access it.

  - The Account Name will be the `AZBLOB_ACCOUNT_NAME` field in the secret.
  - The Account Secret Key will be the `AZBLOB_ACCOUNT_KEY` field in the secret.
  - The Storage URI will be the `AZBLOB_ENDPOINT` field in the secret.

  - By a manifest:
    ```shell
    #!/bin/bash

    # AZBLOB_ACCOUNT_NAME:   Account name of Azure Blob Storage server
    # AZBLOB_ACCOUNT_KEY:    Account key of Azure Blob Storage server
    # AZBLOB_ENDPOINT:       Endpoint of Azure Blob Storage server
    # AZBLOB_CERT:           SSL certificate for Azure Blob Storage server

    AZBLOB_ACCOUNT_NAME=`echo -n ${AZBLOB_ACCOUNT_NAME} | base64`
    AZBLOB_ACCOUNT_KEY=`echo -n ${AZBLOB_ACCOUNT_KEY} | base64`
    AZBLOB_ENDPOINT=`echo -n ${AZBLOB_ENDPOINT} | base64`
    AZBLOB_CERT=`echo -n ${AZBLOB_CERT} | base64`

    cat <<EOF >>azblob_secret.yml
    apiVersion: v1
    kind: Secret
    metadata:
      name: azblob-secret
      namespace: longhorn-system
    type: Opaque
    data:
      AZBLOB_ACCOUNT_NAME: ${AZBLOB_ACCOUNT_NAME}
      AZBLOB_ACCOUNT_KEY: ${AZBLOB_ACCOUNT_KEY}
      #AZBLOB_ENDPOINT: ${AZBLOB_ENDPOINT}
      #AZBLOB_CERT: ${AZBLOB_CERT}
      #HTTP_PROXY: aHR0cDovLzEwLjIxLjkxLjUxOjMxMjg=
      #HTTPS_PROXY: aHR0cDovLzEwLjIxLjkxLjUxOjMxMjg=
    EOF

    kubectl apply -f azblob_secret.yml
    ```

  - CLI command:
    ```shell
    kubectl create secret generic <azblob-secret> \
      --from-literal=AZBLOB_ACCOUNT_NAME=<your-azure-storage-account-name> \
      --from-literal=AZBLOB_ACCOUNT_KEY=<your-azure-storage-account-key> \
      --from-literal=HTTP_PROXY=<your-proxy-ip-and-port> \
      --from-literal=HTTPS_PROXY=<your-proxy-ip-and-port> \
      --from-literal=NO_PROXY=<excluded-ip-list> \
      -n longhorn-system
    ```

Then, navigate to Longhorn UI > Setting > General > Backup

1. Set **Backup Target**. The target URL should look like this:

    ```txt
    azblob://[your-container-name]@[endpoint-suffix]/
    ```

   Make sure that you have `/` at the end, otherwise you will get an error. A subdirectory (prefix) may be used:

    ```text
    azblob://[your-container-name]@[endpoint-suffix]/my-path/
    ```

   - If you set `<endpoint-suffix>` in the URL, the default endpoint suffix will be `core.windows.net`.
   - If you set `AZBLOB_ENDPOINT` in the secret, Longhorn will use `AZBLOB_ENDPOINT` as your storage URL, and `<endpoint-suffix>` will not be used even if it has been set. 

2. Set **Backup Target Credential Secret**

    ```txt
    azblob-secret
    ```


After configuring the above settings, you can manage backups on Azure Blob storage. See [how to create backup](../create-a-backup) for details.
