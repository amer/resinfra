locals {
  project_name = "ri"
  siteA = {
    cluster_name = "ca"
    region       = "westeurope"
    cidr_block   = "10.1.0.0/16" # cidrsubnet("10.1.0.0/16", 4,1) => "10.1.16.0/20", 4096 Addresses
    domain_name  = "a.infra.ci"
  }
  siteB = {
    cluster_name = "cb"
    region       = "eastus"
    cidr_block   = "10.2.0.0/16" # cidrsubnet("10.2.0.0/16", 4,1) => "10.2.16.0/20", 4096 Addresses
    domain_name  = "b.infra.ci"
  }
}

module "azure_aks_siteA" {
  source                       = "./modules/terraform-azurerm-aks"
  subscription_id              = var.subscription_id
  client_id                    = var.client_id
  client_secret                = var.client_secret
  tenant_id                    = var.tenant_id
  location                     = local.siteA.region
  cloudflare_email             = var.cloudflare_email
  cloudflare_api_token         = var.cloudflare_api_token
  cloudflare_zone_id           = var.cloudflare_zone_id
  prefix                       = "${local.project_name}-${local.siteA.region}"
  cluster_name                 = local.siteA.cluster_name
  dns_prefix                   = "${local.project_name}-k8s-${local.siteA.region}"
  ssh_public_key               = "~/.ssh/id_rsa.pub"
  log_analytics_workspace_name = "${local.project_name}-k8s-log-analytics-workspace-${local.siteA.region}"
  agent_count                  = 2
  cidr_block                   = local.siteA.cidr_block
  domain_name                  = local.siteA.domain_name
  vm_size                      = "Standard_D2s_v3" # Standard_D2s_v3, Standard_B2s | For more info https://azureprice.net/
}

module "azure_aks_siteB" {
  source                       = "./modules/terraform-azurerm-aks"
  subscription_id              = var.subscription_id
  client_id                    = var.client_id
  client_secret                = var.client_secret
  tenant_id                    = var.tenant_id
  location                     = local.siteB.region
  cloudflare_email             = var.cloudflare_email
  cloudflare_api_token         = var.cloudflare_api_token
  cloudflare_zone_id           = var.cloudflare_zone_id
  prefix                       = "${local.project_name}-${local.siteB.region}"
  cluster_name                 = local.siteB.cluster_name
  dns_prefix                   = "${local.project_name}-k8s-${local.siteB.region}"
  ssh_public_key               = "~/.ssh/id_rsa.pub"
  log_analytics_workspace_name = "${local.project_name}-k8s-log-analytics-workspace-${local.siteB.region}"
  agent_count                  = 2
  cidr_block                   = local.siteB.cidr_block
  domain_name                  = local.siteB.domain_name
  vm_size                      = "Standard_D2s_v3" # Standard_D2s_v3, Standard_B2s | For more info https://azureprice.net/
}
