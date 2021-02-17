[cockroach_cluster_initializer]
${cockroach_cluster_initializer}

[cockroach_main_servers]
%{ for host in hetzner_hosts ~}
${host}
%{ endfor ~}
%{ for host in azure_hosts ~}
${host}
%{ endfor ~}
%{ for host in gcp_hosts ~}
${host}
%{ endfor ~}
%{ for host in proxmox_hosts ~}
${host}
%{ endfor ~}
