locals {
  hetzner_vpc_cidr    = "10.0.0.0/12"
  hetzner_subnet_cidr = "10.0.1.0/24"

  azure_vpc_cidr            = "10.1.0.0/16"
  azure_vm_subnet_cidr      = "10.1.1.0/24"
  azure_gateway_subnet_cidr = "10.1.2.0/24"

  path_private_key = "C:\\Users\\Roschy\\.ssh\\adsp_key"
  path_public_key  = "C:\\Users\\Roschy\\.ssh\\adsp_key.pub"
}

module "hetzner" {
  source                     = "./modules/hetzner"
  hcloud_token               = var.hcloud_token
  cidr_block                 = local.hetzner_vpc_cidr
  azure_vpc_cidr_block       = local.azure_vpc_cidr
  azure_gateway_ipv4_address = module.azure.azure_gateway_ipv4_address
  shared_key                 = var.shared_key
  path_private_key           = local.path_private_key
  path_public_key            = local.path_public_key
}

module "azure" {
  source                      = "./modules/azure"
  subscription_id             = var.subscription_id
  client_id                   = var.client_id
  client_secret               = var.client_secret
  tenant_id                   = var.tenant_id
  location                    = "eastus"
  cidr_block                  = local.azure_vpc_cidr
  vm_size                     = "Standard_D2s_v3" # Standard_D2s_v3, Standard_B2s | For more info https://azureprice.net/
  hcloud_gateway_ipv4_address = module.hetzner.gateway_ipv4_address
  hcloud_subnet_cidr          = local.hetzner_subnet_cidr
  azure_gateway_subnet_cidr   = local.azure_gateway_subnet_cidr
  azure_vm_subnet_cidr        = local.azure_vm_subnet_cidr
  azure_vpc_cidr              = local.azure_vpc_cidr
  shared_key                  = var.shared_key
  path_private_key            = local.path_private_key
  path_public_key             = local.path_public_key
}

