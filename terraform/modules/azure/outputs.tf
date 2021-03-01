output "azure_gateway_ipv4_address" {
  value = azurerm_public_ip.gateway.ip_address
}

output "azure_private_ip_addresses" {
  value = azurerm_linux_virtual_machine.worker_vm.*.private_ip_address
}