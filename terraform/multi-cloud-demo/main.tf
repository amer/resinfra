locals {
  azure_cidr                = cidrsubnet(var.vpc_cidr, 8, 1)    # 10.1.0.0/16 (Azure does not allow to add overlapping subnets when creating vpn routes)
  azure_vm_subnet_cidr      = cidrsubnet(var.vpc_cidr, 16, 256) # 10.1.0.0/24
  azure_gateway_subnet_cidr = cidrsubnet(var.vpc_cidr, 16, 257) # 10.1.1.0/24

  gcp_cidr           = cidrsubnet(var.vpc_cidr, 8, 2)    # 10.2.0.0/16
  gcp_vm_subnet_cidr = cidrsubnet(var.vpc_cidr, 16, 512) # 10.2.0.0/24

  hetzner_cidr           = var.vpc_cidr    # 10.0.0.0/8 (Hetzner needs to have all subnets included in the big VPN)
  hetzner_vm_subnet_cidr = cidrsubnet(var.vpc_cidr, 16, 768) # 10.3.0.0/24

  path_private_key = "~/.ssh/ri_key"
  path_public_key  = "~/.ssh/ri_key.pub"
}

module "hetzner" {
  source                     = "./modules/hetzner"
  hcloud_token               = var.hcloud_token
  shared_key                 = var.shared_key
  path_private_key           = local.path_private_key
  path_public_key            = local.path_public_key
  azure_vm_subnet_cidr       = local.azure_vm_subnet_cidr
  gcp_gateway_ipv4_address   = module.gcp.gcp_gateway_ipv4_address
  azure_gateway_ipv4_address = module.azure.azure_gateway_ipv4_address
  gcp_vm_subnet_cidr         = local.gcp_vm_subnet_cidr
  hetzner_vm_subnet_cidr     = local.hetzner_vm_subnet_cidr
  hetzner_vpc_cidr           = local.hetzner_cidr
  prefix                     = var.prefix
  instances                  = var.instances
}

module "azure" {
  source                      = "./modules/azure"
  subscription_id             = var.subscription_id
  client_id                   = var.client_id
  client_secret               = var.client_secret
  tenant_id                   = var.tenant_id
  location                    = "eastus"
  vm_size                     = "Standard_D2s_v3" # Standard_D2s_v3, Standard_B2s | For more info https://azureprice.net/
  path_private_key            = local.path_private_key
  path_public_key             = local.path_public_key
  azure_gateway_subnet_cidr   = local.azure_gateway_subnet_cidr
  azure_vm_subnet_cidr        = local.azure_vm_subnet_cidr
  azure_vpc_cidr              = local.azure_cidr
  gcp_gateway_ipv4_address    = module.gcp.gcp_gateway_ipv4_address
  gcp_vm_subnet_cidr          = local.gcp_vm_subnet_cidr
  hcloud_gateway_ipv4_address = module.hetzner.gateway_ipv4_address
  hcloud_vm_subnet_cidr       = local.hetzner_vm_subnet_cidr
  shared_key                  = var.shared_key
  prefix                      = var.prefix
  instances                   = var.instances
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
  path_public_key              = local.path_public_key
  instances                    = var.instances
}


