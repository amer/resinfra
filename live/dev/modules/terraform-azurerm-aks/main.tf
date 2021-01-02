terraform {
  required_version = "=0.14.3"
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
  #skip_provider_registration = true
}

provider "cloudflare" {
  email     = var.cloudflare_email
  api_token = var.cloudflare_api_token
}

resource "cloudflare_record" "public-zone-ns" {
  name       = var.domain_name
  zone_id    = var.cloudflare_zone_id
  type       = "NS"
  ttl        = 1
  count      = 4
  value      = trimsuffix(element(azurerm_dns_zone.azure_zone.name_servers[*], count.index), ".")
  depends_on = [azurerm_dns_zone.azure_zone]
}

resource "cloudflare_record" "cluster_cname" {
  name    = "c${var.domain_name}"
  zone_id = var.cloudflare_zone_id
  type    = "CNAME"
  ttl     = 1
  value   = azurerm_kubernetes_cluster.main.fqdn
}

resource "azurerm_dns_zone" "azure_zone" {
  name                = var.domain_name
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_resource_group" "main" {
  name     = "${var.prefix}-rg"
  location = var.location
}

//resource "azurerm_resource_provider_registration" "node-publicip-preview" {
//  name = "Microsoft.ContainerService"
//}

resource "azurerm_virtual_network" "network" {
  name                = "kube-vnet"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = [var.vnet_cidr]
}

resource "azurerm_subnet" "public" {
  name                 = "kube-public-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.network.name
  # "10.1.x.0/24" where x is an odd number for public subnets, starts at 3
  address_prefixes = [cidrsubnet(var.vnet_cidr, 8, 1 * 2 + 1)]
}

resource "azurerm_subnet" "private" {
  name                 = "kube-private-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.network.name
  # "10.1.x.0/24" where x is an even number for private subnets, starts at 4
  address_prefixes = [cidrsubnet(var.vnet_cidr, 8, 1 * 2 + 2)]
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
    vm_size               = var.vm_size
    type                  = "VirtualMachineScaleSets"
    availability_zones    = ["1", "2", "3"]
    enable_auto_scaling   = true
    min_count             = 2
    max_count             = 5
    os_disk_size_gb       = 30 # can't be smaller
    enable_node_public_ip = false
    vnet_subnet_id        = azurerm_subnet.private.id

    tags = {
      Environment = "production"
      Zone        = "private"
    }
  }

  service_principal {
    client_id     = var.client_id
    client_secret = var.client_secret
  }

  network_profile {
    load_balancer_sku = "Standard"
    network_plugin    = "azure" # azure == CNI, use 'azure' if you want to install calico or cilium later
    # If you want to use Cilium, do NOT specify the '–network-policy' flag when creating
    # the cluster, as this will cause the Azure CNI plugin to push down unwanted iptables rules.
    # network_policy     = "calico"
    outbound_type = "loadBalancer"
  }

  # TODO copy kube_config to ~/Download/somenamehere
  provisioner "local-exec" {
    command = <<EOF
      az aks get-credentials \
      --resource-group ${azurerm_kubernetes_cluster.main.resource_group_name} \
      --name ${azurerm_kubernetes_cluster.main.name} \
      --overwrite-existing
    EOF
    when    = create
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

resource "azurerm_kubernetes_cluster_node_pool" "public-pool" {
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  name                  = "publicpool"
  node_count            = 2
  vm_size               = "Standard_B2s"
  availability_zones    = ["1", "2", "3"]
  enable_auto_scaling   = true
  min_count             = 2
  max_count             = 2
  enable_node_public_ip = true
  vnet_subnet_id        = azurerm_subnet.public.id

  tags = {
    Environment = "production"
    Zone        = "public"
  }
}

module "install_helm" {
  source                 = "../terraform-helm"
  host                   = azurerm_kubernetes_cluster.main.kube_config.0.host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.main.kube_config.0.client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.main.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.main.kube_config.0.cluster_ca_certificate)
}

//module "ingress-nginx" {
//  source = "../app-ingress-nginx"
//  depends_on = [azurerm_kubernetes_cluster.main]
//}
//
//module "prometheus" {
//  source = "../app-prometheus"
//  depends_on = [azurerm_kubernetes_cluster.main]
//}

data "azurerm_kubernetes_cluster" "main" {
  name                = azurerm_kubernetes_cluster.main.name
  resource_group_name = azurerm_kubernetes_cluster.main.resource_group_name
}

//resource "azurerm_firewall_policy" "main" {
//  name                = "test-fwpolicy"
//  resource_group_name = azurerm_resource_group.main.name
//  location            = azurerm_resource_group.main.location
//}
//
//
//resource "azurerm_firewall_nat_rule_collection" "example" {
//  name                = "test-collection"
//  azure_firewall_name = azurerm_firewall.
//  resource_group_name = azurerm_resource_group.main.name
//  priority            = 150
//  action              = "Dnat"
//
//  rule {
//    name = "testrule"
//
//    source_addresses  = "0.0.0.0/0"
//    translated_address    = var.service_cidr
//    translated_port   = 55101
//
//    destination_addresses = "0.0.0.0/0"
//    destination_ports = 55101
//
//    protocols = [
//      "TCP",
//      "UDP",
//    ]
//  }
//}

//
//resource "azurerm_firewall_policy_rule_collection_group" "main" {
//  name               = "example-fwpolicy-rcg"
//  firewall_policy_id = azurerm_firewall_policy.main.id
//  priority           = 500
//
//  network_rule_collection {
//    name     = "network_rule_collection1"
//    priority = 400
//    action   = "Allow" # Allow or Deny
//    rule {
//      name                  = "network_rule_collection1_rule1"
//      protocols             = ["Any"] # ["Any","TCP","UDP","ICMP"]
//      source_addresses      = ["0.0.0.0/0"]
//      destination_addresses = ["0.0.0.0/0"]
//      destination_ports     = ["0-64000"] # ["80", "1000-2000"]
//    }
//  }
//}
