output "azure_aks_siteA_cluster_fqdn" {
  value = module.azure_aks_siteA.cluster_fqdn
}

output "siteA_cluster_cname" {
  value = module.azure_aks_siteA.cluster_cname
}

output "siteA_cluster_resource_group" {
  value = module.azure_aks_siteA.resource_group
}

output "siteA_name" {
  value = module.azure_aks_siteA.name
}

//------------------

output "azure_aks_siteB_cluster_fqdn" {
  value = module.azure_aks_siteB.cluster_fqdn
}

output "siteB_cluster_cname" {
  value = module.azure_aks_siteB.cluster_cname
}

output "siteB_cluster_resource_group" {
  value = module.azure_aks_siteB.resource_group
}

output "siteB_name" {
  value = module.azure_aks_siteB.name
}

//output "kube_config" {
//  value = module.azure_aks_siteA.kube_config
//}

