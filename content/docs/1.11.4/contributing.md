---
title: Contributing
weight: 6
---

Longhorn is open source software, so contributions are greatly welcome. Please read the [Cloud Native Computing Foundation Code of Conduct](https://github.com/cncf/foundation/blob/master/code-of-conduct.md) and [Contributing Guidelines](https://github.com/longhorn/longhorn/blob/master/CONTRIBUTING.md) before contributing.

Contributing code is not the only way of contributing. We value feedback very much and many of the Longhorn features are originated from users' feedback. If you have any feedback, feel free to [file an issue](https://github.com/longhorn/longhorn/issues/new/choose) and talk to the developers at the [CNCF](https://slack.cncf.io/) [#longhorn](https://cloud-native.slack.com/messages/longhorn) slack channel.

Longhorn is a [CNCF Incubating Project.](https://www.cncf.io/projects/longhorn/)

![Longhorn is a CNCF Incubating Project](https://raw.githubusercontent.com/cncf/artwork/master/other/cncf/horizontal/color/cncf-color.svg)

## Source Code

Longhorn is 100% open source software under the auspices of the [Cloud Native Computing Foundation](https://cncf.io). The project's source code is spread across a number of repos:

| Component                      | What it does                                                           | GitHub repo                                                                                 |
| :----------------------------- | :--------------------------------------------------------------------- | :------------------------------------------------------------------------------------------ |
| Longhorn Backing Image Manager | Backing image download, sync, and deletion in a disk                   | [longhorn/backing-image-manager](https://github.com/longhorn/backing-image-manager)         |
| Longhorn Engine                | Core controller/replica logic                                          | [longhorn/longhorn-engine](https://github.com/longhorn/longhorn-engine)                     |
| Longhorn Instance Manager      | Controller/replica instance lifecycle management                       | [longhorn/longhorn-instance-manager](https://github.com/longhorn/longhorn-instance-manager) |
| Longhorn Manager               | Longhorn orchestration, includes CSI driver for Kubernetes             | [longhorn/longhorn-manager](https://github.com/longhorn/longhorn-manager)                   |
| Longhorn Share Manager         | NFS provisioner that exposes Longhorn volumes as ReadWriteMany volumes | [longhorn/longhorn-share-manager](https://github.com/longhorn/longhorn-share-manager)       |
| Longhorn UI                    | The Longhorn dashboard                                                 | [longhorn/longhorn-ui](https://github.com/longhorn/longhorn-ui)                             |

## License

Copyright (c) 2014-2021 The Longhorn Authors.

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at [Apache License 2.0](http://www.apache.org/licenses/LICENSE-2.0).

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
