locals {
  azure_cidr = cidrsubnet(var.vpc_cidr, 8, 1)
  # 10.1.0.0/16 (Azure does not allow to add overlapping subnets when creating vpn routes)
  azure_vm_subnet_cidr = cidrsubnet(var.vpc_cidr, 16, 256)
  # 10.1.0.0/24
  azure_gateway_subnet_cidr = cidrsubnet(var.vpc_cidr, 16, 257)
  # 10.1.1.0/24

  gcp_cidr = cidrsubnet(var.vpc_cidr, 8, 2)
  # 10.2.0.0/16
  gcp_vm_subnet_cidr = cidrsubnet(var.vpc_cidr, 16, 512)
  # 10.2.0.0/24

  hetzner_cidr = var.vpc_cidr
  # 10.0.0.0/8 (Hetzner needs to have all subnets included in the big VPN)
  hetzner_vm_subnet_cidr = cidrsubnet(var.vpc_cidr, 16, 768)
  # 10.3.0.0/24

  proxmox_cidr = cidrsubnet(var.vpc_cidr, 8, 4)
  # 10.4.0.0/16
  proxmox_vm_subnet_cidr = cidrsubnet(local.proxmox_cidr, 8, 0)
  # 10.4.0.0/24

  # In our architecture, each provider gets assigned an IP address range in which it can freely assign addresses
  # (through DHCP). Thus, each provider is treated as an Autonomous System and is assigned an Autonomous System Number
  # from the pool of private ASNs as defined in RFC6996, 64512 - 65534. Azure (and maybe other providers) reserve some
  # of the private ASNs for internal use, see https://docs.microsoft.com/de-de/azure/vpn-gateway/vpn-gateway-bgp-overview#what-asns-autonomous-system-numbers-can-i-use
  azure_asn = 65521
  gcp_asn   = 65522

  # The BGP peer address can theoretically be any address other than the public IP addresses of the VPN gateways.
  # In the case of GCP, it must be an APIPA address.
  # In the case of Azure, it can be any address, but if it is an APIPA address,
  # it must be 169.254.21/24 or 169.254.22/24. (https://docs.microsoft.com/en-us/azure/vpn-gateway/bgp-howto)
  # FIXME this structure won't make sense any more when we activate BGP for more providers.
  azure_bgp_peer_addresses = ["169.254.22.1", "169.254.22.5"]
  gcp_bgp_peer_addresses   = ["169.254.22.2", "169.254.22.6"]

  # The number of redundant tunnels to open between two BGP-enabled gateways.
  # At the moment, only '1' is supported. More information on why this is can be found in PR#45.
  # If a value >1 is to be used, some code changes need to be made in the Azure and GCP modules. There are comments
  # marking them as 'For High Availability'. Sensible values are {1,2,4}.
  ha_vpn_tunnel_count = 1

  path_private_key = "~/.ssh/ri_key"
  path_public_key  = "~/.ssh/ri_key.pub"

  azure_worker_vm_image_id = "/subscriptions/${var.subscription_id}/resourceGroups/${var.azure_resource_group}/providers/Microsoft.Compute/images/azure-worker-vm"

  consul_leader_ip = "10.3.0.254"
}

module "hetzner" {
  source                       = "../../../terraform/modules/hetzner"
  hcloud_token                 = var.hcloud_token
  shared_key                   = var.shared_key
  path_private_key             = local.path_private_key
  path_public_key              = local.path_public_key
  azure_vm_subnet_cidr         = local.azure_vm_subnet_cidr
  gcp_gateway_ipv4_address     = module.gcp.gcp_gateway_ipv4_address
  azure_gateway_ipv4_address   = module.azure.azure_gateway_ipv4_address
  gcp_vm_subnet_cidr           = local.gcp_vm_subnet_cidr
  proxmox_vm_subnet_cidr       = local.proxmox_vm_subnet_cidr
  proxmox_gateway_ipv4_address = module.proxmox.gateway_ipv4_address
  hetzner_vm_subnet_cidr       = local.hetzner_vm_subnet_cidr
  hetzner_vpc_cidr             = local.hetzner_cidr
  prefix                       = var.prefix
  instances                    = var.instances
  consul_leader_ip             = local.consul_leader_ip
  machine_type                 = "cx21"
}

module "azure" {
  source                       = "../../../terraform/modules/azure"
  subscription_id              = var.subscription_id
  client_id                    = var.client_id
  client_secret                = var.client_secret
  tenant_id                    = var.tenant_id
  location                     = "westeurope"
  vm_size                      = "Standard_A2_v2" # For more info https://azureprice.net/
  path_private_key             = local.path_private_key
  path_public_key              = local.path_public_key
  azure_gateway_subnet_cidr    = local.azure_gateway_subnet_cidr
  azure_vm_subnet_cidr         = local.azure_vm_subnet_cidr
  azure_vpc_cidr               = local.azure_cidr
  azure_asn                    = local.azure_asn
  azure_bgp_peer_addresses     = local.azure_bgp_peer_addresses
  gcp_gateway_ipv4_address     = module.gcp.gcp_gateway_ipv4_address
  gcp_vm_subnet_cidr           = local.gcp_vm_subnet_cidr
  gcp_asn                      = local.gcp_asn
  gcp_bgp_peer_addresses       = local.gcp_bgp_peer_addresses
  gcp_ha_gateway_interfaces    = module.gcp.gcp_ha_gateway_interfaces
  hcloud_gateway_ipv4_address  = module.hetzner.gateway_ipv4_address
  hcloud_vm_subnet_cidr        = local.hetzner_vm_subnet_cidr
  proxmox_gateway_ipv4_address = module.proxmox.gateway_ipv4_address
  proxmox_vm_subnet_cidr       = local.proxmox_vm_subnet_cidr
  ha_vpn_tunnel_count          = local.ha_vpn_tunnel_count
  shared_key                   = var.shared_key
  prefix                       = var.prefix
  instances                    = var.instances
  azure_worker_vm_image_id     = local.azure_worker_vm_image_id
  resource_group               = var.azure_resource_group
}

