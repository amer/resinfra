output "hetzner" {
  value = module.hetzner
}

output "azure" {
  value = module.azure.azure_public_ip
}