# Monitoring with Prometheus
The following guide demonstrates how to setup Prometheus and Grafana to monitor a virtual machine.

We will use the Prometheus Node Exporter to extract the metrics from the virtual machine (see: https://prometheus.io/docs/guides/node-exporter/).

*Caveats*:
Prometheus Node Exporter only support *nix systems. But there is a community project, which develops a exporter for windows systems: https://github.com/prometheus-community/windows_exporter.

## Add Node Exporter to a virtual machine
- Download Node Exporter from here: https://prometheus.io/download/#node_exporter
- Extract, move the folder to your target machine, open the folder and type the following command in order to start Node Exporter (detailed: https://prometheus.io/docs/guides/node-exporter/):

```
$ ./node_exporter
```

Node Exporter will now export the metrics of the host on port 9100. You can verify that the exporter is running, by issuing the following command:

```
$ curl http://localhost:9100/metrics
```

## Install and configure Prometheus
- Download Prometheus from here: https://prometheus.io/download
- Extract the downloaded archive
- Open the extracted folder and replace the content of the file 'prometheus.yml' with the following:

```
global:
  scrape_interval: 15s

scrape_configs:
- job_name: node
  static_configs:
  - targets: ['localhost:9100']
```

- After that you can start Prometheus from the same folder with the following command:

```
$ ./prometheus
```  
Now Prometheus should be up and running on port 9090. You can explore the metrics in your browser by visiting the page: http://localhost:9090/graph.    

## Install and configure Grafana
- Follow the guide to install Grafana on your PC: https://grafana.com/docs/grafana/latest/installation/.
- Click on Configuration on the left sidebar and click Data sources. Then add Prometheus (example URL: localhost:9090) as your data source.
- Click on Create on the left sidebar and click Import. Then type the number 1860 into the input field (Import via grafana.com) and click Load to load the following dashboard: https://grafana.com/grafana/dashboards/1860.

Now you should have a dashboard with all available metrics like this:

![alt text](https://grafana.com/api/dashboards/1860/images/7994/image)

The most important metrics for our project are:
- Sys load 5 min average (Busy state of all CPU cores together)
- Memory usage (RAM used)
- Network Traffic by Packets
- Network Traffic Errors
- Disk Space Used

Happy monitoring!
