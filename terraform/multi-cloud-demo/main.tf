module "hetzner" {
  source = "./modules/hetzner"
  hcloud_token = var.hcloud_token
}