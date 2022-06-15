---
title: "Troubleshooting: Longhorn default settings do not persist"
author: Chin-Ya Huang
draft: false
date: 2021-04-29
categories:
  - "setting"
---

## Applicable versions

Longhorn version < v1.3.0.

## Symptoms

* When upgrading Longhorn system via helm or Rancher App, the modified Longhorn default settings doesn't persist.

* When modifying the default settings via `kubectl -n longhorn-system edit configmap longhorn-default-setting`, the modification won't be applied to the Longhorn system.

## Background

This default setting is only for a Longhorn system that hasn’t been deployed. It has no impact on an existing Longhorn system. 

## Solution

We recommend using the Longhorn UI to change Longhorn setting on the existing cluster.

You can also use the `kubectl`, but please be aware **this will bypass Longhorn backend validation**.
```
kubectl edit settings <SETTING-NAME> -n longhorn-system
```
