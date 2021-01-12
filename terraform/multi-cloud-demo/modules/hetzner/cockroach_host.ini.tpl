[cockroach_cluster_initializer]
${cockroach_cluster_initializer}

[cockroach_main_servers_azure]
%{ for host in azure_hosts ~}
${host}
%{ endfor ~}

[cockroach_main_servers_gcp]
%{ for host in gcp_hosts ~}
${host}
%{ endfor ~}

[cockroach_main_servers_hetzner]
%{ for host in hetzner_hosts ~}
${host}
%{ endfor ~}
