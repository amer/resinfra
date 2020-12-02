# Centralized logging
Looking for a storage solution for logs.

## Requirements
- Centralized storage for all logs emitted by both the tooling & the deployed infrastructure
- Unified log gathering
- Visualization of logs


## Idea 1: ELK (preferred)
- Elasticsearc + Logstash + Kibana 
- Elasticsearch (ES) is a NoSQL open-source database
- Kibana is a dashboarding tool, developed from the same people. It integrates pretty easily with elasticsearch.
- Data can be fed into ES with [beats](https://www.elastic.co/de/beats/). These are agents installed on the targets that collect  data (logs). 
- Data can be pre processed with [logstash](https://www.elastic.co/de/logstash). You define a set of rules that will be applied to incomming logs. Example (from [here](https://github.com/enowars/EnoELK/blob/master/config-dir/enologmessage.conf)):

        input {
            beats {
                port => 5045
                }
        }

        filter {
            grok {
                match => { "message" => "##ENOLOGMESSAGE %{GREEDYDATA:message}" }
                overwrite => ["message"]
                add_tag =>  [ "enologmessage" ]
            }
            if "enologmessage" in [tags] {
                json {
                source => "message"
                target => "enologs"
                skip_on_invalid_json => true
                }
                mutate {
                replace => {
                    "[@metadata][index_prefix]" => "enologmessage"
                    }
                }
            }   
            if "enologmessage" not in [tags] and "enostatisticsmessage" not in [tags] {
                drop { }
            }
        }

        output {
            elasticsearch {
                hosts => ["http://elasticsearch:9200"]
                index => "%{[@metadata][index_prefix]}-%{+YYYY.MM.dd}"
            }
        }

- Kibana is used to visualize / search logs. 

## Idea 2: [Graylog](https://www.graylog.org/products/open-source)
- Comes with a dashboard + search functions (comparable to ELK)
- [Graylog sidecar](https://www.graylog.org/features/sidecar) acts as the centralized log collection configuration. All configuration can be controlled from the admin pane. 
- Graylog has no unified agent that is used to send logs (such as ES beats) but offers a wide range of possibilites for sending logs to the log db (directly through TCP, through a Kafka cluster, ...). For more see [here](https://docs.graylog.org/en/latest/pages/sending_data.html).
- Open source version should have all necessary functionality. For a comparison with the enterprise version see [here](https://www.graylog.org/products/open-source-vs-enterprise).
