---
title: "Troubleshooting: Longhorn-UI: Error during WebSocket handshake: Unexpected response code: 200 #2265"
author: Clark Hsu
draft: false
date: 2021-03-09
catelogies:
  - "longhorn-ui"
---

## Applicable versions

Existing Longhorn versions < v1.1.0 upgrade to Longhorn >= v1.1.0.

## Symptoms

After upgrading Longhorn to version >= v1.1.0, the following is encountered:

Ingress messages:

```
{"level":"error","msg":"vulcand/oxy/forward/websocket: Error dialing \"10.17.1.246\": websocket: bad handshake with resp: 200 200 OK","time":"2021-03-09T08:29:03Z"}
```

Longhorn UI messages:

```
10.46.0.3 - - [19/Feb/2021:11:33:24 +0000] "GET /node/v1/ws/1s/engineimages HTTP/1.1" 200 578 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/88.0.4324.150 Safari/537.36 Edg/88.0.705.68"
10.46.0.3 - - [19/Feb/2021:11:33:29 +0000] "GET /node/v1/ws/1s/volumes HTTP/1.1" 200 578 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/88.0.4324.150 Safari/537.36 Edg/88.0.705.68"
10.46.0.3 - - [19/Feb/2021:11:33:32 +0000] "GET /node/v1/ws/1s/nodes HTTP/1.1" 200 578 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/88.0.4324.150 Safari/537.36 Edg/88.0.705.68"
10.46.0.3 - - [19/Feb/2021:11:33:37 +0000] "GET /node/v1/ws/1s/events HTTP/1.1" 200 578 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/88.0.4324.150 Safari/537.36 Edg/88.0.705.68"
10.46.0.3 - - [19/Feb/2021:11:33:38 +0000] "GET /node/v1/ws/1s/engineimages HTTP/1.1" 200 578 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/88.0.4324.150 Safari/537.36 Edg/88.0.705.68"
10.46.0.3 - - [19/Feb/2021:11:33:41 +0000] "GET /node/v1/ws/1s/volumes HTTP/1.1" 200 578 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/88.0.4324.150 Safari/537.36 Edg/88.0.705.68"
```

## Reason

To support different routing (Rancher-Proxy, NodePort, Ingress, and Ngnix), Longhorn v1.1.0 has restructured the UI to use hash history for two reasons:

- To support Longhorn UI routing to different paths. e.g., /longhorn/#/dashboard
- To support single-page application by disassociating frontend and backend.

As result, `<LONGHORN_URL>/<TAG>` changes to `<LONGHORN_URL>/#/<TAG>`.

Afterward, output messages should be similar to the following:

Ingress messages should have no websocket error:

```
time="2021-03-16T04:54:23Z" level=debug msg="websocket: open" id=6809628160892941023 type=events
time="2021-03-16T04:54:23Z" level=debug msg="websocket: open" id=3234910863291903636 type=engineimages
time="2021-03-16T04:54:23Z" level=debug msg="websocket: open" id=2117763315178050120 type=backingimages
time="2021-03-16T04:54:23Z" level=debug msg="websocket: open" id=621105775322000457 type=volumes
```

Longhorn UI messages:

Using Ingress:

```
10.42.0.8 - - [16/Mar/2021:04:54:34 +0000] "GET /v1/nodes HTTP/1.1" 200 6729 "http://10.17.0.169/" "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/89.0.4389.90 Safari/537.36"
10.42.0.8 - - [16/Mar/2021:04:54:34 +0000] "GET /v1/backingimages HTTP/1.1" 200 117 "http://10.17.0.169/" "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/89.0.4389.90 Safari/537.36"
10.42.0.8 - - [16/Mar/2021:04:54:34 +0000] "GET /v1/volumes HTTP/1.1" 200 162 "http://10.17.0.169/" "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/89.0.4389.90 Safari/537.36"
10.42.0.8 - - [16/Mar/2021:04:54:34 +0000] "GET /v1/engineimages HTTP/1.1" 200 1065 "http://10.17.0.169/" "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/89.0.4389.90 Safari/537.36"
10.42.0.8 - - [16/Mar/2021:04:54:34 +0000] "GET /v1/settings HTTP/1.1" 200 30761 "http://10.17.0.169/" "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/89.0.4389.90 Safari/537.36"
10.42.0.8 - - [16/Mar/2021:04:54:34 +0000] "GET /v1/events HTTP/1.1" 200 62750 "http://10.17.0.169/" "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/89.0.4389.90 Safari/537.36"
```

Using Proxy:

```
10.42.0.0 - - [16/Mar/2021:05:03:51 +0000] "GET /v1/engineimages HTTP/1.1" 200 1070 "http://localhost:8001/api/v1/namespaces/longhorn-system/services/http:longhorn-frontend:80/proxy/" "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/89.0.4389.90 Safari/537.36"
10.42.0.0 - - [16/Mar/2021:05:03:51 +0000] "GET /v1/events HTTP/1.1" 200 62904 "http://localhost:8001/api/v1/namespaces/longhorn-system/services/http:longhorn-frontend:80/proxy/" "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/89.0.4389.90 Safari/537.36"
10.42.0.0 - - [16/Mar/2021:05:03:52 +0000] "GET /v1/engineimages HTTP/1.1" 200 1071 "http://localhost:8001/api/v1/namespaces/longhorn-system/services/http:longhorn-frontend:80/proxy/" "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/89.0.4389.90 Safari/537.36"
10.42.0.0 - - [16/Mar/2021:05:03:52 +0000] "GET /v1/nodes HTTP/1.1" 200 6756 "http://localhost:8001/api/v1/namespaces/longhorn-system/services/http:longhorn-frontend:80/proxy/" "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/89.0.4389.90 Safari/537.36"
10.42.0.0 - - [16/Mar/2021:05:03:52 +0000] "GET /v1/settings HTTP/1.1" 200 30882 "http://localhost:8001/api/v1/namespaces/longhorn-system/services/http:longhorn-frontend:80/proxy/" "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/89.0.4389.90 Safari/537.36"
10.42.0.0 - - [16/Mar/2021:05:03:52 +0000] "GET /v1/volumes HTTP/1.1" 200 168 "http://localhost:8001/api/v1/namespaces/longhorn-system/services/http:longhorn-frontend:80/proxy/" "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/89.0.4389.90 Safari/537.36"
10.42.0.0 - - [16/Mar/2021:05:03:52 +0000] "GET /v1/backingimages HTTP/1.1" 200 120 "http://localhost:8001/api/v1/namespaces/longhorn-system/services/http:longhorn-frontend:80/proxy/" "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/89.0.4389.90 Safari/537.36"
10.42.0.0 - - [16/Mar/2021:05:03:52 +0000] "GET /v1/events HTTP/1.1" 200 62900 "http://localhost:8001/api/v1/namespaces/longhorn-system/services/http:longhorn-frontend:80/proxy/" "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/89.0.4389.90 Safari/537.36"
```

#### Solution

1. Clear browser cache.
2. Access/Rebookmark Longhorn URL from `<LONGHORN_URL>/#`.

## Related information

* Related Longhorn issue: https://github.com/longhorn/longhorn/issues/2265
* Related Longhorn issue: https://github.com/longhorn/longhorn/issues/1660
