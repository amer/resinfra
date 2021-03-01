[cockroach_cluster_initializer]
${cockroach_cluster_initializer}

[cockroach_main_servers]
%{ for host in hetzner_hosts ~}
${host}
%{ endfor ~}

