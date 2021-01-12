terraform {
  required_version = "=0.14.4"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "2.41.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "2.15.0"
    }
  }
}

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
  byte_length = 8
}

resource "azurerm_resource_group" "site" {
  name     = "${var.prefix}-rg"
  location = var.location
}

resource "azurerm_virtual_network" "site" {
  name                = "${var.prefix}-vnet"
  location            = azurerm_resource_group.site.location
  resource_group_name = azurerm_resource_group.site.name
  address_space       = [var.cidr_block]
}

resource "azurerm_subnet" "private" {
  name                 = "${var.prefix}-private"
  virtual_network_name = azurerm_virtual_network.site.name
  resource_group_name  = azurerm_resource_group.site.name
  address_prefixes     = [cidrsubnet(var.cidr_block, 8, 1)]
}

resource "azurerm_subnet" "public" {
  name                 = "${var.prefix}-public"
  virtual_network_name = azurerm_virtual_network.site.name
  resource_group_name  = azurerm_resource_group.site.name
  address_prefixes     = [cidrsubnet(var.cidr_block, 8, 2)]
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "private_egress" {
  name                = "${var.prefix}-private-security-group"
  location            = azurerm_resource_group.site.location
  resource_group_name = azurerm_resource_group.site.name

  security_rule {
    name                       = "All-Outbound"
    priority                   = 150
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}
resource "azurerm_subnet_network_security_group_association" "private" {
  network_security_group_id = azurerm_network_security_group.private_egress.id
  subnet_id                 = azurerm_subnet.private.id
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "public_ingress" {
  name                = "${var.prefix}-public_ingress-security-group"
  location            = azurerm_resource_group.site.location
  resource_group_name = azurerm_resource_group.site.name

  security_rule {
    name                       = "SSH"
    priority                   = 1100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "ICMP"
    priority                   = 300
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "ICMP"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "public" {
  network_security_group_id = azurerm_network_security_group.public_ingress.id
  subnet_id                 = azurerm_subnet.public.id
}

resource "azurerm_network_interface" "public" {
  name                = "${var.prefix}-public-nic"
  location            = azurerm_resource_group.site.location
  resource_group_name = azurerm_resource_group.site.name

  ip_configuration {
    name                          = "${var.prefix}-${random_id.id.hex}-NicConfiguration"
    subnet_id                     = azurerm_subnet.public.id
    public_ip_address_id          = azurerm_public_ip.bastion.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface" "private" {
  count               = var.instances
  name                = "${var.prefix}-${count.index}-private-nic"
  location            = azurerm_resource_group.site.location
  resource_group_name = azurerm_resource_group.site.name

  ip_configuration {
    name                          = "${var.prefix}-${random_id.id.hex}-NicConfiguration"
    subnet_id                     = azurerm_subnet.private.id
    private_ip_address_allocation = "Dynamic"
  }
}



# Create public IPs
resource "azurerm_public_ip" "bastion" {
  name                = "${var.prefix}-ssh-public-ip"
  location            = azurerm_resource_group.site.location
  resource_group_name = azurerm_resource_group.site.name
  allocation_method   = "Dynamic"
}

# Create a virtual machine
resource "azurerm_linux_virtual_machine" "worker-nodes" {
  count                 = var.instances
  name                  = "${var.prefix}-worker${count.index}-${random_id.id.hex}-vm"
  resource_group_name   = azurerm_resource_group.site.name
  location              = azurerm_resource_group.site.location
  size                  = var.vm_size
  admin_username        = "adminuser"
  network_interface_ids = [azurerm_network_interface.private[count.index].id]

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
    sku       = "18.04-LTS"
    version   = "latest"
  }
}

resource "azurerm_linux_virtual_machine" "bastion" {
  name                  = "${var.prefix}-bastion-${random_id.id.hex}-vm"
  resource_group_name   = azurerm_resource_group.site.name
  location              = azurerm_resource_group.site.location
  size                  = var.vm_size
  admin_username        = "adminuser"
  network_interface_ids = [azurerm_network_interface.public.id]

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
    sku       = "18.04-LTS"
    version   = "latest"
  }
}

resource "azurerm_public_ip" "nat" {
  name                = "nat-gateway-publicIP"
  location            = azurerm_resource_group.site.location
  resource_group_name = azurerm_resource_group.site.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1"]
}

resource "azurerm_public_ip_prefix" "nat" {
  name                = "nat-gateway-publicIPPrefix"
  location            = azurerm_resource_group.site.location
  resource_group_name = azurerm_resource_group.site.name
  prefix_length       = 30
  zones               = ["1"]
}

resource "azurerm_nat_gateway" "private" {
  name                    = "nat-Gateway"
  location                = azurerm_resource_group.site.location
  resource_group_name     = azurerm_resource_group.site.name
  public_ip_prefix_ids    = [azurerm_public_ip_prefix.nat.id]
  sku_name                = "Standard"
  idle_timeout_in_minutes = 10
  zones                   = ["1"]
}

resource "azurerm_nat_gateway_public_ip_association" "default" {
  nat_gateway_id       = azurerm_nat_gateway.private.id
  public_ip_address_id = azurerm_public_ip.nat.id
}

resource "azurerm_subnet_nat_gateway_association" "default" {
  nat_gateway_id = azurerm_nat_gateway.private.id
  subnet_id = azurerm_subnet.private.id
}