---
title: Python Client
weight: 5
---

Currently, you can operate Longhorn using Longhorn UI.
We are planning to build a dedicated Longhorn CLI in the upcoming releases.

In the meantime, you can access Longhorn API using Python binding, as we demonstrated below.

1. Get Longhorn endpoint

   One way to communicate with Longhorn is through `longhorn-frontend` service.

   If you run your automation/scripting tool inside the same cluster in which Longhorn is installed, connect to the endpoint `http://longhorn-frontend.longhorn-system/v1`


   If you run your automation/scripting tool on your local machine,
   use `kubectl port-forward` to forward the `longhorn-frontend` service to localhost:
   ```
   kubectl port-forward services/longhorn-frontend 8080:http -n longhorn-system
   ```
   and connect to endpoint `http://localhost:8080/v1`

2. Using Python Client

    Import file [longhorn.py](https://github.com/longhorn/longhorn-tests/blob/master/manager/integration/tests/longhorn.py) which contains the Python client into your Python script and create a client from the endpoint:
    ```python
    import longhorn

    # If automation/scripting tool is inside the same cluster in which Longhorn is installed
    longhorn_url = 'http://longhorn-frontend.longhorn-system/v1'
    # If forwarding `longhorn-frontend` service to localhost
    longhorn_url = 'http://localhost:8080/v1'

    client = longhorn.Client(url=longhorn_url)

    # Volume operations
    # List all volumes
    volumes = client.list_volume()
    # Get volume by NAME/ID
    testvol1 = client.by_id_volume(id="testvol1")
    # Attach TESTVOL1
    testvol1 = testvol1.attach(hostId="worker-1")
    # Detach TESTVOL1
    testvol1.detach()
    # Create a snapshot of TESTVOL1 with NAME
    snapshot1 = testvol1.snapshotCreate(name="snapshot1")
    # Create a backup from a snapshot NAME
    testvol1.snapshotBackup(name=snapshot1.name)
    # Update the number of replicas of TESTVOL1
    testvol1.updateReplicaCount(replicaCount=2)
    # Find more examples in Longhorn integration tests https://github.com/longhorn/longhorn-tests/tree/master/manager/integration/tests

    # Node operations
    # List all nodes
    nodes = client.list_node()
    # Get node by NAME/ID
    node1 = client.by_id_node(id="worker-1")
    # Disable scheduling for NODE1
    client.update(node1, allowScheduling=False)
    # Enable scheduling for NODE1
    client.update(node1, allowScheduling=True)
    # Find more examples in Longhorn integration tests https://github.com/longhorn/longhorn-tests/tree/master/manager/integration/tests

    # Setting operations
    # List all settings
    settings = client.list_setting()
    # Get setting by NAME/ID
    backupTargetsetting = client.by_id_setting(id="backup-target")
    # Update a setting
    backupTargetsetting = client.update(backupTargetsetting, value="s3://backupbucket@us-east-1/")
    # Find more examples in Longhorn integration tests https://github.com/longhorn/longhorn-tests/tree/master/manager/integration/tests
    ```

