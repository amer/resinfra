# What is this?
In this document the possible solutions for triggering a script based on an monitoring event are discussed. Later the chosen solution is deployed in an setup und tested if it can fulfill our needs.

# Research

The first search results indicating towards https://github.com/imgix/prometheus-am-executor with a promising description: 
```
The prometheus-am-executor is a HTTP server that receives alerts from the Prometheus Alertmanager and executes a given command with alert details set as environment variables.
```

Further investigation lead to solutions that deploy a self programmed webserver as endpoint for prometheus alerts (https://medium.com/@josebiro/building-a-simple-command-and-control-system-with-prometheus-6ce110b81e41)

These have in common that they both use the prometheus alertmanager. Further investigation on the prometheus alertmanager lead to the assumption that the prometheus alertmanager is the designated part on the prometheus side to create and send alerts. As shown in the both example projects and the [prometheus alertmanager documentation](https://prometheus.io/docs/alerting/latest/configuration/#webhook_config) the alerts can be send as json objects to a webserver. This should be everything we need to trigger a script based on the information in the json object.

The next step is to determine what way is the best to receive these alerts. 

A self developed webserver has the advantage of full customizablity but also comes with a higher effort for the first runnable version. 

The prometheus-am-executor solution maybe exactly what we currently need. But it is not forseable if there will be use-cases that can not be covered by this tool.

With focus on the time to market and a working prototype I suggest using prometheus-am-executor.
## prometheus-am-executor
The prometheus-am-executor [example for rebooting a failing system](https://github.com/imgix/prometheus-am-executor#example-reboot-systems-with-errors) contain an detailed example configuration. When applying this configuration on the alertmanager, it will send the created alerts as http post json objects to the specified webserver. 

## Example prometheus alertmanager configuration files
https://prometheus.io/docs/alerting/latest/configuration/#webhook_config
### Receiver configuration
```
# Whether or not to notify about resolved alerts.
[ send_resolved: <boolean> | default = true ]

# The endpoint to send HTTP POST requests to.
url: <string>

# The HTTP client's configuration.
[ http_config: <http_config> | default = global.http_config ]

# The maximum number of alerts to include in a single webhook message. Alerts
# above this threshold are truncated. When leaving this at its default value of
# 0, all alerts are included.
[ max_alerts: <int> | default = 0 ]
```

### HTTP POST request
```
{
  "version": "4",
  "groupKey": <string>,              // key identifying the group of alerts (e.g. to deduplicate)
  "truncatedAlerts": <int>,          // how many alerts have been truncated due to "max_alerts"
  "status": "<resolved|firing>",
  "receiver": <string>,
  "groupLabels": <object>,
  "commonLabels": <object>,
  "commonAnnotations": <object>,
  "externalURL": <string>,           // backlink to the Alertmanager.
  "alerts": [
    {
      "status": "<resolved|firing>",
      "labels": <object>,
      "annotations": <object>,
      "startsAt": "<rfc3339>",
      "endsAt": "<rfc3339>",
      "generatorURL": <string>       // identifies the entity that caused the alert
    },
    ...
  ]
}
```
# Deploy a setup with Prometheus and the prometheus-am-executor

For this setup we will use 2 virtual machines running Debian 10:
* prometheus-vm - 10.1.0.9
* prometheus-am-executor-vm - 10.1.0.8

First setup everything on the prometheus-vm:
1. Install docker (https://docs.docker.com/engine/install/debian/)
2. deploy prometheus (https://prometheus.io/docs/prometheus/latest/installation/#using-docker)
3. deploy prometheus alertmanager (??)
4. Configure prometheus and altermanager

I stop at this point. The deployment of even a simple running example with prometheus is not trivial. I will go further if a team member can help me who has more experience with prometheus. 