module "azure_aks_eastus" {
  source = "./modules/terraform-azurerm-aks"
  subscription_id               = var.subscription_id
  client_id                     = var.client_id
  client_secret                 = var.client_secret
  tenant_id                     = var.tenant_id
  prefix                        = "ri-eastus"
  location                      = "eastus"
  cluster_name                  = "ri-eastus-k8s-cluster"
  dns_prefix                    = "ri-eastus-k8s"
  ssh_public_key                = "~/.ssh/id_rsa.pub"
  log_analytics_workspace_name  = "ri-eastus-k8s-log-analytics-workspace"
  agent_count                   = 3
  virtual_network_address_space = ["10.1.0.0/16"]
  subnet_address_prefixes       = ["10.1.0.0/24"]
}

module "azure_aks_westus" {
  source = "./modules/terraform-azurerm-aks"
  subscription_id               = var.subscription_id
  client_id                     = var.client_id
  client_secret                 = var.client_secret
  tenant_id                     = var.tenant_id
  prefix                        = "ri-eastus2"
  location                      = "eastus2"
  cluster_name                  = "ri-eastus2-k8s-cluster"
  dns_prefix                    = "ri-eastus2-k8s"
  ssh_public_key                = "~/.ssh/id_rsa.pub"
  log_analytics_workspace_name  = "ri-eastus2-k8s-log-analytics-workspace"
  agent_count                   = 3
  virtual_network_address_space = ["10.2.0.0/16"]
  subnet_address_prefixes       = ["10.2.0.0/24"]
}

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
