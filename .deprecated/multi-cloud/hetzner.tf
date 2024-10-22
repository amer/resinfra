# Configure the Hetzner Cloud Provider
provider "hcloud" {
  token   = var.hcloud_token
}

resource "hcloud_ssh_key" "default" {
  name       = "${var.prefix}-hetzner-key-${random_id.id.hex}"
  public_key = file(var.public_key_path)
}

data "hcloud_image" "latest-debian" {
  name = "debian-10"
  most_recent = "true"
}

resource "hcloud_server" "main" {
  count       = var.instances
  name        = "${var.prefix}-vm-${count.index+1}-${random_id.id.hex}"
  image       = data.hcloud_image.latest-debian.name
  server_type = var.server_type
  location    = var.location
  ssh_keys    = [hcloud_ssh_key.default.id]
  user_data = data.template_file.user_data.rendered
}

resource "hcloud_floating_ip" "main" {
  count         = var.enable_floating_ip ? var.instances : 0
  name          = "${var.prefix}-floating_ip-${count.index+1}-${random_id.id.hex}"
  type          = "ipv4"
  home_location = var.location
  server_id     = hcloud_server.main.*.id[count.index]
}

resource "hcloud_volume" "main" {
  count         = var.enable_volume ? var.instances : 0
  name          = "${var.prefix}-volume-${count.index+1}-${random_id.id.hex}"
  size          = var.volume_size
  server_id     = hcloud_server.main.*.id[count.index]
  automount     = "true"
  format = "xfs"
}

output "hcloud_public_ips" {
  value = {
    for server in hcloud_server.main :
    server.name => server.ipv4_address
  }
}
