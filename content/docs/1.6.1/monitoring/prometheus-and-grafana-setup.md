---
title: Setting up Prometheus and Grafana to monitor Longhorn
weight: 1
---

This document is a quick guide to setting up the monitor for Longhorn.

Longhorn natively exposes metrics in [Prometheus text format](https://prometheus.io/docs/instrumenting/exposition_formats/#text-based-format) on a REST endpoint `http://LONGHORN_MANAGER_IP:PORT/metrics`.

You can use any collecting tools such as [Prometheus](https://prometheus.io/), [Graphite](https://graphiteapp.org/), [Telegraf](https://www.influxdata.com/time-series-platform/telegraf/) to scrape these metrics then visualize the collected data by tools such as [Grafana](https://grafana.com/).

See [Longhorn Metrics for Monitoring](../metrics) for available metrics.

## High-level Overview

The monitoring system uses `Prometheus` for collecting data and alerting, and `Grafana` for visualizing/dashboarding the collected data.

* Prometheus server which scrapes and stores time-series data from Longhorn metrics endpoints. The Prometheus is also responsible for generating alerts based on configured rules and collected data. Prometheus servers then send alerts to an Alertmanager.
* AlertManager then manages those alerts, including silencing, inhibition, aggregation, and sending out notifications via methods such as email, on-call notification systems, and chat platforms.
* Grafana which queries Prometheus server for data and draws a dashboard for visualization.

The below picture describes the detailed architecture of the monitoring system.

![images](/img/screenshots/monitoring/longhorn-monitoring-system.png)

There are 2 unmentioned components in the above picture:

* Longhorn Backend service is a service pointing to the set of Longhorn manager pods. Longhorn's metrics are exposed in Longhorn manager pods at the endpoint `http://LONGHORN_MANAGER_IP:PORT/metrics`.
* [Prometheus operator](https://github.com/prometheus-operator/prometheus-operator/blob/master/Documentation/user-guides/getting-started.md) makes running Prometheus on top of Kubernetes very easy. The operator watches 3 custom resources: ServiceMonitor, Prometheus ,and AlertManager.
  When you create those custom resources, Prometheus Operator deploys and manages the Prometheus server, AlertManager with the user-specified configurations.

## Installation

This document uses the `default` namespace for the monitoring system. To install on a different namespace, change the field `namespace: <OTHER_NAMESPACE>` in manifests.

### Install Prometheus Operator
Follow instructions in [Prometheus Operator - Quickstart](https://github.com/prometheus-operator/prometheus-operator#quickstart).

> **NOTE:** You may need to choose a release that is compatible with the Kubernetes version of the cluster.

### Install Longhorn ServiceMonitor

#### Install Longhorn ServiceMonitor with Kubectl

Create a ServiceMonitor for Longhorn Manager.

    ```yaml
    apiVersion: monitoring.coreos.com/v1
    kind: ServiceMonitor
    metadata:
      name: longhorn-prometheus-servicemonitor
      namespace: default
      labels:
        name: longhorn-prometheus-servicemonitor
    spec:
      selector:
        matchLabels:
          app: longhorn-manager
      namespaceSelector:
        matchNames:
        - longhorn-system
      endpoints:
      - port: manager
    ```

#### Install Longhorn ServiceMonitor with Helm

1. Modify the YAML file `longhorn/chart/values.yaml`.

    ```yaml
    metrics:
      serviceMonitor:
        # -- Setting that allows the creation of a [Prometheus Operator](https://prometheus-operator.dev/) ServiceMonitor resource for Longhorn Manager components.
        enabled: true
    ```

1. Create a ServiceMonitor for Longhorn Manager using Helm.

    ```bash
      helm upgrade longhorn longhorn/longhorn --namespace longhorn-system -f values.yaml
    ```

Longhorn ServiceMonitor is a [Prometheus Operator](https://prometheus-operator.dev/) custom resource. This setup allows the Prometheus server to discover all Longhorn Manager pods and their respective endpoints.

You can use the label selector `app: longhorn-manager` to select the longhorn-backend service, which points to the set of Longhorn Manager pods.

### Install and configure Prometheus AlertManager

1. Create a highly available Alertmanager deployment with 3 instances.

    ```yaml
    apiVersion: monitoring.coreos.com/v1
    kind: Alertmanager
    metadata:
      name: longhorn
      namespace: default
    spec:
      replicas: 3
    ```

1. The Alertmanager instances will not start unless a valid configuration is given.
See [Prometheus - Configuration](https://prometheus.io/docs/alerting/latest/configuration/) for more explanation.

    ```yaml
    global:
      resolve_timeout: 5m
    route:
      group_by: [alertname]
      receiver: email_and_slack
    receivers:
    - name: email_and_slack
      email_configs:
      - to: <the email address to send notifications to>
        from: <the sender address>
        smarthost: <the SMTP host through which emails are sent>
        # SMTP authentication information.
        auth_username: <the username>
        auth_identity: <the identity>
        auth_password: <the password>
        headers:
          subject: 'Longhorn-Alert'
        text: |-
          {{ range .Alerts }}
            *Alert:* {{ .Annotations.summary }} - `{{ .Labels.severity }}`
            *Description:* {{ .Annotations.description }}
            *Details:*
            {{ range .Labels.SortedPairs }} • *{{ .Name }}:* `{{ .Value }}`
            {{ end }}
          {{ end }}
      slack_configs:
      - api_url: <the Slack webhook URL>
        channel: <the channel or user to send notifications to>
        text: |-
          {{ range .Alerts }}
            *Alert:* {{ .Annotations.summary }} - `{{ .Labels.severity }}`
            *Description:* {{ .Annotations.description }}
            *Details:*
            {{ range .Labels.SortedPairs }} • *{{ .Name }}:* `{{ .Value }}`
            {{ end }}
          {{ end }}
    ```

    Save the above Alertmanager config in a file called `alertmanager.yaml` and create a secret from it using kubectl.

    Alertmanager instances require the secret resource naming to follow the format `alertmanager-<ALERTMANAGER_NAME>`. In the previous step, the name of the Alertmanager is `longhorn`, so the secret name must be `alertmanager-longhorn`

    ```
    $ kubectl create secret generic alertmanager-longhorn --from-file=alertmanager.yaml -n default
    ```

1. To be able to view the web UI of the Alertmanager, expose it through a Service. A simple way to do this is to use a Service of type NodePort.

    ```yaml
    apiVersion: v1
    kind: Service
    metadata:
      name: alertmanager-longhorn
      namespace: default
    spec:
      type: NodePort
      ports:
      - name: web
        nodePort: 30903
        port: 9093
        protocol: TCP
        targetPort: web
      selector:
        alertmanager: longhorn
    ```

    After creating the above service, you can access the web UI of Alertmanager via a Node's IP and the port 30903.

    > Use the above `NodePort` service for quick verification only because it doesn't communicate over the TLS connection. You may want to change the service type to `ClusterIP` and set up an Ingress-controller to expose the web UI of Alertmanager over a TLS connection.

### Install and configure Prometheus server

1. Create PrometheusRule custom resource to define alert conditions. See more examples about Longhorn alert rules at [Longhorn Alert Rule Examples](../alert-rules-example).

    ```yaml
    apiVersion: monitoring.coreos.com/v1
    kind: PrometheusRule
    metadata:
      labels:
        prometheus: longhorn
        role: alert-rules
      name: prometheus-longhorn-rules
      namespace: default
    spec:
      groups:
      - name: longhorn.rules
        rules:
        - alert: LonghornVolumeUsageCritical
          annotations:
            description: Longhorn volume {{$labels.volume}} on {{$labels.node}} is at {{$value}}% used for
              more than 5 minutes.
            summary: Longhorn volume capacity is over 90% used.
          expr: 100 * (longhorn_volume_usage_bytes / longhorn_volume_capacity_bytes) > 90
          for: 5m
          labels:
            issue: Longhorn volume {{$labels.volume}} usage on {{$labels.node}} is critical.
            severity: critical
    ```
   See [Prometheus - Alerting rules](https://prometheus.io/docs/prometheus/latest/configuration/alerting_rules/#alerting-rules) for more information.

1. If [RBAC](https://kubernetes.io/docs/reference/access-authn-authz/authorization/) authorization is activated, Create a ClusterRole and ClusterRoleBinding for the Prometheus Pods.

    ```yaml
    apiVersion: v1
    kind: ServiceAccount
    metadata:
      name: prometheus
      namespace: default
    ```

    ```yaml
    apiVersion: rbac.authorization.k8s.io/v1
    kind: ClusterRole
    metadata:
      name: prometheus
      namespace: default
    rules:
    - apiGroups: [""]
      resources:
      - nodes
      - services
      - endpoints
      - pods
      verbs: ["get", "list", "watch"]
    - apiGroups: [""]
      resources:
      - configmaps
      verbs: ["get"]
    - nonResourceURLs: ["/metrics"]
      verbs: ["get"]
    ```

    ```yaml
    apiVersion: rbac.authorization.k8s.io/v1
    kind: ClusterRoleBinding
    metadata:
      name: prometheus
    roleRef:
      apiGroup: rbac.authorization.k8s.io
      kind: ClusterRole
      name: prometheus
    subjects:
    - kind: ServiceAccount
      name: prometheus
      namespace: default
    ```

1. Create a Prometheus custom resource. Notice that we select the Longhorn service monitor and Longhorn rules in the spec.

    ```yaml
    apiVersion: monitoring.coreos.com/v1
    kind: Prometheus
    metadata:
      name: longhorn
      namespace: default
    spec:
      replicas: 2
      serviceAccountName: prometheus
      alerting:
        alertmanagers:
          - namespace: default
            name: alertmanager-longhorn
            port: web
      serviceMonitorSelector:
        matchLabels:
          name: longhorn-prometheus-servicemonitor
      ruleSelector:
        matchLabels:
          prometheus: longhorn
          role: alert-rules
    ```

1. To be able to view the web UI of the Prometheus server, expose it through a Service. A simple way to do this is to use a Service of type NodePort.

    ```yaml
    apiVersion: v1
    kind: Service
    metadata:
      name: prometheus-longhorn
      namespace: default
    spec:
      type: NodePort
      ports:
      - name: web
        nodePort: 30904
        port: 9090
        protocol: TCP
        targetPort: web
      selector:
        prometheus: longhorn
    ```

    After creating the above service, you can access the web UI of the Prometheus server via a Node's IP and the port 30904.

    > At this point, you should be able to see all Longhorn manager targets as well as Longhorn rules in the targets and rules section of the Prometheus server UI.

    > Use the above NodePort service for quick verification only because it doesn't communicate over the TLS connection. You may want to change the service type to `ClusterIP` and set up an Ingress controller to expose the web UI of the Prometheus server over a TLS connection.

### Setup Grafana

1. Create Grafana datasource ConfigMap.

    ```yaml
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: grafana-datasources
      namespace: default
    data:
      prometheus.yaml: |-
        {
            "apiVersion": 1,
            "datasources": [
                {
                   "access":"proxy",
                    "editable": true,
                    "name": "prometheus-longhorn",
                    "orgId": 1,
                    "type": "prometheus",
                    "url": "http://prometheus-longhorn.default.svc:9090",
                    "version": 1
                }
            ]
        }
    ```

    > **NOTE:** change field `url` if you are installing the monitoring stack in a different namespace.
    > `http://prometheus-longhorn.<NAMESPACE>.svc:9090"`

1. Create Grafana Deployment.
    ```yaml
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: grafana
      namespace: default
      labels:
        app: grafana
    spec:
      replicas: 1
      selector:
        matchLabels:
          app: grafana
      template:
        metadata:
          name: grafana
          labels:
            app: grafana
        spec:
          containers:
          - name: grafana
            image: grafana/grafana:7.1.5
            ports:
            - name: grafana
              containerPort: 3000
            resources:
              limits:
                memory: "500Mi"
                cpu: "300m"
              requests:
                memory: "500Mi"
                cpu: "200m"
            volumeMounts:
              - mountPath: /var/lib/grafana
                name: grafana-storage
              - mountPath: /etc/grafana/provisioning/datasources
                name: grafana-datasources
                readOnly: false
          volumes:
            - name: grafana-storage
              emptyDir: {}
            - name: grafana-datasources
              configMap:
                  defaultMode: 420
                  name: grafana-datasources
    ```

1. Create Grafana Service.
    ```yaml
    apiVersion: v1
    kind: Service
    metadata:
      name: grafana
      namespace: default
    spec:
      selector:
        app: grafana
      type: ClusterIP
      ports:
        - port: 3000
          targetPort: 3000
    ```

1. Expose Grafana on NodePort `32000`.
    ```yaml
    kubectl -n default patch svc grafana --type='json' -p '[{"op":"replace","path":"/spec/type","value":"NodePort"},{"op":"replace","path":"/spec/ports/0/nodePort","value":32000}]'
    ```

   > Use the above NodePort service for quick verification only because it doesn't communicate over the TLS connection. You may want to change the service type to ClusterIP and set up an Ingress controller to expose Grafana over a TLS connection.

1. Access the Grafana dashboard using any node IP on port `32000`.
    ```
    # Default Credential
    User: admin
    Pass: admin
    ```

1. Setup Longhorn dashboard.

    Once inside Grafana, import the prebuilt [Longhorn example dashboard](https://grafana.com/grafana/dashboards/17626).

    See [Grafana Lab - Export and import](https://grafana.com/docs/grafana/latest/reference/export_import/) for instructions on how to import a Grafana dashboard.

    You should see the following dashboard at successful setup:
    ![images](/img/screenshots/monitoring/longhorn-example-grafana-dashboard.png)
