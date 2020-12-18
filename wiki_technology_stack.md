# Tools we will use
* Terraform
* Prometheus


In the following, we want to evaluate a range of tools for a given task and explain the final choice.

# Monitoring solutions
We have looked into a couple of monitoring solutions listed and assessed below. Note, that this does not yet deal with reporting or visualizing monitoring results. 

## Tools
### [Telegraf](https://www.influxdata.com/time-series-platform/telegraf/)
Telegraf is an agent for collecting and sending server metrics, logs and traces. It is push-based, meaning that it will send data to the respective destination database by itself.
Developed by influxdata, but open-sourced, it offers seamless integration with InfluxDB as the backend database. 
Telegraf offers a wide range of [plugins](https://docs.influxdata.com/telegraf/v1.16/plugins/) that allows to pull metrics from different sources.

### [Sensu](https://sensu.io/)
Sensu tries to introduce another layer of abstraction to monitoring, providing an interface to publish and subscribe to events emitted from various monitoring solutions (Nagios, Telegraf, ...). 
Monitoring tasks are defined as code and events are collected by a central agent from where they can be processed. It allows for monitoring at different abstraction levels (from network over server to container).

### [Prometheus](https://prometheus.io/) 
Prometheus is the leading open source monitoring platform that takes care of both collecting as well as storing events. Other than Sensu and Telegraf, Prometheus follows a pull scheme instead of sending events to their respective destinations but comes with a service discovery functionality to collect targets.
It comes with its own [query language](https://prometheus.io/docs/prometheus/latest/querying/basics/) that can be used to deliver reports and / or build dashboards. 

In order to collect metrics for a large number of nodes [Prometheus Federation](https://prometheus.io/docs/prometheus/latest/federation/) can be used. Federation allows to aggregate data on target systems and to collect that data from another Prometheus instance. Note, that Prometheus will have to run on the target node. The collection is controlled by defining [scraping configurations](https://prometheus.io/docs/prometheus/latest/federation/#configuring-federation).

## Decision
We will move on with **Prometheus** for two reasons:
- The pull-based approach will allow us to more easily minimize the amount of data that has to travel the network. As data might have to travel across cloud provider boundaries, moving large amounts of data can become costly.
- Major parts of the team have experience in working with Prometheus. We would like to leverage that knowledge.

# Distributed Application
One of the main goals of this project is to run a distributed application on top of the cloud spanning infrastructure. Following are our requirements and a short documentation about the analysis and research process for the possible candidates **Galera** and **CockroachDB**. In the end, we choose CockroachDB because it seems to be the better choice for our use case.

For the distributed application we have some requirements that has to be fulfill:
* The application must support a distributed deployment plan, cluster functionalities or orchestration
* The application must support automatic recovery functionality
* The application must produce measurable output or actions
* The application must be easy to deploy
* There must be sufficient and good documentation for this application.
* There must be a easy benchmarking or stress testing tool / functionality for the application

And some requirements that would be nice to have:
* The application supports dynamic up and down scaling
* The application supports interfaces for our monitoring solution


## Galera Cluster
The idea to use Galera was pitched by Oliver because they have a Galera Cluster running.

A short research lead to the assumption that a Galera Cluster is not the right choice for our use case.

The source https://www.mysqlha.com/galera/ summarized the advantages and disadvantages of Galera. 

In this summary the comment about local high availability is "Failure is handled automatically. **But recovery of the failed node is manual and labor intensive process with possible cluster downtime if not properly planned.**"

Further it is stating about global disaster recovery "Does not support Global DR. Effective replication to remote site is not possible owing to latency issues."

And a comment about Multi-Site Operation: "Not suitable for multi-site owing to the latency attached to using syncronous replication."

All-In-All it sounds as the main requirements can not be fulfilled by Galera and is therefore no valid candidate for our use case.

## CockroachDB
CockroachDB looks like a promising candidate as it is advertised as a geo distributed database.

They introduce them selfes as:

*"CockroachDB is a distributed SQL database built on a transactional and strongly-consistent key-value store. It scales horizontally; survives disk, machine, rack, and even datacenter failures with minimal latency disruption and no manual intervention; supports strongly-consistent ACID transactions; and provides a familiar SQL API for structuring, manipulating, and querying data."*

And say they are the right choice for Multi-datacenter deployments and Multi-region deployments. (https://www.cockroachlabs.com/docs/v20.2/frequently-asked-questions.html)


A short dive in lead to valuable documentation about topics like [Multi-region survivability planning](https://www.cockroachlabs.com/docs/v20.2/disaster-recovery.html#multi-region-survivability-planning) and [Multi-region recovery](https://www.cockroachlabs.com/docs/v20.2/disaster-recovery.html#multi-region-recovery).

For their multi-region survivability they have the following table show how much nodes can fail with a given example deployment.

| Fault Tolerance Goals | 3 Regions (9 Nodes Total) | 4 Regions (12 Nodes Total) | 5 Regions (15 Nodes Total) |
|-----------------------|---------------------------|----------------------------|----------------------------|
| 1 Node                | RF = 3                    | RF = 3                     | RF = 3                     |
| 1 AZ                  | RF = 3                    | RF = 3                     | RF = 3                     |
| 1 Region              | RF = 3                    | RF = 3                     | RF = 3                     |
| 2 Nodes               | RF = 5                    | RF = 5                     | RF = 5                     |
| 1 Region + 1 Node     | RF = 9                    | RF = 7                     | RF = 5                     |
| 2 Regions             | Not possible              | Not possible               | RF = 5                     |
| 2 Regions + 1 Node    | Not possible              | Not possible               | RF = 15                    |

replication factor (RF); availability zones (AZ)


They also have a table that shows what actions are to take when a failure occurs on an 3 region setup with 3 AZs per region and 9 nodes with an replication factor of 3.


| Failure           | Availability | Consequence                                                                                                                           | Action to Take                                                                                                                                                                                                                                                                                                                                                                                                                               |
|-------------------|--------------|---------------------------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 1 Disk            | √            | Under-replicated data. Fewer resources for workload.                                                                                  | Restart the node with a new disk.                                                                                                                                                                                                                                                                                                  |
| 1 Node            | √            |        [see above]                                                                                                                                                       | If the node or AZ becomes unavailable check the Overview dashboard on the DB Console: If the down node is marked Suspect, try restarting the node. If the down node is marked Dead, decommission the node, wipe the store path, and then rejoin it back to the cluster. If the node has additional hardware issues, decommission the node and add a new node to the cluster. Ensure that locality flags are set correctly upon node startup. |
| 1 AZ              | √            |              [see above]                                                                               |                           [see above]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     | 
| 1 Region          | √            |             [see above]                                                                                                                                                  | Check the Overview dashboard on the DB Console. If nodes are marked Dead, decommission the nodes and add 3 new nodes in a new region. Ensure that locality flags are set correctly upon node startup.                                                                                                                                                                                                                                        |
| 2 or More Regions | X            | Cluster is unavailable.  Potential data loss between last backup and time of outage if the region and nodes did not come back online. | When the regions come back online, try restarting the nodes in the cluster.  If the regions do not come back online and nodes are lost or destroyed, try restoring the latest cluster backup into a new cluster.  You can also contact Cockroach Labs support for assistance.                                                                                                                                                                |                                                           |

The [automatic recovery / scaling](https://www.cockroachlabs.com/docs/v20.2/start-a-local-cluster.html#step-6-scale-the-cluster) sounds as easy as add a new node to the cluster. [Simulating node failures](https://www.cockroachlabs.com/docs/v20.2/start-a-local-cluster.html#step-5-simulate-node-failure) seems to be easy too.

### Summary
CockroachDB meets all set requirements. It supports [cluster functionalities](https://www.cockroachlabs.com/docs/v20.2/deploy-cockroachdb-on-premises-insecure), [automatic recovery functionalities](https://www.cockroachlabs.com/docs/v20.2/disaster-recovery.html), can produce measurable actions because it is a database, seems to be [easy to deploy](https://www.cockroachlabs.com/docs/v20.2/start-a-local-cluster-in-docker-linux), has a [good looking documentation](https://www.cockroachlabs.com/docs/v20.2) and because it has an [interface for an established SQL dialect PostgreSQL](https://www.cockroachlabs.com/docs/v20.2/postgresql-compatibility.html) there should be enough testing or benchmarking tools. Furthermore it is also able to meet our secondary requirements because it is easy to [down](https://www.cockroachlabs.com/docs/v20.2/remove-nodes.html) or [upscale](https://www.cockroachlabs.com/docs/v20.2/deploy-cockroachdb-on-premises.html#step-9-scale-the-cluster) and provide a [prometheus interface](https://www.cockroachlabs.com/docs/stable/monitor-cockroachdb-with-prometheus.html) we can include in our monitoring.




# Things to consider
* https://skupper.io/
* https://submariner.io/
* https://kubemq.io/