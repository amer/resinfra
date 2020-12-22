output "hcloud_public_ips" {
  value = {
    for server in hcloud_server.main :
    server.name => server.ipv4_address
  }
}
