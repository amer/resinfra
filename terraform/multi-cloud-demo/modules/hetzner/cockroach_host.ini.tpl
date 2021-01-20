# file created dynamically during terraform apply
[cockroach_cluster_initializer]
${cockroach_cluster_initializer}

[cockroach_benchmark_server]
${hetzner_benchmark_host}

[cockroach_main_servers]
%{ for host in azure_hosts ~}
${host}
%{ endfor ~}
%{ for host in gcp_hosts ~}
${host}
%{ endfor ~}
%{ for host in hetzner_hosts ~}
${host}
%{ endfor ~}

[deployer_server]
${deployer_vm}

