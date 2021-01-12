# Grafana auto provisioning
Grafana can be configured to be provisioned with data sources and dashboards at startup. 
The provisioning configuration is defined in the [privisioning folders](files/provisioning/). Datasources are provisioned directly from the configuration, whereas dashobards are only referenced in the config. The acutal dashboard json files are located in the [dashboards folder](files/dashboards/). More information on the configuration can be found [here](https://grafana.com/docs/grafana/latest/administration/provisioning/).

The provisioning files are copied to the remote host from the ansible role 
```
 - name: Copy over the Grafana provisioning files
    copy:
      src: files/provisioning
      dest: /services/Grafana/
    changed_when: false 
  
  - name: Copy over the Grafana dasboards
    copy:
      src: files/dashboards
      dest: /services/Grafana
    changed_when: false 
```

and then to the docker container.

```
volumes:
        - grafana_data:/var/lib/grafana
        - /services/Grafana/provisioning:/etc/grafana/provisioning/
        - /services/Grafana/dashboards:/etc/grafana/provisioned_dashbaords
```
They are picked up by Grafana automatically on startup. 

## Configuration
The grafana admin password is provisioned from the `grafana_admin_pw` variable.  Make sure to provision that from your ansible config yml or in 'vars' (in your playbook). See further configuration options from the set environment variables in the [template file](ansible/roles/grafana/templates/docker-compose.yml.j2).