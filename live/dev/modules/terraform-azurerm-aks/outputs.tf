output client_certificate {
  value = azurerm_kubernetes_cluster.main.kube_config.0.client_certificate
}

output kube_config {
  value = azurerm_kubernetes_cluster.main.kube_config_raw
}

output aks_location {
  value = azurerm_kubernetes_cluster.main.location
}

output cluster_name {
  value = azurerm_kubernetes_cluster.main.name
}

output cluster_fqdn {
  value = azurerm_kubernetes_cluster.main.fqdn
}

output cluster_cname {
  value = cloudflare_record.cluster_cname.name
}
