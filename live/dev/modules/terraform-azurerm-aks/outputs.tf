//output "client_certificate" {
//  value = azurerm_kubernetes_cluster.main.kube_config.0.client_certificate
//}

//output "kube_config" {
//  value = azurerm_kubernetes_cluster.main.kube_config_raw
//}

output "aks_location" {
  value = azurerm_kubernetes_cluster.main.location
}

output "cluster_name" {
  value = azurerm_kubernetes_cluster.main.name
}

output "cluster_fqdn" {
  value = azurerm_kubernetes_cluster.main.fqdn
}

output "cluster_cname" {
  value = cloudflare_record.cluster_cname.name
}

output "resource_group" {
  value = azurerm_kubernetes_cluster.main.resource_group_name
}

output "aks_generated_resource_group_name" {
  value = local.aks_generated_rg
}

output "public_pool_network_security_group_name" {
  value = local.aks_nsg_name
}

output "public_get_virtual_machine_scale_set_name" {
  value = local.aks_vmss_name
}

output "public_node_ips" {
  value = local.public_node_ips
}

output "public_nodes_fqdn" {
  value = cloudflare_record.public_nodes.0.name
}