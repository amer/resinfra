/*
--------------------
    PREPARATION  
--------------------
*/


variable "prefix" {
  default = "resinfra"
}

provider "hcloud" {
  token   = var.hetzner_token
}

provider "azurerm" {
  version = "=2.37.0"
  features {}

  # More information on the authentication methods supported by
  # the AzureRM Provider can be found here:
  # http://terraform.io/docs/providers/azurerm/index.html

  subscription_id = var.resinfra_subscription_id
  client_id       = var.resinfra_client_id
  client_secret   = var.resinfra_client_secret
  tenant_id       = var.resinfra_tenant_id
}

resource "hcloud_ssh_key" "default" {
  name       = "${var.prefix}-key"
  public_key = file("~/.ssh/id_rsa.pub")
}

# Create a resource group
resource "azurerm_resource_group" "main" {
  name     = "${var.prefix}-resources"
  location = "West US"
}


/*
------------------
    NETWORKS
-------------------
*/


### AZURE ###

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

# Create public IPs
#   public ip for the virtual network gateway
resource "azurerm_public_ip" "main" {
  name                         = "${var.prefix}-public-ip"
  location                     = azurerm_resource_group.main.location
  resource_group_name          = azurerm_resource_group.main.name
  allocation_method            = "Dynamic"
}

### HETZNER ###

# Create a virtual network
resource "hcloud_network" "main" {
  name = "${var.prefix}-network"
  ip_range = var.hetzner_vpc_cidr
}

# Create a subnet for both the gateway and the vms
resource "hcloud_network_subnet" "main" {
  network_id = hcloud_network.main.id
  type = "cloud"
  network_zone = "eu-central"
  ip_range   = var.hetzner_subnet_cidr
}


/*
-----------------------------
    MANUAL GATEWAY VM(S)
-----------------------------
*/

### HETZNER ###

# Create VM that will be the gateway
resource "hcloud_server" "gateway" {
  name        = "${var.prefix}-gateway-vm"
  image       = "ubuntu-20.04"
  server_type = "cx11"
  location    = "nbg1"
  ssh_keys    = [hcloud_ssh_key.default.id]
}

# Put that VM into the subnet
resource "hcloud_server_network" "internal" {
  server_id = hcloud_server.gateway.id
  subnet_id = hcloud_network_subnet.main.id

  provisioner "remote-exec" {
    inline = ["echo 'SSH is now ready!'"]

    connection {
      type        = "ssh"
      user        = "root"
      private_key = file("~/.ssh/id_rsa")
      host        = hcloud_server.gateway.ipv4_address
    }
  }

  provisioner "local-exec" {
    command = "ansible-playbook -i '${hcloud_server.gateway.ipv4_address},' -u 'root' ../ansible/playbook.yml --extra-vars 'public_gateway_ip='${hcloud_server.gateway.ipv4_address}' local_cidr='${var.hetzner_vpc_cidr}' remote_gateway_ip='${azurerm_public_ip.main.ip_address}' remote_cidr='${var.azure_vpc_cidr}' psk='${var.shared_key}''"
  }
}


/*
----------------------------
    MANAGED GATEWAY(S)
----------------------------
*/

### AZURE ###

# Create local network gateway
#   This is the place where we will store the IP Adresse range of the other network
#   as well as the ip address of the other gateway.
resource "azurerm_local_network_gateway" "hetzner_onpremise" {
  name                = "hetzner-onpremise"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  gateway_address     = hcloud_server.gateway.ipv4_address
  address_space       = [var.hetzner_subnet_cidr]
}

# Create virtual network gateway
resource "azurerm_virtual_network_gateway" "main" {
  name                = "${var.prefix}-network-gateway"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  type     = "Vpn"
  vpn_type = "RouteBased"

  active_active = false
  enable_bgp    = false
  sku           = "Basic"

  ip_configuration {
    name                          = "${var.prefix}-vnetGatewayConfig"
    public_ip_address_id          = azurerm_public_ip.main.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.gateway.id
  }
}

/*
-------------------------------
   CONNECTING THE GATEWAYS
-------------------------------
*/


# Create the connection between the gateways. 
#   Internally, this is realiszed by connecting the virtual network gateway with 
#   the local network gateway
resource "azurerm_virtual_network_gateway_connection" "hetzner_onpremise" {
  name                = "hetzner-onpremise-connection"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  type                       = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.main.id
  local_network_gateway_id   = azurerm_local_network_gateway.hetzner_onpremise.id

  # !!!
  # TODO: find a way to store and distribute these properly accross the gateways
  # !!!
  shared_key = var.shared_key
}

# create a route in the Hetzner Network for Azure traffic
resource "hcloud_network_route" "to_gateway" {
  network_id = hcloud_network.main.id
  destination = var.azure_vpc_cidr
  gateway = hcloud_server_network.internal.ip
}


# TODO: outputs


/*
------------
    AWS
------------
Currently not usable. Cannot access AWS networking resources with current plan.


provider "aws" {
  region = "us-east-1"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  token = var.aws_session_token
}

# Create VPC
resource "aws_vpc" "main" {
  cidr_block           = "192.168.0.0/16"
  enable_dns_hostnames = true
}

# Create subnet in VPC
resource "aws_subnet" "main" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "192.168.0.0/24"
}

# Create internet gateway in VPC
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}

# Create customer gateway
resource "aws_customer_gateway" "main" {
  bgp_asn    = 65000
  ip_address = azurerm_public_ip.main.ip_address
  type       = "ipsec.1"

  tags = {
    Name = "main-customer-gateway"
  }
}

resource "aws_vpn_gateway" "main" {
  vpc_id = aws_vpc.main.id
}

resource "aws_vpn_connection" "main" {
  vpn_gateway_id      = aws_vpn_gateway.main.id
  customer_gateway_id = aws_customer_gateway.main.id
  type                = "ipsec.1"
  static_routes_only  = true
}

resource "aws_vpn_connection_route" "office" {
  destination_cidr_block = "10.0.0.0/24"
  vpn_connection_id      = aws_vpn_connection.main.id
}

*/
