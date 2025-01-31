// Regex to extract IP because server.ipconfig1 looks like: "ip=92.204.185.34/29,gw=92.204.175.162"
output "proxmox_public_ips" {
  value = [for server in proxmox_vm_qemu.proxmox_vm : regex("\\b(?:[0-9]{1,3}\\.){3}[0-9]{1,3}\\b", server.ipconfig1)]
}

output "gateway_ipv4_address" {
  value = local.gateway_public_ipv4_address
}


output "gateway_private_ipv4_address" {
  value = local.gateway_private_ipv4_address
}

output "proxmox_private_ip_addresses"{
  value = [for server in proxmox_vm_qemu.proxmox_vm : regex("\\b(?:[0-9]{1,3}\\.){3}[0-9]{1,3}\\b", server.ipconfig0)]
}
