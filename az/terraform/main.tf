terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.37.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
  # More information on the authentication methods supported by
  # the AzureRM Provider can be found here:
  # http://terraform.io/docs/providers/azurerm/index.html

  subscription_id = var.resinfra_subscription_id
  client_id       = var.resinfra_client_id
  client_secret   = var.resinfra_client_secret
  tenant_id       = var.resinfra_tenant_id
}

variable "prefix" {
  default = "resinfra"
}

resource "random_id" "mv_random_id" {
  byte_length = 8
}

# Create a resource group
resource "azurerm_resource_group" "main" {
  name     = "${var.prefix}-resources"
  location = "West US"
}

# Create a virtual network
resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

# Create a subnet
resource "azurerm_subnet" "internal" {
  name                 = "${var.prefix}-internal"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_interface" "main" {
  name                = "${var.prefix}-nic"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "${var.prefix}-NicConfiguration"
    subnet_id                     = azurerm_subnet.internal.id
    public_ip_address_id          = azurerm_public_ip.main.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "main" {
  name                = "${var.prefix}-security-group"
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
  network_interface_id      = azurerm_network_interface.main.id
  network_security_group_id = azurerm_network_security_group.main.id
}

# Create public IPs
resource "azurerm_public_ip" "main" {
  name                         = "${var.prefix}-public-ip"
  location                     = azurerm_resource_group.main.location
  resource_group_name          = azurerm_resource_group.main.name
  allocation_method            = "Dynamic"
  idle_timeout_in_minutes      = 30
  ip_version                   = "IPv4"

  tags = {
    environment = "development"
  }
}

# Create a virtual machine
resource "azurerm_linux_virtual_machine" "main" {
  name                = "${var.prefix}-vm-${random_id.mv_random_id.dec}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  size                = "Standard_DS1_v2" # Specs of Standard_DS1_v2 vm: (vCPU: 1, Memory: 3.5 GiB, Storage (SSD): 7 GiB)
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.main.id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
}

resource "azurerm_dns_zone" "azure" {
  name                = "azure.amer.berlin"
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_dns_a_record" "mv_public" {
  name                = azurerm_linux_virtual_machine.main.name
  zone_name           = azurerm_dns_zone.azure.name
  resource_group_name = azurerm_resource_group.main.name
  ttl                 = 100
  target_resource_id  = azurerm_public_ip.main.id
}

output "fqdn" {
  value = azurerm_dns_a_record.mv_public.fqdn
}

output "public_ip_address" {
  value = azurerm_public_ip.main.*.ip_address
}
