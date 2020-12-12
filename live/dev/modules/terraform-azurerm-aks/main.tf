terraform {
  required_version = "=0.14.2"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "2.40.0"
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
    destination_port_ranges    = [7946,51820]
    source_address_prefix      = "*"
    destination_address_prefixes = var.subnet_cidr
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
    destination_address_prefixes = var.subnet_cidr
  }

  tags = {
    environment = "development"
  }
}

resource "azurerm_dns_zone" "azure_zone" {
  name                = "azure.amer.berlin"
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_dns_ns_record" "ns" {
  name                = "cloudflare-amer.berlin"
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

resource "azurerm_resource_group" "main" {
  name     = "${var.prefix}-rg"
  location = var.location
}

resource "random_id" "log_analytics_workspace_name_suffix" {
  byte_length = 8
}



resource "azurerm_log_analytics_workspace" "main" {
  # The WorkSpace name has to be unique across the whole of azure, not just the current subscription/tenant.
  name                = "${var.log_analytics_workspace_name}-${random_id.log_analytics_workspace_name_suffix.dec}"
  location            = var.log_analytics_workspace_location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = var.log_analytics_workspace_sku
}

resource "azurerm_log_analytics_solution" "test" {
  solution_name         = "ContainerInsights"
  location              = azurerm_log_analytics_workspace.main.location
  resource_group_name   = azurerm_resource_group.main.name
  workspace_resource_id = azurerm_log_analytics_workspace.main.id
  workspace_name        = azurerm_log_analytics_workspace.main.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/ContainerInsights"
  }
}

resource "azurerm_kubernetes_cluster" "main" {
  name                = var.cluster_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = var.dns_prefix

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
    name                = "agentpool"
    node_count          = var.agent_count
    vm_size             = "Standard_D2_v2"
    type                = "VirtualMachineScaleSets"
    availability_zones  = ["1", "2", "3"]
    enable_auto_scaling = true
    min_count           = 2
    max_count           = 5
    #vnet_subnet_id      = azurerm_kubernetes_cluster.main.network_profile.
  }

  service_principal {
    client_id     = var.client_id
    client_secret = var.client_secret
  }

  addon_profile {
    kube_dashboard {
      enabled = true # TODO change to false in production
    }

    oms_agent {
      enabled                    = true
      log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
    }
  }

  network_profile {
    load_balancer_sku   = "Standard"
    network_plugin      = "azure" # azure == cni
    dns_service_ip      = var.dns_service_ip
    service_cidr        = var.service_cidr
    docker_bridge_cidr  = "172.17.0.1/16"
    network_policy      = "calico"
  }

  tags = {
    App         = "k8s"
    Environment = "development"
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
