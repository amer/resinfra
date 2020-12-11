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
  virtual_network_address_space = ["10.1.0.0/16"]
  subnet_address_prefixes       = ["10.1.0.0/24"]
}

//module "azure_aks_siteB" {
//  source = "./modules/terraform-azurerm-aks"
//  subscription_id               = var.subscription_id
//  client_id                     = var.client_id
//  client_secret                 = var.client_secret
//  tenant_id                     = var.tenant_id
//  location                      = local.siteB.region
//  prefix                        = "${local.project_name}-${local.siteB.region}"
//  cluster_name                  = "${local.project_name}-k8s-cluster-${local.siteB.region}"
//  dns_prefix                    = "${local.project_name}-k8s-${local.siteB.region}"
//  ssh_public_key                = "~/.ssh/id_rsa.pub"
//  log_analytics_workspace_name  = "${local.project_name}-k8s-log-analytics-workspace-${local.siteB.region}"
//  agent_count                   = 2
//  virtual_network_address_space = ["10.2.0.0/16"]
//  subnet_address_prefixes       = ["10.2.0.0/24"]
//}

//module "gcp_project" {
//  source = "./modules/terraform-gcp-project"
//  project_id = var.gcp_project_id
//  region =  var.gcp_region
//  organization_id = var.gcp_organization_id
//}
//
//module "gcp-vpc" {
//  source = "./modules/terraform-gcp-vpc"
//  project_id = var.gcp_project_id
//  region =  var.gcp_region
//  depends_on = [module.gcp_project]
//}

//
//resource "helm_release" "consul" {
//  timeout   = "600"
//  name      = "consul"
//  namespace = "default"
//  chart     = "https://github.com/hashicorp/consul-helm/archive/v0.27.0.tar.gz"
//
//  set {
//    name  = "connectInject.enabled"
//    value = "true"
//  }
//  set {
//    name  = "global.datacenter"
//    value = "tf-k8s-az-1"
//  }
//  set {
//    name  = "client.enabled"
//    value = "true"
//  }
//  set {
//    name  = "client.grpc"
//    value = "true"
//  }
//  set {
//    name  = "syncCatalog.enabled"
//    value = "true"
//  }
//}
