output "hcloud_public_ips" {
  value = {
    for server in hcloud_server.main :
    server.name => server.ipv4_address
  }
}

output "gateway_ipv4_address" {
  value = hcloud_server.gateway.ipv4_address
}

output "hcloud_private_ip_addresses"{
  value = hcloud_server_network.normal-vms-into-subnet.*.ip
}