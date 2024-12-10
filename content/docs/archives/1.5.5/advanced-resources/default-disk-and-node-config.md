---
title: Configuring Defaults for Nodes and Disks
weight: 6
---

_Available as of v0.8.1_

This feature allows the user to customize the default disks and node configurations in Longhorn for newly added nodes using Kubernetes labels and annotations instead of the Longhorn API or UI.

Customizing the default configurations for disks and nodes is useful for scaling the cluster because it eliminates the need to configure Longhorn manually for each new node if the node contains more than one disk, or if the disk configuration is different for new nodes.

Longhorn will not keep the node labels or annotations in sync with the current Longhorn node disks or tags. Nor will Longhorn keep the node disks or tags in sync with the nodes, labels or annotations after the default disks or tags have been created.

### Adding Node Tags to New Nodes

When a node does not have a tag, you can use a node annotation to set the node tags, as an alternative to using the Longhorn UI or API.

1. Scale up the Kubernetes cluster. The newly added nodes contain no node tags.
2. Add annotations to the new Kubernetes nodes that specify what the default node tags should be. The annotation format is:

    ```
    node.longhorn.io/default-node-tags: <node tag list with JSON string format>
    ```
    For example:

    ```
    node.longhorn.io/default-node-tags: '["fast","storage"]'
    ``` 
3. Wait for Longhorn to sync the node tag automatically.

> **Result:** If the node tag list was originally empty, Longhorn updates the node with the tag list, and you will see the tags for that node updated according to the annotation. If the node already had tags, you will see no change to the tag list.
### Customizing Default Disks for New Nodes

Longhorn uses the **Create Default Disk on Labeled Nodes** setting to enable default disk customization.

If the setting is disabled, Longhorn will create a default disk using `setting.default-data-path` on all new nodes.

If the setting is enabled, Longhorn will decide to create the default disks or not, depending on the node's label value of `node.longhorn.io/create-default-disk`.

- If the node's label value is `true`, Longhorn will create the default disk using `settings.default-data-path` on the node. If the node already has existing disks, Longhorn will not change anything.
- If the node's label value is `config`, Longhorn will check for the `node.longhorn.io/default-disks-config` annotation and create default disks according to it. If there is no annotation, or if the annotation is invalid, or the label value is invalid, Longhorn will not change anything.

The value of the label will be in effect only when the setting is enabled.

If the `create-default-disk` label is not set, the default disk will not be automatically created on the new nodes when the setting is enabled.

The configuration described in the annotation only takes effect when there are no existing disks or tags on the node.

If the label or annotation fails validation, the whole annotation is ignored. 

> **Prerequisite:** The Longhorn setting **Create Default Disk on Labeled Nodes** must be enabled.
1. Add new nodes to the Kubernetes cluster.
2. Add the label to the node. Longhorn relies on the label to decide how to customize default disks:

    ```
    node.longhorn.io/create-default-disk: 'config'
    ```

3. Then add an annotation to the node. The annotation is used to specify the configuration of default disks. The format is:

    ```
    node.longhorn.io/default-disks-config: <disks configuration with JSON string format>
    ```

    For example, the following disk configuration can be specified in the annotation:

    ```
    node.longhorn.io/default-disks-config: 
    '[
        { 
            "path":"/mnt/disk1",
            "allowScheduling":true
        },
        {   
            "name":"fast-ssd-disk", 
            "path":"/mnt/disk2",
            "allowScheduling":false,
            "storageReserved":10485760,
            "tags":[
                "ssd",
                "fast"
            ]
        }
    ]'
    ```

    > **Note:** If the same name is specified for different disks, the configuration will be treated as invalid.
    
4. Wait for Longhorn to create the customized default disks automatically.

> **Result:** The disks will be updated according to the annotation.

### Launch Longhorn with multiple disks
1. Add the label to all nodes before launching Longhorn. 

    ```
    node.longhorn.io/create-default-disk: 'config'
    ```

2. Then add the disk config annotation to all nodes:

    ```
    node.longhorn.io/default-disks-config: '[ { "path":"/var/lib/longhorn", "allowScheduling":true
      }, { "name":"fast-ssd-disk", "path":"/mnt/extra", "allowScheduling":false, "storageReserved":10485760,
      "tags":[ "ssd", "fast" ] }]'
    ```
3. Deploy Longhorn with `create-default-disk-labeled-nodes: true`, check [here](../deploy/customizing-default-settings) for customizing the default settings of Longhorn.
