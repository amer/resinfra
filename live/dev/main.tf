locals {
  project_name = "ri"
  siteA = {
    region = "eastus"
    service_cidr = "10.1.0.0/16"
    dns_service_ip = "10.1.0.10"
    domain_name = "a.infra.ci"
  }
  siteB = {
    region = "eastus2"
    service_cidr = "10.2.0.0/16"
    dns_service_ip = "10.2.0.10"
    domain_name = "b.infra.ci"
  }
}

module "azure_aks_siteA" {
  source                       = "modules/terraform-azurerm-aks"
  subscription_id              = var.subscription_id
  client_id                    = var.client_id
  client_secret                = var.client_secret
  tenant_id                    = var.tenant_id
  location                     = local.siteA.region
  cloudflare_email             = var.cloudflare_email
  cloudflare_api_token         = var.cloudflare_api_token
  cloudflare_zone_id           = var.cloudflare_zone_id
  prefix                       = "${local.project_name}-${local.siteA.region}"
  cluster_name                 = "${local.project_name}-k8s-cluster-${local.siteA.region}"
  dns_prefix                   = "${local.project_name}-k8s-${local.siteA.region}"
  ssh_public_key               = "~/.ssh/id_rsa.pub"
  log_analytics_workspace_name = "${local.project_name}-k8s-log-analytics-workspace-${local.siteA.region}"
  agent_count                  = 2
  service_cidr                 = local.siteA.service_cidr
  dns_service_ip               = local.siteA.dns_service_ip
  domain_name                  = local.siteA.domain_name
  vm_size                      = "Standard_B2s" # Standard_D2s_v3, Standard_B2s | For more info https://azureprice.net/
}

module "azure_aks_siteB" {
  source                       = "modules/terraform-azurerm-aks"
  subscription_id              = var.subscription_id
  client_id                    = var.client_id
  client_secret                = var.client_secret
  tenant_id                    = var.tenant_id
  location                     = local.siteB.region
  cloudflare_email             = var.cloudflare_email
  cloudflare_api_token         = var.cloudflare_api_token
  cloudflare_zone_id           = var.cloudflare_zone_id
  prefix                       = "${local.project_name}-${local.siteB.region}"
  cluster_name                 = "${local.project_name}-k8s-cluster-${local.siteB.region}"
  dns_prefix                   = "${local.project_name}-k8s-${local.siteB.region}"
  ssh_public_key               = "~/.ssh/id_rsa.pub"
  log_analytics_workspace_name = "${local.project_name}-k8s-log-analytics-workspace-${local.siteB.region}"
  agent_count                  = 2
  service_cidr                 = local.siteB.service_cidr
  dns_service_ip               = local.siteB.dns_service_ip
  domain_name                  = local.siteB.domain_name
  vm_size                      = "Standard_B2s" # Standard_D2s_v3, Standard_B2s | For more info https://azureprice.net/
}