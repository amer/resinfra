locals {
  azure_vpc_cidr_block = "10.1.0.0/16"
  hetzner_vpc_cidr_block = "10.2.0.0/16"
}

module "hetzner" {
  source               = "./modules/hetzner"
  hcloud_token         = var.hcloud_token
  cidr_block           = local.hetzner_vpc_cidr_block
  azure_vpc_cidr_block = local.azure_vpc_cidr_block
  azurerm_public_ip    = "1.2.3.4" # TODO get the public ip of Azure VPN gateway
  shared_key           = var.shared_key
}

module "azure" {
  source          = "./modules/azure"
  subscription_id = var.subscription_id
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
  location        = "eastus"
  cidr_block      = local.azure_vpc_cidr_block
  vm_size         = "Standard_D2s_v3" # Standard_D2s_v3, Standard_B2s | For more info https://azureprice.net/
}
