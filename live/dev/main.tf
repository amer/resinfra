locals {
  project_name = "ri"
  siteA = {
    region = "eastus"
  }
  siteB = {
    region = "eastus2"
  }
}

module "azure_aks_siteA" {
  source = "./modules/terraform-azurerm-aks"
  subscription_id               = var.subscription_id
  client_id                     = var.client_id
  client_secret                 = var.client_secret
  tenant_id                     = var.tenant_id
  location                      = local.siteA.region
  prefix                        = "${local.project_name}-${local.siteA.region}"
  cluster_name                  = "${local.project_name}-k8s-cluster-${local.siteA.region}"
  dns_prefix                    = "${local.project_name}-k8s-${local.siteA.region}"
  ssh_public_key                = "~/.ssh/id_rsa.pub"
  log_analytics_workspace_name  = "${local.project_name}-k8s-log-analytics-workspace-${local.siteA.region}"
  agent_count                   = 2
  service_cidr                  = "10.0.0.0/16"
  dns_service_ip                = "10.0.0.10"
}