module "gcp" {
  source                       = "../../../terraform/modules/gcp"
  azure_gateway_ipv4_addresses = module.azure.azure_ha_gateway_ipv4_addresses
  azure_subnet_cidr            = local.azure_vm_subnet_cidr
  azure_asn                    = local.azure_asn
  azure_bgp_peer_address       = local.azure_bgp_peer_addresses
  gcp_project_id               = var.gcp_project_id
  gcp_region                   = var.gcp_region
  gcp_service_account_path     = var.gcp_service_account_path
  gcp_subnet_cidr              = local.gcp_vm_subnet_cidr
  gcp_asn                      = local.gcp_asn
  gcp_bgp_peer_address         = local.gcp_bgp_peer_addresses
  hetzner_gateway_ipv4_address = module.hetzner.gateway_ipv4_address
  hetzner_subnet_cidr          = local.hetzner_vm_subnet_cidr
  proxmox_gateway_ipv4_address = module.proxmox.gateway_ipv4_address
  proxmox_subnet_cidr          = local.proxmox_vm_subnet_cidr
  ha_vpn_tunnel_count          = local.ha_vpn_tunnel_count
  prefix                       = var.prefix
  shared_key                   = var.shared_key
  path_public_key              = local.path_public_key
  instances                    = var.instances
  gcp_machine_type             = "e2-medium"
}

module "proxmox" {
  source                          = "../../../terraform/modules/proxmox/vm"
  hetzner_gateway_ipv4_address    = module.hetzner.gateway_ipv4_address
  hetzner_vm_subnet_cidr          = local.hetzner_vm_subnet_cidr
  azure_gateway_ipv4_address      = module.azure.azure_gateway_ipv4_address
  azure_vm_subnet_cidr            = local.azure_vm_subnet_cidr
  gcp_gateway_ipv4_address        = module.gcp.gcp_gateway_ipv4_address
  gcp_vm_subnet_cidr              = local.gcp_vm_subnet_cidr
  proxmox_api_password            = var.proxmox_api_password
  proxmox_api_user                = var.proxmox_api_user
  path_private_key                = local.path_private_key
  path_public_key                 = local.path_public_key
  prefix                          = var.prefix
  proxmox_server_port             = var.proxmox_server_port
  proxmox_server_address          = var.proxmox_server_address
  proxmox_target_node             = var.proxmox_target_node
  proxmox_private_gateway_address = var.proxmox_private_gateway_address
  proxmox_public_ip_cidr          = "92.204.185.32/29"
  proxmox_vm_subnet_cidr          = local.proxmox_vm_subnet_cidr
  vm_username                     = var.vm_username
  instances                       = var.instances
  shared_key                      = var.shared_key
  num_cores                       = 2
  memory                          = 2048
}

# create the hosts file
# uses the prviate ip addresses of the deployed vms
resource "local_file" "hosts_file_creation" {

  content = templatefile("cockroach_host.ini.tpl", {
    cockroach_cluster_initializer = module.hetzner.hcloud_private_ip_addresses[0]
    azure_hosts                   = module.azure.azure_private_ip_addresses
    gcp_hosts                     = module.gcp.gcp_private_ip_addresses
    hetzner_hosts                 = module.hetzner.hcloud_private_ip_addresses
    proxmox_hosts                 = module.proxmox.proxmox_private_ip_addresses
  })
  filename = "cockroach_host.ini"
}

# copy over the hosts file to the deployer vm
resource "null_resource" "hosts_file_copy" {
  depends_on = [
    local_file.hosts_file_creation
  ]

  triggers = {
    local_file_id = local_file.hosts_file_creation.id
  }

  connection {
    type        = "ssh"
    user        = "root"
    private_key = file(local.path_private_key)
    host        = module.hetzner.hcloud_deployer_public_ip
  }

  provisioner "file" {
    source      = "cockroach_host.ini"
    destination = "~/cockroach_host.ini"
  }
}

resource "null_resource" "cockroach_ansible" {
  depends_on = [
    local_file.hosts_file_creation,
    null_resource.hosts_file_copy
  ]

  triggers = {
    local_file_id = local_file.hosts_file_creation.id
  }

  connection {
    type        = "ssh"
    user        = "root"
    private_key = file(local.path_private_key)
    host        = module.hetzner.hcloud_deployer_public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'SSH is now ready!'",
      "sleep 30",
      "echo '${file(local.path_private_key)}' >> ~/.ssh/vm_key",
      "chmod 0600 ~/.ssh/vm_key",
      "cd /resinfra",
      # "git pull",
      "git checkout benchmarking",
      "cd ansible",
      <<EOF
        ansible-playbook cockroach_playbook.yml \
                -i ~/cockroach_host.ini \
                -u resinfra \
                --ssh-common-args='-o StrictHostKeyChecking=no' \
                --private-key ~/.ssh/vm_key \
                --extra-vars 'priv_ip_list='${join(",", module.azure.azure_private_ip_addresses, module.gcp.gcp_private_ip_addresses, module.hetzner.hcloud_private_ip_addresses, module.proxmox.proxmox_private_ip_addresses)}' ansible_python_interpreter=/usr/bin/python3'
      EOF
    ]
  }
}
