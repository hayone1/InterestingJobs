HOW-TO

You can download, edit and apply the manifest[Link](https://raw.githubusercontent.com/hayone1/InterestingJobs/main/notifications/connectivity-monitor/template-kubernetes.yaml).

Alternatively, using curl and yq, you can edit and run the below script.

```
export notification_hosts='[
    {
        "name" : "name",
        "host" : "host",
        "port" : "port"
    },
    {
        "name" : "name",
        "host" : "host",
        "port" : "port"
    }
]'
export notification_team='[
  {
    "type": "mention",
    "text": "<at>name</at>",
    "mentioned": {
        "id": "name.name@domain.com",
        "name": "name name"
    }
  },
  {
    "type": "mention",
    "text": "<at>name</at>",
    "mentioned": {
        "id": "name.name@domain.com",
        "name": "name name"
    }
  }
]'
manifest=$(curl https://raw.githubusercontent.com/hayone1/InterestingJobs/main/notifications/connectivity-monitor/template-kubernetes.yaml)
echo "$manifest" | yq '. |
(select(.kind == "Deployment").metadata.namespace) |= "dafault" |
(select(.kind == "ConfigMap").metadata.namespace) |= "dafault" |
(select(.kind == "ConfigMap").data.HTTPS_PROXY) |= "ip:port" |
(select(.kind == "ConfigMap").data.PROXY_BEFORE_TEST) |= "true" |
(select(.kind == "ConfigMap").data.PROXY_DURING_TEST) |= "false" |
(select(.kind == "ConfigMap").data.NOTIFY_ON_SUCCESS) |= "false" |
(select(.kind == "ConfigMap").data.NOTIFY_ON_FAILURE) |= "true" |
(select(.kind == "ConfigMap").data.SLEEP_INTERVAL) |= "60" |
(select(.kind == "ConfigMap").data.RETRY_EXPONENT) |= "2" |
(select(.kind == "ConfigMap").data.MAX_RETRY_INTERVAL) |= "3600" |
(select(.kind == "ConfigMap").data.HOSTS) |= strenv(notification_hosts) |
(select(.kind == "ConfigMap").data.TEAM) |= strenv(notification_team) | 
(select(.kind == "ConfigMap").data.WEBHOOK_URL) |= "https://url" |
(select(.kind == "ConfigMap").data.SCRIPT_URL) |= "https://raw.githubusercontent.com/hayone1/InterestingJobs/main/notifications/connectivity-monitor/check-connectivity-msteams.sh"'

kubectl apply --kubeconfig "kubeconfig.yaml" -f connectivity-manifest.yaml
```

you can also add podAffinity to the arguments. eg.

```
...
(select(.kind == "Deployment").spec.template.spec.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].key) = "node-key" |
(select(.kind == "Deployment").spec.template.spec.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].operator) = "In" |
(select(.kind == "Deployment").spec.template.spec.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].values[0]) = "node-value"
...
```
> Remember the Pipe "|"