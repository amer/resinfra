# Configure the Hetzner Cloud Provider
provider "hcloud" {
  token   = var.hcloud_token
}

resource "hcloud_ssh_key" "default" {
  name       = "hetzner_key"
  public_key = file(var.pub_ssh_path)
}

resource "hcloud_server" "vm" {
  count       = var.instances
  name        = "vm-${count.index+1}"
  image       = var.os_type
  server_type = var.server_type
  location    = var.location
  ssh_keys    = [hcloud_ssh_key.default.id]
  labels = {
    type = "vm"
  }
}

output "vm_status" {
  value = {
    for server in hcloud_server.vm :
    server.name => server.status
  }
}

output "vm_ipds" {
  value = {
    for server in hcloud_server.vm :
    server.name => server.ipv4_address
  }
}
