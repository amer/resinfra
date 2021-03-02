# POC: Logging with ELK
The following will demonstrate how to use the Elasticsearch - Logstash - Kibana (ELK) stack to collect, process and visualize logs. We will use filebeat to push system logs to the ELK. There is a number of [other beats available](https://www.elastic.co/de/beats/). 

*Caveats*:
For ease of use we will have the ELK run in docker as a single node cluster. To keep things simple, we will also not define any logstash pipelines. Pipelines could be defined in a `config-dir` and then mounted to the container. For further information on how to configure Logstash for docker see [here](https://www.elastic.co/guide/en/logstash/current/docker-config.html).

## Prerequisites
- docker ([Ubuntu 20 installation](https://docs.docker.com/engine/install/ubuntu/)) 
- docker compose ([Ubuntu 20 installation](https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-compose-on-ubuntu-20-04))

### Setting up the ELK
Start the docker containers

```
$ docker-compose up -d
```

Kibana should now be exposed to port 5601 of the host. Elasticsearch will be exposed to the host on port 9200.

### Install filebeat
We will install filebeat manually on the same host as we are running the ELK containers.

For Ubuntu follow [these](https://www.elastic.co/guide/en/beats/filebeat/current/setup-repositories.html#_apt) instructions to install filebeat with `apt`. If you are on any other os/distribution, see [here](https://www.elastic.co/guide/en/beats/filebeat/current/filebeat-installation-configuration.html#installation).

## POC
Filebeat ships with a list of preconfigured [modules](https://www.elastic.co/guide/en/beats/filebeat/current/filebeat-modules.html) that allow to directly plug into logs of services running on the target. 
You can list all modules with 

```
$ logstash modules list
```

For the sake of this poc, we will enable the `system` module.

```
$ logstash modules enable system
```

For further configuration, check the logstash config file. For the sake of this poc no further configuration is required. 
To find the configuration directory according to your installation refer to [the docs](https://www.elastic.co/guide/en/beats/filebeat/current/directory-layout.html).

Setup filebeat. This will create among others an index in your ES cluster (this might take a minute or two). The index will be called in the likes of `filebeat-7.10.0-yyyy.mm.dd-000001`.

```
$ filebeat setup -e
```

Filebeat might try to set up dashboards in Kibana. For the default config and the current docker setup this will fail. However, this is not relevant for the sake of this poc. 

Once the setup has completed sucessfully, start filebeat.

```
$ filebeat -e
```

Filebeat should now start sending messages to the respective ES index. 

You can verify that logs are arriving in your ES cluster either by checking directly from Kibana or by querying ES from the REST API. 

In Kibana, filebeat should have already set up a `filebeat.*` index pattern that you can use to query the respective ES indices. 

If you want to query ES directly (from the host where your containers are running), list all available indices first.

```
$ curl localhost:9200/_cat/indices
```

Pick the correct filebeat index and check its content

```
$ curl localhost:9200/filebeat-7.10.0-2020.12.02-000001/_search?pretty=true&q=*:*
```

Happy logging!
