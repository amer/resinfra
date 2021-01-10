module "hetzner" {
  source       = "./modules/hetzner"
  hcloud_token = var.hcloud_token
}

module "azure" {
  source          = "./modules/azure"
  subscription_id = var.subscription_id
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
  location        = "eastus"
  cidr_block      = "10.1.0.0/16"
  vm_size         = "Standard_D2s_v3" # Standard_D2s_v3, Standard_B2s | For more info https://azureprice.net/
}