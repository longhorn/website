---
title: "Troubleshooting: Create Support Bundle with cURL"
author: Chin-Ya Huang
draft: false
date: 2021-04-12
categories:
  - "support bundle"
---

## Applicable versions

All Longhorn versions.

## Symptoms

Not able to create the support bundle with a web browser.

## Solution

1. Expose Longhorn backend service. Below is an example using `NodePort`, you can also export via load balancer if one is set up.
    ```
    ip-172-30-0-21:~ # kubectl -n longhorn-system     patch svc longhorn-backend -p '{"spec":    {"type":"NodePort"}}'
    service/longhorn-backend patched
    ip-172-30-0-21:~ # kubectl -n longhorn-system get     svc/longhorn-backend
    NAME               TYPE       CLUSTER-IP          EXTERNAL-IP   PORT(S)          AGE
    longhorn-backend   NodePort   10.43.136.157       <none>        9500:32595/TCP   156m
    ```

2. Run the below script to create and download the support bundle.
You will need to replace the `BACKEND_URL`, `ISSUE_URL`, `ISSUE_DESCRIPTION`.
    ```
    # Replace this block ====>
    BACKEND_URL="18.141.237.97:32595"

    ISSUE_URL="https://github.com/longhorn/longhorn/issues/dummy"
    ISSUE_DESCRIPTION="dummy description"
    # <==== Replace this block

    # Request to create the support bundle
    REQUEST_SUPPORT_BUNDLE=$( curl -sSX POST -H 'Content-Type: application/json' -d '{ "issueURL": "'"${ISSUE_URL}"'", "description": "'"${ISSUE_DESCRIPTION}"'" }' http://${BACKEND_URL}/v1/supportbundles )

    ID=$( jq -r '.id' <<< ${REQUEST_SUPPORT_BUNDLE} )
    SUPPORT_BUNDLE_NAME=$( jq -r '.name' <<< ${REQUEST_SUPPORT_BUNDLE} )
    echo "Creating support bundle ${SUPPORT_BUNDLE_NAME} on Node ${ID}"

    while [ $(curl -sSX GET http://${BACKEND_URL}/v1/supportbundles/${ID}/${SUPPORT_BUNDLE_NAME} | jq -r '.state' ) != "ReadyForDownload" ]; do
      echo "Progress: $(curl -sSX GET http://${BACKEND_URL}/v1/supportbundles/${ID}/${SUPPORT_BUNDLE_NAME} | jq -r '.progressPercentage' )%"
      sleep 1s
    done

    curl -X GET http://${BACKEND_URL}/v1/supportbundles/${ID}/${SUPPORT_BUNDLE_NAME}/download --output /tmp/${SUPPORT_BUNDLE_NAME}.zip
    echo "Downloaded support bundle to /tmp/${SUPPORT_BUNDLE_NAME}.zip"
    ```

## Related information

* Related Longhorn comment: https://github.com/longhorn/longhorn/issues/2118#issuecomment-748099002
