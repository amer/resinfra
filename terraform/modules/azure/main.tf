# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
  # More information on the authentication methods supported by
  # the AzureRM Provider can be found here:
  # http://terraform.io/docs/providers/azurerm/index.html

  subscription_id = var.subscription_id
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
}


resource "random_id" "id" {
  byte_length = 4
}

data "azurerm_subscription" "current" {}

/*
------------------------
    INTERNAL NETWORK
------------------------
*/

resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-network"
  address_space       = [var.azure_vpc_cidr]
  location            = var.location
  resource_group_name = var.resource_group
}

# This subnet will be used for all VMs
resource "azurerm_subnet" "vms" {
  name                 = "internal"
  resource_group_name  = var.resource_group
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.azure_vm_subnet_cidr]
}

# This subnet will be used for the virtual network gateway only
resource "azurerm_subnet" "gateway" {
  name                 = "GatewaySubnet"
  resource_group_name  = var.resource_group
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.azure_gateway_subnet_cidr]
}

resource "azurerm_public_ip" "worker_vm" {
  count               = var.instances
  name                = "${var.prefix}-public-ip-${count.index}-${random_id.id.hex}"
  location            = var.location
  resource_group_name = var.resource_group
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "worker_vm" {
  count               = var.instances
  name                = "${var.prefix}-nic-${count.index}-${random_id.id.hex}"
  location            = var.location
  resource_group_name = var.resource_group

  ip_configuration {
    name                          = "${var.prefix}-NicConfiguration-${random_id.id.hex}"
    subnet_id                     = azurerm_subnet.vms.id
    public_ip_address_id          = azurerm_public_ip.worker_vm[count.index].id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_security_group" "main" {
  name                = "${var.prefix}-security-group-${random_id.id.hex}"
  location            = var.location
  resource_group_name = var.resource_group

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "main" {
  count                     = var.instances
  network_interface_id      = azurerm_network_interface.worker_vm[count.index].id
  network_security_group_id = azurerm_network_security_group.main.id
}


/*
----------------------------
    SITE-TO-SITE NETWORK
----------------------------
*/

resource "azurerm_public_ip" "gateway" {
  count               = var.ha_vpn_tunnel_count
  name                = "${var.prefix}-public-gateway-ip-${count.index}-${random_id.id.hex}"
  location            = var.location
  resource_group_name = var.resource_group
  # The public IP address of a virtual network gateway can only be dynamic. Dynamic IP addresses are only "materialized"
  # when they are assigned to an actually existing resource. Unfortunately, this means that the address will not be part
  # of the output of the `terraform apply` run in which the gateway is created. Re-run `terraform apply` to get the
  # IP address and correctly setup VPN connections.
  allocation_method   = "Dynamic"
}

# Local network gateway models the remote HCloud / Proxmox VPN gateway and does not actually deploy anything.
resource "azurerm_local_network_gateway" "hetzner" {
  name                = "hetzner-onpremise"
  location            = var.location
  resource_group_name = var.resource_group

  gateway_address = var.hcloud_gateway_ipv4_address
  address_space   = [var.hcloud_vm_subnet_cidr]
}

resource "azurerm_local_network_gateway" "proxmox" {
  name                = "proxmox"
  location            = var.location
  resource_group_name = var.resource_group

  gateway_address = var.proxmox_gateway_ipv4_address
  address_space   = [var.proxmox_vm_subnet_cidr]
}

# The tunnel to GCP uses BGP, and some things have been prepared to make it highly available. For details, see PR#45.
resource "azurerm_local_network_gateway" "gcp" {
  count = var.ha_vpn_tunnel_count

  name                = "gcp-${count.index}"
  location            = var.location
  resource_group_name = var.resource_group

  gateway_address = var.gcp_ha_gateway_interfaces[count.index].ip_address
  # We add no addresses here, because all routes will be discovered through BGP, with one exception: The route to the
  # BGP peer is added by Azure automatically and not visible. See also https://docs.microsoft.com/en-us/azure/vpn-gateway/vpn-gateway-bgp-overview#what-should-i-specify-as-my-address-prefixes-for-the-local-network-gateway-when-i-use-bgp
  address_space = []

  bgp_settings {
    asn = var.gcp_asn
    bgp_peering_address = var.gcp_bgp_peer_addresses[count.index]
  }
}

# The virtual network gateway is the VPN gateway on the Azure side.
resource "azurerm_virtual_network_gateway" "main" {
  name                = "${var.prefix}-network-gateway"
  location            = var.location
  resource_group_name = var.resource_group

  type     = "Vpn"
  vpn_type = "RouteBased"

  active_active = false # For High Availability: Set to true if you want load balancing instead of failover
  enable_bgp    = true
  sku           = "HighPerformance" # Needed for active/active, can also be "Standard" otherwise

  ip_configuration {
    name                          = "${var.prefix}-vnetGatewayConfig-0"
    public_ip_address_id          = azurerm_public_ip.gateway[0].id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.gateway.id
  }
//  For High Availability: uncomment if you need more interfaces.
//  ip_configuration {
//    name                          = "${var.prefix}-vnetGatewayConfig-1"
//    public_ip_address_id          = azurerm_public_ip.gateway[1].id
//    private_ip_address_allocation = "Dynamic"
//    subnet_id                     = azurerm_subnet.gateway.id
//  }

  bgp_settings {
    asn = var.azure_asn
  }

  # Setting the BGP peer address to an APIPA address is not supported as of 02/2021, see
  # https://github.com/terraform-providers/terraform-provider-azurerm/issues/10262
  # Instead, we set it through the Azure REST API here.
  # FIXME there should be a better way of "zipping" the bgpPeeringAddresses and the azure_bgp_peer_address array
  provisioner "local-exec" {
    command = <<EOF
      URL='https://management.azure.com/subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/${var.resource_group}/providers/Microsoft.Network/virtualNetworkGateways/${azurerm_virtual_network_gateway.main.name}?api-version=2020-07-01'
      AUTH_HEADER="Authorization: Bearer $(az account get-access-token | jq -r '.accessToken')"
      curl -H "$AUTH_HEADER" $URL | \
        jq -M '.properties.bgpSettings.bgpPeeringAddresses[0].customBgpIpAddresses = ["${var.azure_bgp_peer_addresses[0]}"] |
               .properties.bgpSettings.bgpPeeringAddresses[1].customBgpIpAddresses = ["${var.azure_bgp_peer_addresses[1]}"]' | \
        curl -XPUT -H "$AUTH_HEADER" -H 'Content-Type: application/json' --data @- $URL
    EOF
  }
}

resource "azurerm_virtual_network_gateway_connection" "main" {
  for_each = {
    "hetzner" = { "id" = azurerm_local_network_gateway.hetzner.id, "bgp" = false },
    "gcp"     = { "id" = azurerm_local_network_gateway.gcp.id, "bgp" = true },
    "proxmox" = { "id" = azurerm_local_network_gateway.proxmox.id, "bgp" = false }
  }

  name                = "${each.key}-connection"
  location            = var.location
  resource_group_name = var.resource_group

  type                       = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.main.id
  local_network_gateway_id   = each.value["id"]
  enable_bgp                 = each.value["bgp"]

  shared_key = var.shared_key
}


/*
-------------------------------
   WORKER VM(s)
-------------------------------
*/

resource "azurerm_linux_virtual_machine" "worker_vm" {
  count               = var.instances
  name                = "${var.prefix}-azure-vm-${count.index + 1}-${random_id.id.hex}"
  resource_group_name = var.resource_group
  location            = var.location
  size                = var.vm_size
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.worker_vm[count.index].id,
  ]

  source_image_id = var.azure_worker_vm_image_id

  admin_ssh_key {
    username   = "adminuser"
    public_key = file(var.path_public_key)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 50
  }
}
