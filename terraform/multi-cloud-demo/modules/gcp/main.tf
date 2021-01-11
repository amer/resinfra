terraform {
  required_version = "=0.14.4"
  required_providers {
    google = {
      source = "hashicorp/google"
    }
  }
}

provider "google" {
  credentials = file(var.gcp_service_account_path)
  project     = var.gcp_project_id
  region      = var.gcp_region
}

resource "random_id" "id" {
  byte_length = 4
}


# Create a virtual network
resource "google_compute_network" "main" {
  name                    = "${var.prefix}-network-${random_id.id.hex}"
  auto_create_subnetworks = false
}

# Create a subnet
#   This subnet will be used to place the machines
resource "google_compute_subnetwork" "vms" {
  name          = "${var.prefix}-internal-${random_id.id.hex}"
  ip_cidr_range = var.gcp_subnet_cidr
  region        = var.gcp_region
  network       = google_compute_network.main.id
}

# create firewall rule for port 22 (ssh)
resource "google_compute_firewall" "allow_ssh" {
  name    = "${var.prefix}-network-internal-allow-ssh-${random_id.id.hex}"
  network = google_compute_network.main.name


  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["0.0.0.0/0"]

}
# allow all internal traffic (10.0.0.0/8)
resource "google_compute_firewall" "allow_internal" {
  name    = "${var.prefix}-network-internal-allow-internal-${random_id.id.hex}"
  network = google_compute_network.main.name


  allow {
    protocol = "tcp"
  }
  source_ranges = ["10.0.0.0/8"]

}
# allow icmp
resource "google_compute_firewall" "allow_icmp" {
  name    = "${var.prefix}-network-internal-allow-icmp-${random_id.id.hex}"
  network = google_compute_network.main.name


  allow {
    protocol = "icmp"
  }
  source_ranges = ["0.0.0.0/0"]

}

# Create public IPs
#   public ip for the virtual network gateway
resource "google_compute_address" "gateway_ip_address" {
  name = "${var.prefix}-vpn-gateway-address-${random_id.id.hex}"
}

# Create classic VPN
resource "google_compute_vpn_gateway" "main" {
  name    = "${var.prefix}-vpn"
  network = google_compute_network.main.id
}

# create VPN forwarding routes
#   these are the default routes created.
#   TODO: find out, what they are actually doing / good for.

resource "google_compute_forwarding_rule" "fr_esp" {
  name        = "fr-esp"
  ip_protocol = "ESP"
  ip_address  = google_compute_address.gateway_ip_address.address
  target      = google_compute_vpn_gateway.main.id
}

resource "google_compute_forwarding_rule" "fr_udp500" {
  name        = "fr-udp500"
  ip_protocol = "UDP"
  port_range  = "500"
  ip_address  = google_compute_address.gateway_ip_address.address
  target      = google_compute_vpn_gateway.main.id
}

resource "google_compute_forwarding_rule" "fr_udp4500" {
  name        = "fr-udp4500"
  ip_protocol = "UDP"
  port_range  = "4500"
  ip_address  = google_compute_address.gateway_ip_address.address
  target      = google_compute_vpn_gateway.main.id
}

# Create the tunnel & route trafic to remote networks through tunnel
#   for azure
resource "google_compute_vpn_tunnel" "azure_tunnel" {
  name          = "${var.prefix}-azure-tunnel-${random_id.id.hex}"
  peer_ip       = var.azure_gateway_ipv4_address
  shared_secret = var.shared_key

  target_vpn_gateway      = google_compute_vpn_gateway.main.id
  local_traffic_selector  = [var.gcp_subnet_cidr]
  remote_traffic_selector = [var.azure_subnet_cidr]

  depends_on = [
    google_compute_forwarding_rule.fr_esp,
    google_compute_forwarding_rule.fr_udp500,
    google_compute_forwarding_rule.fr_udp4500,
  ]
}
resource "google_compute_route" "azure-route" {
  name       = "${var.prefix}-azure-route-${random_id.id.hex}"
  network    = google_compute_network.main.name
  dest_range = var.azure_subnet_cidr

  next_hop_vpn_tunnel = google_compute_vpn_tunnel.azure_tunnel.id
}

# Create the tunnel & route trafic to remote networks through tunnel
#   for hetzner
resource "google_compute_vpn_tunnel" "hetzner_tunnel" {
  name          = "${var.prefix}-hetzner-tunnel-${random_id.id.hex}"
  peer_ip       = var.hetzner_gateway_ipv4_address
  shared_secret = var.shared_key

  target_vpn_gateway      = google_compute_vpn_gateway.main.id
  local_traffic_selector  = [var.gcp_subnet_cidr]
  remote_traffic_selector = [var.hetzner_subnet_cidr]

  depends_on = [
    google_compute_forwarding_rule.fr_esp,
    google_compute_forwarding_rule.fr_udp500,
    google_compute_forwarding_rule.fr_udp4500,
  ]
}
resource "google_compute_route" "hetzner-route" {
  name       = "${var.prefix}-hetzner-route-${random_id.id.hex}"
  network    = google_compute_network.main.name
  dest_range = var.hetzner_subnet_cidr

  next_hop_vpn_tunnel = google_compute_vpn_tunnel.hetzner_tunnel.id
}

# Create a worker VM

data "template_file" "user_data" {
  template = file("${path.module}/preconf.yml")

  vars = {
    username = "resinfra"
    public_key = file(var.path_public_key)
  }
}
data "template_cloudinit_config" "config" {
  gzip          = true
  base64_encode = true

  part {
    filename     = "cloud-init"
    content_type = "text/cloud-config"
    content      = data.template_file.user_data.rendered
  }
}
resource "google_compute_instance" "vm" {
  count = var.instances
  name         = "${var.prefix}-vm-${count.index + 1}-${random_id.id.hex}"
  machine_type = "e2-micro"
  zone         = "${var.gcp_region}-b"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-10"
    }
  }

  network_interface {
    network = google_compute_subnetwork.vms.id
  }

  metadata = {
     user-data = "${data.template_cloudinit_config.config.rendered}"
  }

}
