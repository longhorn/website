# Default disks and node configuration

## Overview

This feature allows the user to customize the default disks and node configurations in Longhorn for newly added nodes **using Kubernetes label and annotation**, instead of using Longhorn API or UI.

This feature is available since v0.8.1.

## Usage

### Add node tags for new nodes

1. Scale up the Kubernetes cluster. Then the newly added nodes contain no node tag.
2. Add the annotations to the new Kubernetes nodes. 
    - The annotation format is `node.longhorn.io/default-node-tags: <node tag list with JSON string format>`. For example:
    ```
    node.longhorn.io/default-node-tags: '["fast","storage"]'
    ``` 
3. Wait for Longhorn syncing the node tag automatically.

### Customize default disks for new nodes

1. Enable the Longhorn setting `Create Default Disk on Labeled Nodes` to enable the feature. After the feature is enabled, the default disk will not be automatically created on the new nodes unless a certain label was set. 
2. Add new nodes to the Kubernetes cluster, e.g. by using Rancher or Terraform, etc.
3. Patch the label and annotation to each new node to define the default disks.
    - Longhorn relies on the label to decide how to customize default disks. Since we choose using annotation here, the label should be:
    ```
    node.longhorn.io/create-default-disk: 'config'
    ```
    - The annotation is used to specify the configuration of default disks. The format is `node.longhorn.io/default-disks-config: <disks configuration with JSON string format>`. For example:
    ```
    node.longhorn.io/default-disks-config: 
    '[{"path":"/mnt/disk1","allowScheduling":false},
      {"path":"/mnt/disk2","allowScheduling":false,"storageReserved":1024,"tags":["ssd","fast"]}]'
    ```
4. Wait for Longhorn creating the customized default disks automatically.

### Notice
1. This feature will only take effect when there is no disks/tags on the node.
2. Longhorn will not keep the node label/annotations in sync with the current Longhorn node disks/tags.

