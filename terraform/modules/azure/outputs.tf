output "azure_gateway_ipv4_address" {
  value = azurerm_public_ip.gateway[0].ip_address
}

output "azure_ha_gateway_ipv4_addresses" {
  value = azurerm_public_ip.gateway.*.ip_address
}

output "azure_private_ip_addresses" {
  value = azurerm_linux_virtual_machine.worker_vm.*.private_ip_address
}

output "public_ip_addresses" {
  value = [for ip_config in azurerm_public_ip.worker_vm : ip_config.ip_address]
}
