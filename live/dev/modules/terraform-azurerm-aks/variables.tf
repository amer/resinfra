variable client_id {}
variable client_secret {}
variable subscription_id {}
variable tenant_id {}
variable prefix {}
variable location {}
variable cluster_name {}
variable dns_prefix {}
variable ssh_public_key {}
variable agent_count {}
variable log_analytics_workspace_name {}
variable cloudflare_email {}
variable cloudflare_api_token {}
variable cloudflare_zone_id {}
variable domain_name {}
variable vm_size {}
variable cidr_block {}

# Refer https://azure.microsoft.com/global-infrastructure/services/?products=monitor
# for log analytics available regions
variable log_analytics_workspace_location {
  default = "eastus"
}

# Refer https://azure.microsoft.com/pricing/details/monitor/ for log analytics pricing
variable log_analytics_workspace_sku {
  default = "PerGB2018"
}
