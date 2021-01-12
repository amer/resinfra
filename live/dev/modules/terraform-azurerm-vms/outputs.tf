output "bastion_public_ip_address" {
  value = azurerm_public_ip.bastion.*.ip_address
}

output "public_subnet_private_ip_addresses" {
  value = flatten(azurerm_linux_virtual_machine.bastion.*.private_ip_addresses)
}

output "internal_subnet_private_ip_addresses" {
  value = flatten(azurerm_linux_virtual_machine.worker-nodes.*.private_ip_addresses)
}

