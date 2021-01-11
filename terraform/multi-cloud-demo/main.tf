locals {
  azure_vm_subnet_cidr      = cidrsubnet(var.vpc_cidr, 8, 1)
  gcp_vm_subnet_cidr        = cidrsubnet(var.vpc_cidr, 8, 2)
  hetzner_vm_subnet_cidr    = cidrsubnet(var.vpc_cidr, 8, 3)
  azure_gateway_subnet_cidr = cidrsubnet(var.vpc_cidr, 8, 4)

  path_private_key = "~/.ssh/ri_key"
  path_public_key  = "~/.ssh/ri_key.pub"
}

module "hetzner" {
  source                     = "./modules/hetzner"
  hcloud_token               = var.hcloud_token
  shared_key                 = var.shared_key
  path_private_key           = local.path_private_key
  path_public_key            = local.path_public_key
  azure_vm_subnet_cidr       = local.azure_gateway_subnet_cidr
  gcp_gateway_ipv4_address   = module.gcp.gcp_gateway_ipv4_address
  azure_gateway_ipv4_address = module.azure.azure_gateway_ipv4_address
  gcp_vm_subnet_cidr         = local.gcp_vm_subnet_cidr
  hetzner_vm_subnet_cidr     = local.hetzner_vm_subnet_cidr
  hetzner_vpc_cidr           = var.vpc_cidr
  prefix                     = var.prefix
}

module "azure" {
  source          = "./modules/azure"
  subscription_id = var.subscription_id
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
  location        = "eastus"
  vm_size         = "Standard_D2s_v3"
  # Standard_D2s_v3, Standard_B2s | For more info https://azureprice.net/
  path_private_key            = local.path_private_key
  path_public_key             = local.path_public_key
  azure_gateway_subnet_cidr   = local.azure_gateway_subnet_cidr
  azure_vm_subnet_cidr        = local.azure_vm_subnet_cidr
  azure_vpc_cidr              = var.vpc_cidr
  gcp_gateway_ipv4_address    = module.gcp.gcp_gateway_ipv4_address
  gcp_vm_subnet_cidr          = local.gcp_vm_subnet_cidr
  hcloud_gateway_ipv4_address = module.hetzner.gateway_ipv4_address
  hcloud_vm_subnet_cidr       = local.hetzner_vm_subnet_cidr
  shared_key                  = var.shared_key
  prefix                      = var.prefix
}

module "gcp" {
  source                       = "./modules/gcp"
  azure_gateway_ipv4_address   = module.azure.azure_gateway_ipv4_address
  azure_subnet_cidr            = local.azure_vm_subnet_cidr
  gcp_project_id               = var.gcp_project_id
  gcp_region                   = var.gcp_region
  gcp_service_account_path     = var.gcp_service_account_path
  gcp_subnet_cidr              = local.gcp_vm_subnet_cidr
  hetzner_gateway_ipv4_address = module.hetzner.gateway_ipv4_address
  hetzner_subnet_cidr          = local.hetzner_vm_subnet_cidr
  prefix                       = var.prefix
  shared_key                   = var.shared_key
}


