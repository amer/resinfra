# Configure the Microsoft Azure Provider
provider "azurerm" {
  version = "=2.37.0"
  features {}

  subscription_id = var.resinfra_subscription_id
  client_id       = var.resinfra_client_id
  client_secret   = var.resinfra_client_secret
  tenant_id       = var.resinfra_tenant_id
}

# Create a resource group
resource "azurerm_resource_group" "main" {
  name     = "${var.prefix}-resources-${random_id.id.hex}"
  location = "West Europe"
}

# Create a virtual network
resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-network-${random_id.id.hex}"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

# Create a subnet
resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_interface" "main" {
  name                = "${var.prefix}-nic-${random_id.id.hex}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "${var.prefix}-NicConfiguration-${random_id.id.hex}"
    subnet_id                     = azurerm_subnet.internal.id
    public_ip_address_id          = azurerm_public_ip.main.id
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
  network_interface_id      = azurerm_network_interface.main.id
  network_security_group_id = azurerm_network_security_group.main.id
}

# Create public IPs
resource "azurerm_public_ip" "main" {
  name                         = "${var.prefix}-public-ip-${random_id.id.hex}"
  location                     = azurerm_resource_group.main.location
  resource_group_name          = azurerm_resource_group.main.name
  allocation_method            = "Dynamic"
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
resource "azurerm_linux_virtual_machine" "main" {
  name                = "${var.prefix}-vm-${random_id.id.hex}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  size                = var.resinfra_vm_size
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.main.id,
  ]
  custom_data = data.template_cloudinit_config.config.rendered


  admin_ssh_key {
    username   = "adminuser"
    public_key = file(var.public_key_path)
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

resource "azurerm_dns_zone" "azure_zone" {
  name                = "${var.prefix}.azure.amer.berlin"
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_dns_ns_record" "ns" {
  name                = "${var.prefix}.cloudflare-amer.berlin"
  zone_name           = azurerm_dns_zone.azure_zone.name
  resource_group_name = azurerm_resource_group.main.name
  ttl                 = 50

  records = [
            "ns1-09.azure-dns.com",
            "ns2-09.azure-dns.net",
            "ns3-09.azure-dns.org",
            "ns4-09.azure-dns.info",
  ]

  tags = {
    Environment = "development"
  }
}


resource "azurerm_dns_a_record" "mv_public" {
  name                = azurerm_linux_virtual_machine.main.name
  zone_name           = azurerm_dns_zone.azure_zone.name
  resource_group_name = azurerm_resource_group.main.name
  ttl                 = 100
  target_resource_id  = azurerm_public_ip.main.id
}

output "fqdn" {
  value = azurerm_dns_a_record.mv_public.fqdn
}

