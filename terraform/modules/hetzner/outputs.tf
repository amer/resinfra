output "hcloud_public_ips" {
  value = {
    for server in hcloud_server.worker-vm :
      server.name => server.ipv4_address
  }
}

output "gateway_ipv4_address" {
  value = hcloud_server.gateway.ipv4_address
}

output "hcloud_private_ip_addresses"{
  value = hcloud_server_network.worker-vm.*.ip
}

output "hcloud_subnet_id" {
  value = hcloud_network_subnet.main.id
}

output "hcloud_deployer_public_ip" {
  value = hcloud_server.deployer.ipv4_address
}
