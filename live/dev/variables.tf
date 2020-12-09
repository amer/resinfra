# terraform-azure-aks module
variable client_id {}
variable client_secret {}
variable subscription_id {}
variable tenant_id {}

# terraform-gcp-project module
variable gcp_project_id {}
variable gcp_region {}
variable gcp_organization_id {}
variable gke_num_nodes { default = 1 }