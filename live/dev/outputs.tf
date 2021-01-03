#### SiteA

output azure_aks_siteA_cluster_fqdn {
  value = module.azure_aks_siteA.cluster_fqdn
}

output siteA_cluster_cname {
  value = module.azure_aks_siteA.cluster_cname
}

output siteA_cluster_resource_group {
  value = module.azure_aks_siteA.resource_group
}

output siteA_name {
  value = module.azure_aks_siteA.name
}

output siteA_aks_generated_rg_name {
  value = module.azure_aks_siteA.aks_generated_rg_name
}


output siteA_public_pool_network_security_group_name {
  value = module.azure_aks_siteA.public_pool_network_security_group_name
}

#### SiteB

output azure_aks_siteB_cluster_fqdn {
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

output siteB_aks_generated_rg_name {
  value = module.azure_aks_siteB.aks_generated_rg_name
}

output siteB_public_pool_network_security_group_name {
  value = module.azure_aks_siteB.public_pool_network_security_group_name
}


