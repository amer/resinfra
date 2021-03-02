provider "google" {
  credentials = file(var.gcp_service_account_path)
  project = var.gcp_project_id
  region = var.gcp_region
}

resource "random_id" "id" {
  byte_length = 4
}

/*
------------------------
    INTERNAL NETWORK
------------------------
*/


# Create a virtual network
resource "google_compute_network" "main" {
  name = "${var.prefix}-network-${random_id.id.hex}"
  auto_create_subnetworks = false
  routing_mode = "GLOBAL"
  # as seen in https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_ha_vpn_gateway
}

# Create a subnet
#   This subnet will be used to place the machines
resource "google_compute_subnetwork" "vms" {
  name = "${var.prefix}-internal-${random_id.id.hex}"
  ip_cidr_range = var.gcp_subnet_cidr
  region = var.gcp_region
  network = google_compute_network.main.self_link
}

# create firewall rule for port 22 (ssh)
resource "google_compute_firewall" "allow_ssh" {
  name = "${var.prefix}-network-internal-allow-ssh-${random_id.id.hex}"
  network = google_compute_network.main.self_link


  allow {
    protocol = "tcp"
    ports = [
      "22"]
  }
  source_ranges = [
    "0.0.0.0/0"]

}

# create firewall rule for port 80,443 (ssh)
resource "google_compute_firewall" "allow_internet" {
  name = "${var.prefix}-network-internal-allow-internet-${random_id.id.hex}"
  network = google_compute_network.main.self_link


  allow {
    protocol = "tcp"
    ports = [
      "80",
      "443"]
  }
  source_ranges = [
    "0.0.0.0/0"]

}

# allow all internal traffic (10.0.0.0/8)
resource "google_compute_firewall" "allow_internal" {
  name = "${var.prefix}-network-internal-allow-internal-${random_id.id.hex}"
  network = google_compute_network.main.self_link


  allow {
    protocol = "tcp"
  }
  source_ranges = [
    "10.0.0.0/8"]

}

# allow icmp
resource "google_compute_firewall" "allow_icmp" {
  name = "${var.prefix}-network-internal-allow-icmp-${random_id.id.hex}"
  network = google_compute_network.main.self_link


  allow {
    protocol = "icmp"
  }
  source_ranges = [
    "0.0.0.0/0"]

}


/*
----------------------------
    EXTERNAL NETWORK
----------------------------
*/

# Create public IPs
#   public ip for the virtual network gateway
resource "google_compute_address" "gateway_ip_address" {
  name = "${var.prefix}-vpn-gateway-address-${random_id.id.hex}"
}

#   public IP of the HA virtual network gateway
resource "google_compute_address" "ha_gateway_ip_address" {
  name = "${var.prefix}-vpn-ha-gateway-address-${random_id.id.hex}"
}

# Create classic VPN
resource "google_compute_vpn_gateway" "main" {
  name    = "${var.prefix}-vpn"
  network = google_compute_network.main.self_link
}

# Create HA VPN for use with BGP
resource "google_compute_ha_vpn_gateway" "main" {
  name    = "${var.prefix}-vpn-ha"
  network = google_compute_network.main.self_link
}

resource "google_compute_router" "main" {
  name = "${var.prefix}-vpn-ha-router"
  network = google_compute_network.main.self_link

  bgp {
    asn = var.gcp_asn
  }
}

# create VPN forwarding rules
#   these are the default rules created, and allow
#   - ESP: the Encapsulating Security Protocol, i.e., the protocol used to tunnel the original IP packages
#   - UDP/500: the port used by IKE, the Internet Key Exchange protocol, i.e., required for establishing the security
#              association between the two participants of the tunnel
#   - UDP/4500: fallback in case 500 is blocked -> probably not needed?
resource "google_compute_forwarding_rule" "fr_esp" {
  name        = "fr-esp"
  ip_protocol = "ESP"
  ip_address  = google_compute_address.gateway_ip_address.address
  target      = google_compute_vpn_gateway.main.self_link
}

resource "google_compute_forwarding_rule" "fr_udp500" {
  name        = "fr-ike"
  ip_protocol = "UDP"
  port_range  = "500"
  ip_address  = google_compute_address.gateway_ip_address.address
  target      = google_compute_vpn_gateway.main.self_link
}

resource "google_compute_forwarding_rule" "fr_udp4500" {
  name        = "fr-ike-fallback"
  ip_protocol = "UDP"
  port_range  = "4500"
  ip_address  = google_compute_address.gateway_ip_address.address
  target      = google_compute_vpn_gateway.main.self_link
}

# Create the tunnel & route trafic to remote networks through tunnel
#   for azure
resource "google_compute_vpn_tunnel" "azure_tunnel" {
  count         = var.ha_vpn_tunnel_count
  name          = "${var.prefix}-azure-tunnel-${count.index}-${random_id.id.hex}"
  shared_secret = var.shared_key

  # Use 'vpn_gateway' for HA VPN, and 'target_vpn_gateway' for classic VPN, as
  # [documented](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_vpn_tunnel#vpn_gateway).
  vpn_gateway = google_compute_ha_vpn_gateway.main.self_link
  vpn_gateway_interface = count.index
  peer_external_gateway = google_compute_external_vpn_gateway.azure_gateway.self_link
  peer_external_gateway_interface = count.index
  router = google_compute_router.main.name

  depends_on = [
    google_compute_forwarding_rule.fr_esp,
    google_compute_forwarding_rule.fr_udp500,
    google_compute_forwarding_rule.fr_udp4500,
  ]
}

