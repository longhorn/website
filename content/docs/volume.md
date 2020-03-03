---
title: Volume operations
---

### Changing replica count of the volumes

The default replica count can be changed in the setting.

Also, when a volume is attached, the user can change the replica count for the volume in the UI.

Longhorn will always try to maintain at least given number of healthy replicas for each volume.
1. If the current healthy replica count is less than specified replica count, Longhorn will start rebuilding new replicas.
2. If the current healthy replica count is more than specified replica count, Longhorn will do nothing. In this situation, if user delete one or more healthy replicas, or there are healthy replicas failed, as long as the total healthy replica count doesn't dip below the specified replica count, Longhorn won't start rebuilding new replicas.

### Maintenance mode

After v0.6.0, when the user attaching the volume from Longhorn UI, there is a checkbox for `Maintenance mode`. The option will result in attaching the volume without enabling the frontend (block device or iSCSI), to make sure no one can access the volume data when the volume is attached.

It's mainly used to perform `Snapshot Revert`. After v0.6.0, Snapshot Reverting operation required volume to be in `Maintenance mode` since we cannot modify the block device's content with the volume mounted or being used, otherwise it will cause filesystem corruptions. 

It's also useful to inspect the volume state without worry that the data can be accessed by accident.
