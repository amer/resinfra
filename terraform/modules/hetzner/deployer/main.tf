provider "hcloud" {
  token = var.hcloud_token
}

resource "random_id" "id" {
  byte_length = 4
}

data "hcloud_image" "deployer-snapshot" {
  with_selector = "hetzner-deployer"
  most_recent = true
}

resource "hcloud_ssh_key" "default" {
  name       = "${var.prefix}-hetzner-key-${random_id.id.hex}"
  public_key = file(var.path_public_key)
}

// initial deployer machine
resource "hcloud_server" "deployer" {
  name        = "${var.prefix}-hetzner-deployer-${random_id.id.hex}"
  image       = data.hcloud_image.deployer-snapshot.id
  server_type = "cpx31"
  ssh_keys = [hcloud_ssh_key.default.id]
  location    = var.location
}

# start terraform apply from here
