variable "prefix" {
  default = "resinfra"
}

/*
--------------
    AZURE
--------------
*/

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


# Create a resource group
resource "azurerm_resource_group" "main" {
  name     = "${var.prefix}-resources"
  location = "West US"
}

# Create a virtual network
resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-network"
  address_space       = ["10.1.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

# Create a subnet
#   This subnet will be used to place the machines
resource "azurerm_subnet" "vms" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.1.1.0/24"]
}

# Create a second subnet as GatewaySubnet
#   This subnet will be used for the gateways
resource "azurerm_subnet" "gateway" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.1.2.0/24"]
}

# Create public IPs
#   public ip for the virtual network gateway
resource "azurerm_public_ip" "main" {
  name                         = "${var.prefix}-public-ip"
  location                     = azurerm_resource_group.main.location
  resource_group_name          = azurerm_resource_group.main.name
  allocation_method            = "Dynamic"
}

# Create local network gateway
#   This is the place where we will store the IP Adresse range of the other network
#   as well as the ip address of the other gateway.
resource "azurerm_local_network_gateway" "hetzner_onpremise" {
  name                = "hetzner-onpremise"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  # !!!
  # TODO: find a way to store and distribute these properly accross the gateways
  # !!!
  gateway_address     = "116.203.220.224"
  address_space       = ["10.0.1.0/28"]
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
  shared_key = "aksjdcsajhdcinsadicnsdauicnsughuscbhjsdbvszuaedgffzusgczugasdzvgsahjvdahcbhzsgdczgszdv"
}
  

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
