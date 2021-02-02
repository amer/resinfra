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

resource "azurerm_resource_group" "main" {
  name     = "${var.prefix}-multi-cloud-rg"
  location = var.location
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
resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-network"
  address_space       = [var.azure_vpc_cidr]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

# Create a subnet
#   This subnet will be used to place the machines
resource "azurerm_subnet" "vms" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.azure_vm_subnet_cidr]
}


# Create a second subnet as GatewaySubnet
#   This subnet will be used for the gateways
resource "azurerm_subnet" "gateway" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.azure_gateway_subnet_cidr]
}


//# Create public IPs
//resource "azurerm_public_ip" "main" {
//  name                = "${var.prefix}-public-ip-${random_id.id.hex}"
//  location            = azurerm_resource_group.main.location
//  resource_group_name = azurerm_resource_group.main.name
//  allocation_method   = "Dynamic"
//}

resource "azurerm_network_interface" "main" {
  count               = var.instances
  name                = "${var.prefix}-nic-${count.index + 1}-${random_id.id.hex}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name      = "${var.prefix}-NicConfiguration-${random_id.id.hex}"
    subnet_id = azurerm_subnet.vms.id
    # public_ip_address_id          = azurerm_public_ip.main.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "main" {
  name                = "${var.prefix}-security-group-${random_id.id.hex}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

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
  network_interface_id      = azurerm_network_interface.main[count.index].id
  network_security_group_id = azurerm_network_security_group.main.id
}


/*
----------------------------
    EXTERNAL NETWORK
----------------------------
*/


# Create public IP for Gateway
resource "azurerm_public_ip" "gateway" {
  name                = "${var.prefix}-public-gateway-ip-${random_id.id.hex}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Dynamic"
}

# Create local network gateway
#   This is the place where we will store the IP Adresse range of the other network
#   as well as the ip address of the other gateway.
resource "azurerm_local_network_gateway" "hetzner_onpremise" {
  name                = "hetzner-onpremise"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  gateway_address = var.hcloud_gateway_ipv4_address
  address_space   = [var.hcloud_vm_subnet_cidr]
}

resource "azurerm_local_network_gateway" "proxmox" {
  name                = "proxmox"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  gateway_address = var.proxmox_gateway_ipv4_address
  address_space   = [var.proxmox_vm_subnet_cidr]
}

# The tunnel to GCP uses BGP, but is not yet highly available.
resource "azurerm_local_network_gateway" "gcp" {
  name                = "gcp"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  # Just use the first address until we can establish redundant connections
  gateway_address = var.gcp_ha_gateway_interfaces[0].ip_address
  # We only add the address of the BGP peer to the route table.
  # The rest of the routes will be discovered through BGP.
  address_space = ["${var.gcp_bgp_peer_address}/32"]

  bgp_settings {
    asn = var.gcp_asn
    bgp_peering_address = var.gcp_bgp_peer_address
  }
}

# Create virtual network gateway
resource "azurerm_virtual_network_gateway" "main" {
  name                = "${var.prefix}-network-gateway"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  type     = "Vpn"
  vpn_type = "RouteBased"

  active_active = false
  enable_bgp    = true
  sku           = "Standard"

  ip_configuration {
    name                          = "${var.prefix}-vnetGatewayConfig"
    public_ip_address_id          = azurerm_public_ip.gateway.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.gateway.id
  }

  bgp_settings {
    asn = var.azure_asn
    # "The IP address must be part of the subnet of the Virtual Network Gateway.", but it cannot be, because GCP
    # requires the address to be "link-local", i.e., 169.254/16
    peering_address = var.azure_bgp_peer_address
  }
}

# Create the connection between the gateways.
#   Internally, this is realized by connecting the virtual network gateway with
#   the local network gateway
resource "azurerm_virtual_network_gateway_connection" "hetzner_onpremise" {
  name                = "hetzner-onpremise-connection"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  type                       = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.main.id
  local_network_gateway_id   = azurerm_local_network_gateway.hetzner_onpremise.id

  shared_key = var.shared_key
}

resource "azurerm_virtual_network_gateway_connection" "gcp" {
  name                = "gcp-connection"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  type                       = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.main.id
  local_network_gateway_id   = azurerm_local_network_gateway.gcp.id
  enable_bgp                 = true

  shared_key = var.shared_key
}

resource "azurerm_virtual_network_gateway_connection" "proxmox" {
  name                = "proxmox-connection"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  type                       = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.main.id
  local_network_gateway_id   = azurerm_local_network_gateway.proxmox.id

  shared_key = var.shared_key
}


/*
-------------------------------
   WORKER VM(s)
-------------------------------
*/


data "template_file" "user_data" {
  template = file("${path.module}/preconf.yml")

  vars = {
    username   = "resinfra"
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

# Create a virtual machine
resource "azurerm_linux_virtual_machine" "worker_vm" {
  count               = var.instances
  name                = "${var.prefix}-azure-vm-${count.index + 1}-${random_id.id.hex}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  size                = var.vm_size
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.main[count.index].id,
  ]
  custom_data = data.template_cloudinit_config.config.rendered


  admin_ssh_key {
    username   = "adminuser"
    public_key = file(var.path_public_key)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Debian"
    offer     = "debian-10"
    sku       = "10"
    version   = "latest"
  }
}
