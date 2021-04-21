---
title: "Troubleshooting: Recurring job does not create new jobs after detaching and attaching volume"
author: Chin-Ya Huang
draft: false
date: 2021-04-21
categories:
  - "recurring job"
---

## Applicable versions

All Longhorn versions.

## Symptoms

Recurring job does not create new jobs when the volume is attached after being detached for a long time.

According to Kubernetes [CronJob limitations](https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/#cron-job-limitations):
> For every CronJob, the CronJob Controller checks how many schedules it missed in the duration from its last scheduled time until now. If there are more than 100 missed schedules, then it does not start the job and logs the error
>
>```
>Cannot determine if job needs to be started. Too many missed start time (> 100). Set or decrease .spec.startingDeadlineSeconds or check clock skew.
>```

That means the duration of the attach/detach operation that the recurring job can tolerate is depending on the scheduled interval.

For example, if the recurring backup job is set to run every minute, then the toleration would be 100 minutes.

## Solution

Directly delete the stuck cronjob to allow Longhorn to recreate it.
```
ip-172-30-0-211:/home/ec2-user # kubectl -n longhorn-system get cronjobs
NAME                                                  SCHEDULE    SUSPEND   ACTIVE   LAST SCHEDULE   AGE
pvc-394e6006-9c34-47da-bf27-2286ae669be1-c-ptl8l1-c   * * * * *   False     1        47s             2m23s

ip-172-30-0-211:/home/ec2-user # kubectl -n longhorn-system delete cronjobs/pvc-394e6006-9c34-47da-bf27-2286ae669be1-c-ptl8l1-c
cronjob.batch "pvc-394e6006-9c34-47da-bf27-2286ae669be1-c-ptl8l1-c" deleted

ip-172-30-0-211:/home/ec2-user # kubectl -n longhorn-system get cronjobs
No resources found in longhorn-system namespace.

ip-172-30-0-211:/home/ec2-user # sleep 60

ip-172-30-0-211:/home/ec2-user # kubectl -n longhorn-system get cronjobs
NAME                                                  SCHEDULE    SUSPEND   ACTIVE   LAST SCHEDULE   AGE
pvc-394e6006-9c34-47da-bf27-2286ae669be1-c-ptl8l1-c   * * * * *   False     1        2s             3m21s
```

## Related information

* Related Longhorn issue: https://github.com/longhorn/longhorn/issues/2513
