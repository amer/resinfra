# Configure the Hetzner Cloud Provider
provider "hcloud" {
  token   = var.hcloud_token
}

resource "hcloud_ssh_key" "default" {
  name       = "hetzner_key_standalone"
  public_key = file(var.pub_ssh_path)
}

resource "hcloud_server" "main" {
  count       = var.instances
  name        = "vm-standalone-${count.index+1}"
  image       = var.os_type
  server_type = var.server_type
  location    = var.location
  ssh_keys    = [hcloud_ssh_key.default.id]
}

resource "hcloud_floating_ip" "main" {
  count         = var.enable_floating_ip ? var.instances : 0
  name          = "floating_ip-standalone-${count.index+1}"
  type          = "ipv4"
  home_location = var.location
  server_id     = hcloud_server.main.*.id[count.index]
}

resource "hcloud_volume" "main" {
  count         = var.enable_volume ? var.instances : 0
  name          = "volume-standalone-${count.index+1}"
  size          = var.volume_size
  server_id     = hcloud_server.main.*.id[count.index]
  automount     = "true"
  format = "xfs"
}

output "vm_ids" {
  value = {
    for server in hcloud_server.main :
    server.name => server.id
  }
}

output "vm_ips" {
  value = {
    for server in hcloud_server.main :
    server.name => server.ipv4_address
  }
}

output "floating_ips" {
  value = {
    for ip in hcloud_floating_ip.main :
    ip.name => ip.ip_address
  }
}

output "floating_ip_mapping" {
  value = {
    for ip in hcloud_floating_ip.main :
    ip.name => ip.server_id
  }
}

output "volumes_device_paths" {
  value = {
    for vol in hcloud_volume.main :
    vol.name => vol.linux_device
  }
}
