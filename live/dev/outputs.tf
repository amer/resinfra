output "azure_aks_siteA_cluster_fqdn" {
  value = module.azure_aks_siteA.cluster_fqdn
}

output "siteA_cluster_cname" {
  value = module.azure_aks_siteA.cluster_cname
}

output "azure_aks_siteB_cluster_fqdn" {
  value = module.azure_aks_siteB.cluster_fqdn
}

output "siteB_cluster_cname" {
  value = module.azure_aks_siteB.cluster_cname
}

//output "kube_config" {
//  value = module.azure_aks_siteA.kube_config
//}

