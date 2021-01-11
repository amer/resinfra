output "azure_public_ip" {
  value = azurerm_public_ip.main.*.ip_address
}

output "azure_gateway_ipv4_address" {
  value = azurerm_public_ip.gateway.ip_address
}

output "azure_private_ip_addresses" {
  value = azurerm_linux_virtual_machine.main.*.private_ip_address
}