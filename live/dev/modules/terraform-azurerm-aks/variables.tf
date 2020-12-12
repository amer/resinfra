variable client_id {}
variable client_secret {}
variable subscription_id {}
variable tenant_id {}
variable "prefix" {}
variable location {}
variable cluster_name {}
variable "dns_prefix" {}
variable "ssh_public_key" {}
variable "agent_count" {}
variable log_analytics_workspace_name {}
variable service_cidr {}
variable dns_service_ip {}

# Refer https://azure.microsoft.com/global-infrastructure/services/?products=monitor
# for log analytics available regions
variable log_analytics_workspace_location {
  default = "eastus"
}



# Refer https://azure.microsoft.com/pricing/details/monitor/ for log analytics pricing
variable log_analytics_workspace_sku {
  default = "PerGB2018"
}
