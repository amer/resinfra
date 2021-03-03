provider "hcloud" {
  token = var.hcloud_token
}

resource "random_id" "id" {
  byte_length = 4
}

resource "hcloud_ssh_key" "default" {
  name = "${var.prefix}-hetzner-key-${random_id.id.hex}"
  public_key = file(var.path_public_key)
}

data "hcloud_image" "worker-image" {
  with_selector = "hetzner-worker-vm"
  most_recent = true
}

data "hcloud_image" "deployer-snapshot" {
  with_selector = "hetzner-benchmark"
  most_recent = true
}

data "hcloud_image" "gateway-snapshot" {
  with_selector = "hetzner-gateway-vm"
  most_recent = true
}

/*
------------------------
    INTERNAL NETWORK
------------------------
*/

resource "hcloud_network" "main" {
  name     = "${var.prefix}-network-${random_id.id.hex}"
  ip_range = var.hetzner_vpc_cidr
}

# Everything will be placed in this subnet, Gateway + other VMs
resource "hcloud_network_subnet" "main" {
  network_id   = hcloud_network.main.id
  type         = "cloud"
  network_zone = "eu-central"
  ip_range     = var.hetzner_vm_subnet_cidr
}

/*
-------------------------------
   DEPLOYER VM
-------------------------------
*/

resource "hcloud_server" "deployer" {
  name = "${var.prefix}-hetzner-deployer-${random_id.id.hex}"
  image = data.hcloud_image.deployer-snapshot.id
  server_type = "cpx31"
  ssh_keys = [hcloud_ssh_key.default.id]
  location = var.location
}

resource "hcloud_server_network" "deployer" {
  server_id = hcloud_server.deployer.id
  subnet_id = hcloud_network_subnet.main.id
  ip = var.consul_leader_ip
}

/*
----------------------------
    SITE-TO-SITE NETWORK
----------------------------
*/

# There is no managed VPN service on Hetzner. Use a normal VM and later provision it as a gateway.
resource "hcloud_server" "gateway" {
  name = "${var.prefix}-hetzner-gateway-vm-${random_id.id.hex}"
  image = data.hcloud_image.gateway-snapshot.id
  server_type = var.machine_type
  location = "nbg1"
  ssh_keys = [hcloud_ssh_key.default.id]
}

resource "hcloud_server_network" "gateway" {
  server_id = hcloud_server.gateway.id
  subnet_id = hcloud_network_subnet.main.id
}

# Copy the secrets and IPSec config file to the gateway vm
resource "null_resource" "copy_ipsec_files" {
  connection {
    type = "ssh"
    user = "root"
    private_key = file(var.path_private_key)
    host = hcloud_server.gateway.ipv4_address
  }

  provisioner "file" {
    content = templatefile("${path.module}../../../templates/strongswan-ipsec.conf.j2", {
      public_gateway_ip = hcloud_server.gateway.ipv4_address
      local_cidr = var.hetzner_vm_subnet_cidr
      azure_remote_gateway_ip = var.azure_gateway_ipv4_address
      azure_remote_cidr = var.azure_vm_subnet_cidr
      gcp_remote_gateway_ip = var.gcp_gateway_ipv4_address
      gcp_remote_cidr = var.gcp_vm_subnet_cidr
      other_strongswan_gateway_ip = var.proxmox_gateway_ipv4_address
      other_strongswan_remote_cidr = var.proxmox_vm_subnet_cidr
    })
    destination = "/etc/ipsec.conf"
  }
  provisioner "file" {
    content = templatefile("${path.module}../../../templates/ipsec.secrets.j2", {
      public_gateway_ip = hcloud_server.gateway.ipv4_address
      azure_remote_gateway_ip = var.azure_gateway_ipv4_address
      gcp_remote_gateway_ip = var.gcp_gateway_ipv4_address
      other_strongswan_gateway_ip = var.proxmox_gateway_ipv4_address
      psk = var.shared_key
    })
    destination = "/etc/ipsec.secrets"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod 0400 /etc/ipsec.secrets",
      "chmod 0400 /etc/ipsec.conf",
      "ipsec restart && ipsec start"
    ]
  }
}

resource "hcloud_network_route" "azure_via_gateway" {
  network_id = hcloud_network.main.id
  destination = var.azure_vm_subnet_cidr
  gateway = hcloud_server_network.gateway.ip
}

resource "hcloud_network_route" "gcp_via_gateway" {
  network_id = hcloud_network.main.id
  destination = var.gcp_vm_subnet_cidr
  gateway = hcloud_server_network.gateway.ip
}

resource "hcloud_network_route" "proxmox_via_gateway" {
  network_id = hcloud_network.main.id
  destination = var.proxmox_vm_subnet_cidr
  gateway = hcloud_server_network.gateway.ip
}

/*
-------------------------------
   WORKER VM(s)
-------------------------------
*/

resource "hcloud_server" "worker-vm" {
  count = var.instances
  name = "${var.prefix}-hetzner-vm-${count.index + 1}-${random_id.id.hex}"
  image = data.hcloud_image.worker-image.id
  server_type = var.server_type
  location = var.location
  ssh_keys = [hcloud_ssh_key.default.id]
}

resource "hcloud_server_network" "worker-vm" {
  count = var.instances
  server_id = hcloud_server.worker-vm[count.index].id
  subnet_id = hcloud_network_subnet.main.id
}
