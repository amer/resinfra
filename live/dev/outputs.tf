output "azure_aks_siteA_cluster_fqdn" {
  value = module.azure_aks_siteA.cluster_fqdn
}

output "azure_aks_siteB_cluster_fqdn" {
  value = module.azure_aks_siteB.cluster_fqdn
}

//output "kube_config" {
//  value = module.azure_aks_siteA.kube_config
//}

