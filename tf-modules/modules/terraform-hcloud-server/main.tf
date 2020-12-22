resource "hcloud_ssh_key" "default" {
  name       = "${var.prefix}-hetzner-key-${var.random_id}"
  public_key = file(var.public_key_path)
}

data "hcloud_image" "latest-debian" {
  name = "debian-10"
  most_recent = "true"
}

resource "hcloud_server" "main" {
  count       = var.instances
  name        = "${var.prefix}-vm-${count.index+1}-${var.random_id}"
  image       = data.hcloud_image.latest-debian.name
  server_type = var.server_type
  location    = var.location
  ssh_keys    = [hcloud_ssh_key.default.id]
  user_data = var.user_data
}

resource "hcloud_floating_ip" "main" {
  count         = var.enable_floating_ip ? var.instances : 0
  name          = "${var.prefix}-floating_ip-${count.index+1}-${var.random_id}"
  type          = "ipv4"
  home_location = var.location
  server_id     = hcloud_server.main.*.id[count.index]
}

resource "hcloud_volume" "main" {
  count         = var.enable_volume ? var.instances : 0
  name          = "${var.prefix}-volume-${count.index+1}-${var.random_id}"
  size          = var.volume_size
  server_id     = hcloud_server.main.*.id[count.index]
  automount     = "true"
  format = "xfs"
}
