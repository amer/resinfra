locals {
  path_public_key  = "~/.ssh/ri_key.pub"
}

module "hetzner-deployer" {
  source                       = "../modules/hetzner/deployer"
  hcloud_token                 = var.hcloud_token
  path_public_key = local.path_public_key
  prefix = var.prefix
}
