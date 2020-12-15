terraform {
  required_version = "=0.14.2"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "2.40.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "2.14.0"
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

provider "cloudflare" {
  email     = var.cloudflare_email
  api_token = var.cloudflare_api_token
}

resource "cloudflare_record" "public-zone-ns" {
  name       = "az.amer.berlin"
  zone_id    = "955db4eb519d7c5b898a87008882d72d"
  type       = "NS"
  ttl        = "120"
  count      = 4
  value      = element(azurerm_dns_zone.azure_zone.name_servers[*], count.index)
  depends_on = [azurerm_dns_zone.azure_zone]
}

resource "azurerm_network_security_group" "wireguard_access" {
  name                = "wireguard_sg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "wireguard_udp"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "UDP"
    source_port_range          = "*"
    destination_port_ranges    = [7946, 51820]
    source_address_prefix      = "*"
    destination_address_prefix = var.service_cidr
  }

  security_rule {
    name                       = "wireguard_tcp"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "tcp"
    source_port_range          = "*"
    destination_port_ranges    = [7946]
    source_address_prefix      = "*"
    destination_address_prefix = var.service_cidr
  }

  tags = {
    environment = "development"
  }
}

resource "azurerm_dns_zone" "azure_zone" {
  name                = "az.amer.berlin"
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_public_ip" "ingress_pip" {
  name                = "nginx-ingress-pip"
  location            = azurerm_kubernetes_cluster.main.location
  resource_group_name = azurerm_kubernetes_cluster.main.node_resource_group
  allocation_method   = "Static"
  ip_version          = "IPv4"
}

resource "azurerm_dns_a_record" "ingress_pip" {
  name                = "*"
  zone_name           = azurerm_dns_zone.azure_zone.name
  resource_group_name = azurerm_resource_group.main.name
  target_resource_id  = azurerm_public_ip.ingress_pip.id
  ttl                 = 300
}

resource "azurerm_resource_group" "main" {
  name     = "${var.prefix}-rg"
  location = var.location
}

resource "azurerm_kubernetes_cluster" "main" {
  name                = var.cluster_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = var.dns_prefix
  kubernetes_version  = "1.19.3"

  role_based_access_control {
    enabled = true
  }

  linux_profile {
    admin_username = "ubuntu"

    ssh_key {
      key_data = file(var.ssh_public_key)
    }
  }

  default_node_pool {
    name                  = "internal"
    node_count            = var.agent_count
    vm_size               = "Standard_D2_v2"
    type                  = "VirtualMachineScaleSets"
    availability_zones    = ["1", "2", "3"]
    enable_auto_scaling   = true
    min_count             = 2
    max_count             = 5
    os_disk_size_gb       = 30 # can't be smaller
    enable_node_public_ip = false

    #vnet_subnet_id = azurerm_subnet.main.id
    tags = {
      Environment = "Production"
      Zone        = "private"
    }
  }

  service_principal {
    client_id     = var.client_id
    client_secret = var.client_secret
  }

  network_profile {
    load_balancer_sku  = "Standard"
    network_plugin     = "azure" # azure == cni
    dns_service_ip     = var.dns_service_ip
    service_cidr       = var.service_cidr
    docker_bridge_cidr = "172.17.0.1/16"
    network_policy     = "calico"
    outbound_type      = "loadBalancer"
  }

  # TODO copy kube_config to ~/Download/somenamehere
  provisioner "local-exec" {
    command = <<EOF
      az aks get-credentials \
      --resource-group ${azurerm_kubernetes_cluster.main.resource_group_name} \
      --name ${azurerm_kubernetes_cluster.main.name} \
      --overwrite-existing

      # $ cp -f ~/.kube/config ~/Downloadskube_confit_${azurerm_kubernetes_cluster.main.name}
    EOF
  }

  # TODO use Helm chart instead of this ugly bash
  provisioner "local-exec" {
    command = "/bin/bash ${path.root}/scripts/install-kubernetes-dashboard.sh"
  }

  tags = {
    environment = "production"
    zone        = "private"
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "external" {
  name                  = "external"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  vm_size               = "Standard_DS2_v2"
  node_count            = 1
  availability_zones    = ["1", "2", "3"]
  min_count             = 1
  max_count             = 2
  enable_auto_scaling   = true
  enable_node_public_ip = true



  tags = {
    environment = "production"
    zone        = "public"
  }
}

module "install_helm" {
  source                 = "../helm"
  host                   = azurerm_kubernetes_cluster.main.kube_config.0.host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.main.kube_config.0.client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.main.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.main.kube_config.0.cluster_ca_certificate)
}

data "azurerm_kubernetes_cluster" "main" {
  name                = azurerm_kubernetes_cluster.main.name
  resource_group_name = azurerm_kubernetes_cluster.main.resource_group_name
}