resource "google_compute_external_vpn_gateway" "azure_gateway" {
  name            = "${var.prefix}-azure-gateway-${random_id.id.hex}"
  redundancy_type = {
    1: "SINGLE_IP_INTERNALLY_REDUNDANT",
    2: "TWO_IPS_REDUNDANCY",
    4: "FOUR_IPS_REDUNDANCY"
  }[var.ha_vpn_tunnel_count]

  interface {
    id         = 0
    ip_address = var.azure_gateway_ipv4_addresses[0]
  }
//  For High Availability: uncomment
//  interface {
//    id         = 1
//    ip_address = var.azure_gateway_ipv4_addresses[1]
//  }
}

resource "google_compute_router_interface" "azure" {
  count = var.ha_vpn_tunnel_count
  name = "${var.prefix}-azure-${count.index}-interface-${random_id.id.hex}"
  # This is weird because we have e.g. 169.254.22.2/30 which is not a valid CIDR prefix (-> rfc4632), but
  # - is interpreted as 169.254.22.0/30
  # - assigns the router the address specified, i.e., 169.254.22.2
  # TODO maybe investigate if this is (1) reliable and (2) needed
  ip_range = "${var.gcp_bgp_peer_address[count.index]}/30"
  router = google_compute_router.main.name
  vpn_tunnel = google_compute_vpn_tunnel.azure_tunnel[count.index].self_link
}

resource "google_compute_router_peer" "azure" {
  count = var.ha_vpn_tunnel_count
  name = "${var.prefix}-azure-${count.index}-bgp-peer-${random_id.id.hex}"
  router = google_compute_router.main.name
  peer_ip_address = var.azure_bgp_peer_address[count.index]
  peer_asn = var.azure_asn
  interface = google_compute_router_interface.azure[count.index].name
}

# Create the tunnel & route trafic to remote networks through tunnel
#   for hetzner
resource "google_compute_vpn_tunnel" "hetzner_tunnel" {
  name          = "${var.prefix}-hetzner-tunnel-${random_id.id.hex}"
  peer_ip       = var.hetzner_gateway_ipv4_address
  shared_secret = var.shared_key

  target_vpn_gateway      = google_compute_vpn_gateway.main.self_link
  local_traffic_selector  = [var.gcp_subnet_cidr]
  remote_traffic_selector = [var.hetzner_subnet_cidr]

  depends_on = [
    google_compute_forwarding_rule.fr_esp,
    google_compute_forwarding_rule.fr_udp500,
    google_compute_forwarding_rule.fr_udp4500,
  ]
}
resource "google_compute_route" "hetzner-route" {
  name = "${var.prefix}-hetzner-route-${random_id.id.hex}"
  network = google_compute_network.main.self_link
  dest_range = var.hetzner_subnet_cidr
  next_hop_vpn_tunnel = google_compute_vpn_tunnel.hetzner_tunnel.self_link
  priority = 0

}

# Create the tunnel & route trafic to remote networks through tunnel
#   for proxmox
resource "google_compute_vpn_tunnel" "proxmox_tunnel" {
  name = "${var.prefix}-proxmox-tunnel-${random_id.id.hex}"
  peer_ip = var.proxmox_gateway_ipv4_address
  shared_secret = var.shared_key

  target_vpn_gateway = google_compute_vpn_gateway.main.self_link
  local_traffic_selector = [
    var.gcp_subnet_cidr]
  remote_traffic_selector = [
    var.proxmox_subnet_cidr]

  depends_on = [
    google_compute_forwarding_rule.fr_esp,
    google_compute_forwarding_rule.fr_udp500,
    google_compute_forwarding_rule.fr_udp4500,
  ]
}
resource "google_compute_route" "proxmox-route" {
  name       = "${var.prefix}-proxmox-route-${random_id.id.hex}"
  network    = google_compute_network.main.self_link
  dest_range = var.proxmox_subnet_cidr
  priority   = 0
  next_hop_vpn_tunnel = google_compute_vpn_tunnel.proxmox_tunnel.self_link
}

/*
-------------------------------
   WORKER VM(s)
-------------------------------
*/


resource "google_compute_address" "static" {
  count = var.instances
  name = "${var.prefix}-ipv4-address-${count.index + 1}-${random_id.id.hex}"
}

resource "google_compute_instance" "worker_vm" {
  count = var.instances
  name = "${var.prefix}-gcp-vm-${count.index + 1}-${random_id.id.hex}"
  machine_type = var.gcp_machine_type
  zone = "${var.gcp_region}-b"

  boot_disk {
    initialize_params {
      image = "gcp-worker-vm"
      size = 50
    }
  }

  network_interface {
    network = google_compute_network.main.self_link
    subnetwork = google_compute_subnetwork.vms.self_link
    access_config {
      nat_ip = google_compute_address.static[count.index].address
    }
  }

  metadata = {
    ssh-keys = "resinfra:${file(var.path_public_key)}"
  }
}
