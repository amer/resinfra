output "tooling_vm_public_ip" {
  value = hcloud_server.cockroach_deployer.ipv4_address
}

output "tooling_vm_internal_ip" {
  value = hcloud_server_network.deployment-vm-into-subnet.ip
}
