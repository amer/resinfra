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

//resource "azurerm_dns_ns_record" "ns" {
//  name                = "cloudflare-amer.berlin"
//  zone_name           = azurerm_dns_zone.azure_zone.name
//  resource_group_name = azurerm_resource_group.main.name
//  ttl                 = 300
//
//  lifecycle {
//    prevent_destroy = false
//  }
//
//
//  records = [
//    "ns1-02.azure-dns.com.",
//    "ns2-02.azure-dns.net.",
//    "ns3-02.azure-dns.org.",
//    "ns4-02.azure-dns.info.",
//  ]
//
//  tags = {
//    Environment = "development"
//  }
//}

resource "azurerm_public_ip" "ri" {
  name                = "ri-public-ip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Dynamic"
  ip_version          = "IPv4"
}

resource "azurerm_dns_a_record" "ri" {
  name                = "ri"
  zone_name           = azurerm_dns_zone.azure_zone.name
  resource_group_name = azurerm_resource_group.main.name
  ttl                 = 300
  target_resource_id  = azurerm_public_ip.ri.id
  depends_on          = [cloudflare_record.public-zone-ns]
}

resource "azurerm_resource_group" "main" {
  name     = "${var.prefix}-rg"
  location = var.location
}

resource "random_id" "log_analytics_workspace_name_suffix" {
  byte_length = 8
}

//resource "azurerm_log_analytics_workspace" "main" {
//  # The WorkSpace name has to be unique across the whole of azure, not just the current subscription/tenant.
//  name                = "${var.log_analytics_workspace_name}-${random_id.log_analytics_workspace_name_suffix.dec}"
//  location            = var.log_analytics_workspace_location
//  resource_group_name = azurerm_resource_group.main.name
//  sku                 = var.log_analytics_workspace_sku
//}

//resource "azurerm_log_analytics_solution" "test" {
//  solution_name         = "ContainerInsights"
//  location              = azurerm_log_analytics_workspace.main.location
//  resource_group_name   = azurerm_resource_group.main.name
//  workspace_resource_id = azurerm_log_analytics_workspace.main.id
//  workspace_name        = azurerm_log_analytics_workspace.main.name
//
//  plan {
//    publisher = "Microsoft"
//    product   = "OMSGallery/ContainerInsights"
//  }
//}


//resource "azurerm_virtual_network" "main" {
//  name                = "test-network"
//  address_space       = [var.service_cidr]
//  location            = azurerm_resource_group.main.location
//  resource_group_name = azurerm_resource_group.main.name
//}
//
//resource "azurerm_subnet" "main" {
//  name                 = "acctsub"
//  resource_group_name  = azurerm_resource_group.main.name
//  virtual_network_name = azurerm_virtual_network.main.name
//  address_prefixes     = ["10.0.1.0/24"]
//}

resource "azurerm_public_ip" "nginx_ingress" {
  name                = "nginx-ingress-pip"
  location            = azurerm_kubernetes_cluster.main.location
  resource_group_name = azurerm_kubernetes_cluster.main.node_resource_group
  allocation_method   = "Static"
  domain_name_label   = "ri.az.amer.berlin"
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
    name                = "agentpool"
    node_count          = var.agent_count
    vm_size             = "Standard_D2_v2"
    type                = "VirtualMachineScaleSets"
    availability_zones  = ["1", "2", "3"]
    enable_auto_scaling = true
    min_count           = 2
    max_count           = 5
    os_disk_size_gb     = 30 # can't be smaller
    enable_node_public_ip = true

    #vnet_subnet_id = azurerm_subnet.main.id
    #enable_node_public_ip = true
//    tags = {
//      zone= "private"
//    }
  }




  service_principal {
    client_id     = var.client_id
    client_secret = var.client_secret
  }

  # api_server_authorized_ip_ranges = ["0.0.0.0/0"]

  //  addon_profile {
  ////    kube_dashboard {
  ////      enabled = true # TODO change to false in production
  ////    }
  //
  //    //    oms_agent {
  //    //      enabled                    = true
  //    //      log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  //    //    }
  //  }

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
    App         = "k8s"
    Environment = "development"
  }
}

//resource "azurerm_kubernetes_cluster_node_pool" "public" {
//  name                  = "public"
//  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
//  vm_size               = "Standard_DS2_v2"
//  node_count            = 1
//  enable_node_public_ip = true
//
//  tags = {
//    Environment = "Production"
//  }
//}

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

