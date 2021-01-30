# Configure the Hetzner Cloud Provider
provider "hcloud" {
  token = var.hcloud_token
}

resource "random_id" "id" {
  byte_length = 4
}

resource "hcloud_ssh_key" "default" {
  name       = "${var.prefix}-hetzner-key-${random_id.id.hex}"
  public_key = file(var.path_public_key)
}

data "hcloud_image" "latest-debian" {
  name        = "debian-10"
  most_recent = "true"
}

data "template_file" "user_data" {
  template = file("${path.module}/preconf.yml")

  vars = {
    username   = "resinfra"
    public_key = file(var.path_public_key)
  }
}

/*
------------------------
    INTERNAL NETWORK
------------------------
*/

# Create a virtual network
resource "hcloud_network" "main" {
  name     = "${var.prefix}-network-${random_id.id.hex}"
  ip_range = var.hetzner_vpc_cidr
}

# Create a subnet for both the gateway and the vms
resource "hcloud_network_subnet" "main" {
  network_id   = hcloud_network.main.id
  type         = "cloud"
  network_zone = "eu-central"
  ip_range     = var.hetzner_vm_subnet_cidr
}

/*
----------------------------
    EXTERNAL NETWORK
----------------------------
*/

# Create VM that will be the gateway
resource "hcloud_server" "gateway" {
  name        = "${var.prefix}-hetzner-gateway-vm-${random_id.id.hex}"
  image       = "ubuntu-20.04"
  server_type = "cx11"
  location    = "nbg1"
  ssh_keys = [
  hcloud_ssh_key.default.id]
}

# Put the Gateway VM into the subnet and run ansible to configure it
resource "hcloud_server_network" "internal" {
  server_id = hcloud_server.gateway.id
  subnet_id = hcloud_network_subnet.main.id
}

resource "null_resource" "strongswan_ansible" {
  provisioner "remote-exec" {
    inline = ["echo 'SSH is now ready!'"]

    connection {
      type        = "ssh"
      user        = "root"
      private_key = file(var.path_private_key)
      host        = hcloud_server.gateway.ipv4_address
    }
  }

  provisioner "local-exec" {
    command = <<EOF
        ansible-playbook -i '${hcloud_server.gateway.ipv4_address},'  \
            -u 'root' ${abspath(path.module)}/../../../ansible/strongswan_playbook.yml \
            --ssh-common-args='-o StrictHostKeyChecking=no' \
            --extra-vars 'public_gateway_ip='${hcloud_server.gateway.ipv4_address}' \
                          local_cidr='${var.hetzner_vm_subnet_cidr}' \
                          azure_remote_gateway_ip='${var.azure_gateway_ipv4_address}' \
                          azure_remote_cidr='${var.azure_vm_subnet_cidr}'
                          gcp_remote_gateway_ip='${var.gcp_gateway_ipv4_address}' \
                          gcp_remote_cidr='${var.gcp_vm_subnet_cidr}' \
                          other_strongswan_gateway_ip=${var.proxmox_gateway_ipv4_address} \
                          other_strongswan_remote_cidr=${var.proxmox_vm_subnet_cidr} \
                          psk='${var.shared_key}'' \
            --key-file '${var.path_private_key}'
  EOF
  }
}

# create a route in the Hetzner Network for Azure, GCP, and Proxmox traffic

resource "hcloud_network_route" "azure_via_gateway" {
  network_id  = hcloud_network.main.id
  destination = var.azure_vm_subnet_cidr
  gateway     = hcloud_server_network.internal.ip
}

resource "hcloud_network_route" "gcp_via_gateway" {
  network_id  = hcloud_network.main.id
  destination = var.gcp_vm_subnet_cidr
  gateway     = hcloud_server_network.internal.ip
}

resource "hcloud_network_route" "proxmox_via_gateway" {
  network_id  = hcloud_network.main.id
  destination = var.proxmox_vm_subnet_cidr
  gateway     = hcloud_server_network.internal.ip
}

/*
-------------------------------
   WORKER VM(s)
-------------------------------
*/

resource "hcloud_server" "worker-vm" {
  count       = var.instances
  name        = "${var.prefix}-hetzner-vm-${count.index + 1}-${random_id.id.hex}"
  image       = data.hcloud_image.latest-debian.name
  server_type = var.server_type
  location    = var.location
  ssh_keys = [
  hcloud_ssh_key.default.id]
  user_data = data.template_file.user_data.rendered
}

# Put the VMs into the subnet
resource "hcloud_server_network" "worker-vms-into-subnet" {
  count     = var.instances
  server_id = hcloud_server.worker-vm[count.index].id
  subnet_id = hcloud_network_subnet.main.id
}
